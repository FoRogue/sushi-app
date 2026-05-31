package handlers

import (
	"fmt"
	"net/http"
	"strconv"

	"order-service/internal/clients"
	"order-service/internal/models"

	"github.com/gin-gonic/gin"
	"gorm.io/gorm"
)

type OrderHandler struct {
	db      *gorm.DB
	catalog *clients.CatalogClient
}

func NewOrderHandler(db *gorm.DB, catalog *clients.CatalogClient) *OrderHandler {
	return &OrderHandler{db: db, catalog: catalog}
}

func userID(c *gin.Context) (uint, error) {
	raw := c.GetHeader("X-User-ID")
	id, err := strconv.ParseUint(raw, 10, 64)
	if err != nil {
		return 0, fmt.Errorf("invalid X-User-ID")
	}
	return uint(id), nil
}

// --- Create ---

type orderItemInput struct {
	MenuItemID uint `json:"menu_item_id" binding:"required"`
	Quantity   int  `json:"quantity" binding:"required,min=1"`
}

type createOrderInput struct {
	ShopID  uint             `json:"shop_id" binding:"required"`
	Address string           `json:"address" binding:"required"`
	Items   []orderItemInput `json:"items" binding:"required,min=1"`
}

func (h *OrderHandler) Create(c *gin.Context) {
	custID, err := userID(c)
	if err != nil {
		c.JSON(http.StatusBadRequest, gin.H{"error": err.Error()})
		return
	}

	var input createOrderInput
	if err := c.ShouldBindJSON(&input); err != nil {
		c.JSON(http.StatusBadRequest, gin.H{"error": err.Error()})
		return
	}

	var orderItems []models.OrderItem
	var total float64

	for _, it := range input.Items {
		catalogItem, err := h.catalog.GetItem(c.Request.Context(), it.MenuItemID)
		if err != nil {
			c.JSON(http.StatusBadRequest, gin.H{"error": err.Error()})
			return
		}
		if !catalogItem.IsAvailable {
			c.JSON(http.StatusBadRequest, gin.H{"error": fmt.Sprintf("item %d is not available", it.MenuItemID)})
			return
		}
		orderItems = append(orderItems, models.OrderItem{
			MenuItemID: it.MenuItemID,
			Name:       catalogItem.Name,
			UnitPrice:  catalogItem.Price,
			Quantity:   it.Quantity,
		})
		total += catalogItem.Price * float64(it.Quantity)
	}

	order := models.Order{
		CustomerID: custID,
		ShopID:     input.ShopID,
		Status:     models.StatusPending,
		TotalPrice: total,
		Address:    input.Address,
		Items:      orderItems,
	}

	if err := h.db.Create(&order).Error; err != nil {
		c.JSON(http.StatusInternalServerError, gin.H{"error": "failed to create order"})
		return
	}
	c.JSON(http.StatusCreated, order)
}

// --- List ---

func (h *OrderHandler) List(c *gin.Context) {
	uid, err := userID(c)
	if err != nil {
		c.JSON(http.StatusBadRequest, gin.H{"error": err.Error()})
		return
	}
	role := c.GetHeader("X-User-Role")

	var orders []models.Order
	q := h.db.Preload("Items")

	switch role {
	case "customer":
		q = q.Where("customer_id = ?", uid)
	case "courier":
		q = q.Where(
			"(status = ? AND id NOT IN (SELECT order_id FROM order_declines WHERE courier_id = ?)) OR courier_id = ?",
			models.StatusAccepted, uid, uid,
		)
	case "shop":
		q = q.Where("shop_id = ?", uid)
		if s := c.Query("status"); s != "" {
			q = q.Where("status = ?", s)
		}
	}

	if err := q.Order("created_at desc").Find(&orders).Error; err != nil {
		c.JSON(http.StatusInternalServerError, gin.H{"error": "failed to fetch orders"})
		return
	}
	c.JSON(http.StatusOK, orders)
}

// --- Get ---

func (h *OrderHandler) Get(c *gin.Context) {
	uid, err := userID(c)
	if err != nil {
		c.JSON(http.StatusBadRequest, gin.H{"error": err.Error()})
		return
	}
	role := c.GetHeader("X-User-Role")

	id, err := strconv.Atoi(c.Param("id"))
	if err != nil {
		c.JSON(http.StatusBadRequest, gin.H{"error": "invalid id"})
		return
	}

	var order models.Order
	if err := h.db.Preload("Items").First(&order, id).Error; err != nil {
		c.JSON(http.StatusNotFound, gin.H{"error": "order not found"})
		return
	}

	switch role {
	case "customer":
		if order.CustomerID != uid {
			c.JSON(http.StatusForbidden, gin.H{"error": "forbidden"})
			return
		}
	case "shop":
		if order.ShopID != uid {
			c.JSON(http.StatusForbidden, gin.H{"error": "forbidden"})
			return
		}
	}

	c.JSON(http.StatusOK, order)
}

