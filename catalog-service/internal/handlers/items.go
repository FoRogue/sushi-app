package handlers

import (
	"fmt"
	"net/http"
	"strconv"

	"catalog-service/internal/models"

	"github.com/gin-gonic/gin"
	"gorm.io/gorm"
)

type ItemHandler struct {
	db *gorm.DB
}

func NewItemHandler(db *gorm.DB) *ItemHandler {
	return &ItemHandler{db: db}
}

func shopIDFromHeader(c *gin.Context) (uint, error) {
	raw := c.GetHeader("X-User-ID")
	id, err := strconv.ParseUint(raw, 10, 64)
	if err != nil {
		return 0, fmt.Errorf("invalid X-User-ID")
	}
	return uint(id), nil
}

type createItemInput struct {
	Name        string          `json:"name" binding:"required"`
	Description string          `json:"description"`
	Price       float64         `json:"price" binding:"required,gt=0"`
	Type        models.ItemType `json:"type" binding:"required,oneof=sushi roll drink"`
}

func (h *ItemHandler) List(c *gin.Context) {
	var items []models.MenuItem
	q := h.db.Where("is_available = ?", true)
	if sid := c.Query("shop_id"); sid != "" {
		q = q.Where("shop_id = ?", sid)
	}
	if t := c.Query("type"); t != "" {
		q = q.Where("type = ?", t)
	}
	if err := q.Find(&items).Error; err != nil {
		c.JSON(http.StatusInternalServerError, gin.H{"error": "failed to fetch items"})
		return
	}
	c.JSON(http.StatusOK, items)
}

func (h *ItemHandler) Get(c *gin.Context) {
	id, err := strconv.Atoi(c.Param("id"))
	if err != nil {
		c.JSON(http.StatusBadRequest, gin.H{"error": "invalid id"})
		return
	}
	var item models.MenuItem
	if err := h.db.First(&item, id).Error; err != nil {
		c.JSON(http.StatusNotFound, gin.H{"error": "item not found"})
		return
	}
	c.JSON(http.StatusOK, item)
}

func (h *ItemHandler) Create(c *gin.Context) {
	sid, err := shopIDFromHeader(c)
	if err != nil {
		c.JSON(http.StatusBadRequest, gin.H{"error": err.Error()})
		return
	}

	var input createItemInput
	if err := c.ShouldBindJSON(&input); err != nil {
		c.JSON(http.StatusBadRequest, gin.H{"error": err.Error()})
		return
	}
	item := models.MenuItem{
		ShopID:      sid,
		Name:        input.Name,
		Description: input.Description,
		Price:       input.Price,
		Type:        input.Type,
		IsAvailable: true,
	}
	if err := h.db.Create(&item).Error; err != nil {
		c.JSON(http.StatusInternalServerError, gin.H{"error": "failed to create item"})
		return
	}
	c.JSON(http.StatusCreated, item)
}

func (h *ItemHandler) Update(c *gin.Context) {
	sid, err := shopIDFromHeader(c)
	if err != nil {
		c.JSON(http.StatusBadRequest, gin.H{"error": err.Error()})
		return
	}

	id, err := strconv.Atoi(c.Param("id"))
	if err != nil {
		c.JSON(http.StatusBadRequest, gin.H{"error": "invalid id"})
		return
	}
	var item models.MenuItem
	if err := h.db.First(&item, id).Error; err != nil {
		c.JSON(http.StatusNotFound, gin.H{"error": "item not found"})
		return
	}
	if item.ShopID != sid {
		c.JSON(http.StatusForbidden, gin.H{"error": "forbidden"})
		return
	}

	var input struct {
		Name        *string          `json:"name"`
		Description *string          `json:"description"`
		Price       *float64         `json:"price"`
		Type        *models.ItemType `json:"type"`
		IsAvailable *bool            `json:"is_available"`
	}
	if err := c.ShouldBindJSON(&input); err != nil {
		c.JSON(http.StatusBadRequest, gin.H{"error": err.Error()})
		return
	}
	updates := map[string]interface{}{}
	if input.Name != nil {
		updates["name"] = *input.Name
	}
	if input.Description != nil {
		updates["description"] = *input.Description
	}
	if input.Price != nil {
		updates["price"] = *input.Price
	}
	if input.Type != nil {
		updates["type"] = *input.Type
	}
	if input.IsAvailable != nil {
		updates["is_available"] = *input.IsAvailable
	}
	if err := h.db.Model(&item).Updates(updates).Error; err != nil {
		c.JSON(http.StatusInternalServerError, gin.H{"error": "failed to update item"})
		return
	}
	c.JSON(http.StatusOK, item)
}

func (h *ItemHandler) Delete(c *gin.Context) {
	sid, err := shopIDFromHeader(c)
	if err != nil {
		c.JSON(http.StatusBadRequest, gin.H{"error": err.Error()})
		return
	}

	id, err := strconv.Atoi(c.Param("id"))
	if err != nil {
		c.JSON(http.StatusBadRequest, gin.H{"error": "invalid id"})
		return
	}

	var item models.MenuItem
	if err := h.db.First(&item, id).Error; err != nil {
		c.JSON(http.StatusNotFound, gin.H{"error": "item not found"})
		return
	}
	if item.ShopID != sid {
		c.JSON(http.StatusForbidden, gin.H{"error": "forbidden"})
		return
	}

	if err := h.db.Delete(&item).Error; err != nil {
		c.JSON(http.StatusInternalServerError, gin.H{"error": "failed to delete item"})
		return
	}
	c.Status(http.StatusNoContent)
}
