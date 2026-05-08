package handlers

import (
	"net/http"
	"strconv"

	"catalog-service/internal/models"

	"github.com/gin-gonic/gin"
	"gorm.io/gorm"
)

type ComboHandler struct {
	db *gorm.DB
}

func NewComboHandler(db *gorm.DB) *ComboHandler {
	return &ComboHandler{db: db}
}

type comboItemInput struct {
	MenuItemID uint `json:"menu_item_id" binding:"required"`
	Quantity   int  `json:"quantity" binding:"required,min=1"`
}

type createComboInput struct {
	Name            string           `json:"name" binding:"required"`
	Description     string           `json:"description"`
	DiscountPercent float64          `json:"discount_percent" binding:"min=0,max=100"`
	Items           []comboItemInput `json:"items" binding:"required,min=1"`
}

type comboResponse struct {
	models.Combo
	OriginalPrice   float64 `json:"original_price"`
	DiscountedPrice float64 `json:"discounted_price"`
}

func calcPrices(combo *models.Combo) (original, discounted float64) {
	for _, ci := range combo.Items {
		original += ci.MenuItem.Price * float64(ci.Quantity)
	}
	discounted = original * (1 - combo.DiscountPercent/100)
	return
}

func toComboResponse(combo *models.Combo) comboResponse {
	orig, disc := calcPrices(combo)
	return comboResponse{Combo: *combo, OriginalPrice: orig, DiscountedPrice: disc}
}

func (h *ComboHandler) loadCombo(id int) (*models.Combo, error) {
	var combo models.Combo
	err := h.db.Preload("Items.MenuItem").First(&combo, id).Error
	return &combo, err
}

func (h *ComboHandler) List(c *gin.Context) {
	var combos []models.Combo
	if err := h.db.Preload("Items.MenuItem").Where("is_available = ?", true).Find(&combos).Error; err != nil {
		c.JSON(http.StatusInternalServerError, gin.H{"error": "failed to fetch combos"})
		return
	}
	resp := make([]comboResponse, len(combos))
	for i := range combos {
		resp[i] = toComboResponse(&combos[i])
	}
	c.JSON(http.StatusOK, resp)
}

func (h *ComboHandler) Get(c *gin.Context) {
	id, err := strconv.Atoi(c.Param("id"))
	if err != nil {
		c.JSON(http.StatusBadRequest, gin.H{"error": "invalid id"})
		return
	}
	combo, err := h.loadCombo(id)
	if err != nil {
		c.JSON(http.StatusNotFound, gin.H{"error": "combo not found"})
		return
	}
	c.JSON(http.StatusOK, toComboResponse(combo))
}

func (h *ComboHandler) Create(c *gin.Context) {
	var input createComboInput
	if err := c.ShouldBindJSON(&input); err != nil {
		c.JSON(http.StatusBadRequest, gin.H{"error": err.Error()})
		return
	}
	combo := models.Combo{
		Name:            input.Name,
		Description:     input.Description,
		DiscountPercent: input.DiscountPercent,
		IsAvailable:     true,
	}
	if err := h.db.Create(&combo).Error; err != nil {
		c.JSON(http.StatusInternalServerError, gin.H{"error": "failed to create combo"})
		return
	}
	for _, it := range input.Items {
		h.db.Create(&models.ComboItem{ComboID: combo.ID, MenuItemID: it.MenuItemID, Quantity: it.Quantity})
	}
	full, _ := h.loadCombo(int(combo.ID))
	c.JSON(http.StatusCreated, toComboResponse(full))
}

func (h *ComboHandler) Update(c *gin.Context) {
	id, err := strconv.Atoi(c.Param("id"))
	if err != nil {
		c.JSON(http.StatusBadRequest, gin.H{"error": "invalid id"})
		return
	}
	var combo models.Combo
	if err := h.db.First(&combo, id).Error; err != nil {
		c.JSON(http.StatusNotFound, gin.H{"error": "combo not found"})
		return
	}
	var input struct {
		Name            *string          `json:"name"`
		Description     *string          `json:"description"`
		DiscountPercent *float64         `json:"discount_percent"`
		IsAvailable     *bool            `json:"is_available"`
		Items           []comboItemInput `json:"items"`
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
	if input.DiscountPercent != nil {
		updates["discount_percent"] = *input.DiscountPercent
	}
	if input.IsAvailable != nil {
		updates["is_available"] = *input.IsAvailable
	}
	if len(updates) > 0 {
		h.db.Model(&combo).Updates(updates)
	}
	if input.Items != nil {
		h.db.Where("combo_id = ?", combo.ID).Delete(&models.ComboItem{})
		for _, it := range input.Items {
			h.db.Create(&models.ComboItem{ComboID: combo.ID, MenuItemID: it.MenuItemID, Quantity: it.Quantity})
		}
	}
	full, _ := h.loadCombo(id)
	c.JSON(http.StatusOK, toComboResponse(full))
}

func (h *ComboHandler) Delete(c *gin.Context) {
	id, err := strconv.Atoi(c.Param("id"))
	if err != nil {
		c.JSON(http.StatusBadRequest, gin.H{"error": "invalid id"})
		return
	}
	h.db.Where("combo_id = ?", id).Delete(&models.ComboItem{})
	if err := h.db.Delete(&models.Combo{}, id).Error; err != nil {
		c.JSON(http.StatusInternalServerError, gin.H{"error": "failed to delete combo"})
		return
	}
	c.Status(http.StatusNoContent)
}
