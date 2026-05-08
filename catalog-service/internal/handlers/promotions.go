package handlers

import (
	"net/http"
	"strconv"
	"time"

	"catalog-service/internal/models"

	"github.com/gin-gonic/gin"
	"gorm.io/gorm"
)

type PromotionHandler struct {
	db *gorm.DB
}

func NewPromotionHandler(db *gorm.DB) *PromotionHandler {
	return &PromotionHandler{db: db}
}

type createPromotionInput struct {
	Name            string    `json:"name" binding:"required"`
	Description     string    `json:"description"`
	DiscountPercent float64   `json:"discount_percent" binding:"min=0,max=100"`
	StartsAt        time.Time `json:"starts_at" binding:"required"`
	EndsAt          time.Time `json:"ends_at" binding:"required"`
}

func (h *PromotionHandler) List(c *gin.Context) {
	var promos []models.Promotion
	if err := h.db.Where("is_active = ? AND ends_at > ?", true, time.Now()).Find(&promos).Error; err != nil {
		c.JSON(http.StatusInternalServerError, gin.H{"error": "failed to fetch promotions"})
		return
	}
	c.JSON(http.StatusOK, promos)
}

func (h *PromotionHandler) Get(c *gin.Context) {
	id, err := strconv.Atoi(c.Param("id"))
	if err != nil {
		c.JSON(http.StatusBadRequest, gin.H{"error": "invalid id"})
		return
	}
	var promo models.Promotion
	if err := h.db.First(&promo, id).Error; err != nil {
		c.JSON(http.StatusNotFound, gin.H{"error": "promotion not found"})
		return
	}
	c.JSON(http.StatusOK, promo)
}

func (h *PromotionHandler) Create(c *gin.Context) {
	var input createPromotionInput
	if err := c.ShouldBindJSON(&input); err != nil {
		c.JSON(http.StatusBadRequest, gin.H{"error": err.Error()})
		return
	}
	promo := models.Promotion{
		Name:            input.Name,
		Description:     input.Description,
		DiscountPercent: input.DiscountPercent,
		StartsAt:        input.StartsAt,
		EndsAt:          input.EndsAt,
		IsActive:        true,
	}
	if err := h.db.Create(&promo).Error; err != nil {
		c.JSON(http.StatusInternalServerError, gin.H{"error": "failed to create promotion"})
		return
	}
	c.JSON(http.StatusCreated, promo)
}

func (h *PromotionHandler) Update(c *gin.Context) {
	id, err := strconv.Atoi(c.Param("id"))
	if err != nil {
		c.JSON(http.StatusBadRequest, gin.H{"error": "invalid id"})
		return
	}
	var promo models.Promotion
	if err := h.db.First(&promo, id).Error; err != nil {
		c.JSON(http.StatusNotFound, gin.H{"error": "promotion not found"})
		return
	}
	var input struct {
		Name            *string    `json:"name"`
		Description     *string    `json:"description"`
		DiscountPercent *float64   `json:"discount_percent"`
		StartsAt        *time.Time `json:"starts_at"`
		EndsAt          *time.Time `json:"ends_at"`
		IsActive        *bool      `json:"is_active"`
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
	if input.StartsAt != nil {
		updates["starts_at"] = *input.StartsAt
	}
	if input.EndsAt != nil {
		updates["ends_at"] = *input.EndsAt
	}
	if input.IsActive != nil {
		updates["is_active"] = *input.IsActive
	}
	if err := h.db.Model(&promo).Updates(updates).Error; err != nil {
		c.JSON(http.StatusInternalServerError, gin.H{"error": "failed to update promotion"})
		return
	}
	c.JSON(http.StatusOK, promo)
}

func (h *PromotionHandler) Delete(c *gin.Context) {
	id, err := strconv.Atoi(c.Param("id"))
	if err != nil {
		c.JSON(http.StatusBadRequest, gin.H{"error": "invalid id"})
		return
	}
	if err := h.db.Delete(&models.Promotion{}, id).Error; err != nil {
		c.JSON(http.StatusInternalServerError, gin.H{"error": "failed to delete promotion"})
		return
	}
	c.Status(http.StatusNoContent)
}