// --- UpdateStatus ---

var allowedTransitions = map[models.OrderStatus]map[string]models.OrderStatus{
	models.StatusPending: {
		"shop":     models.StatusAccepted,
		"customer": models.StatusCancelled,
	},
	models.StatusAccepted: {
		"shop":    models.StatusCancelled,
		"courier": models.StatusPickedUp,
	},
	models.StatusPickedUp: {
		"courier": models.StatusDelivered,
	},
}

type updateStatusInput struct {
	Status models.OrderStatus `json:"status" binding:"required"`
}

func (h *OrderHandler) UpdateStatus(c *gin.Context) {
	uid, err := userID(c)
	if err != nil {
		c.JSON(http.StatusBadRequest, gin.H{"error": err.Error()})
		return
	}
	role := c.GetHeader("X-User-Role")

	id, err := strconv.Atoi(c.Param("id"))
	if err != nil {
		c.JSON(http.StatusBadRequest, gin.H{"error": "invalid id"})
		return
	}

	var input updateStatusInput
	if err := c.ShouldBindJSON(&input); err != nil {
		c.JSON(http.StatusBadRequest, gin.H{"error": err.Error()})
		return
	}

	var order models.Order
	if err := h.db.Preload("Items").First(&order, id).Error; err != nil {
		c.JSON(http.StatusNotFound, gin.H{"error": "order not found"})
		return
	}

	if role == "customer" && order.CustomerID != uid {
		c.JSON(http.StatusForbidden, gin.H{"error": "forbidden"})
		return
	}
	if role == "shop" && order.ShopID != uid {
		c.JSON(http.StatusForbidden, gin.H{"error": "forbidden"})
		return
	}

	allowed, ok := allowedTransitions[order.Status]
	if !ok {
		c.JSON(http.StatusBadRequest, gin.H{"error": "order is in a terminal state"})
		return
	}
	nextStatus, ok := allowed[role]
	if !ok || nextStatus != input.Status {
		c.JSON(http.StatusBadRequest, gin.H{"error": fmt.Sprintf("role %s cannot set status to %s", role, input.Status)})
		return
	}

	updates := map[string]interface{}{"status": nextStatus}
	if nextStatus == models.StatusPickedUp {
		updates["courier_id"] = uid
		// Защита от гонки: берём только если никто не взял
		result := h.db.Model(&order).Where("courier_id IS NULL").Updates(updates)
		if result.Error != nil {
			c.JSON(http.StatusInternalServerError, gin.H{"error": "failed to update status"})
			return
		}
		if result.RowsAffected == 0 {
			c.JSON(http.StatusConflict, gin.H{"error": "заказ уже взят другим курьером"})
			return
		}
	} else {
		if err := h.db.Model(&order).Updates(updates).Error; err != nil {
			c.JSON(http.StatusInternalServerError, gin.H{"error": "failed to update status"})
			return
		}
	}

	order.Status = nextStatus
	if nextStatus == models.StatusPickedUp {
		order.CourierID = &uid
	}
	c.JSON(http.StatusOK, order)
}

// --- Decline ---

func (h *OrderHandler) Decline(c *gin.Context) {
	uid, err := userID(c)
	if err != nil {
		c.JSON(http.StatusBadRequest, gin.H{"error": err.Error()})
		return
	}

	id, err := strconv.Atoi(c.Param("id"))
	if err != nil {
		c.JSON(http.StatusBadRequest, gin.H{"error": "invalid id"})
		return
	}

	var order models.Order
	if err := h.db.First(&order, id).Error; err != nil {
		c.JSON(http.StatusNotFound, gin.H{"error": "order not found"})
		return
	}

	if order.Status != models.StatusAccepted {
		c.JSON(http.StatusBadRequest, gin.H{"error": "можно отказаться только от принятого заказа"})
		return
	}

	decline := models.OrderDecline{OrderID: uint(id), CourierID: uid}
	if err := h.db.Create(&decline).Error; err != nil {
		c.JSON(http.StatusConflict, gin.H{"error": "заказ уже отклонён"})
		return
	}

	c.Status(http.StatusNoContent)
}
