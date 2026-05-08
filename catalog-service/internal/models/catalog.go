package models

import (
	"time"

	"gorm.io/gorm"
)

type ItemType string

const (
	TypeSushi ItemType = "sushi"
	TypeRoll  ItemType = "roll"
	TypeDrink ItemType = "drink"
)

type MenuItem struct {
	ID          uint           `gorm:"primarykey" json:"id"`
	Name        string         `gorm:"not null" json:"name"`
	Description string         `json:"description"`
	Price       float64        `gorm:"not null" json:"price"`
	Type        ItemType       `gorm:"type:varchar(20);not null" json:"type"`
	IsAvailable bool           `gorm:"default:true" json:"is_available"`
	CreatedAt   time.Time      `json:"created_at"`
	UpdatedAt   time.Time      `json:"updated_at"`
	DeletedAt   gorm.DeletedAt `gorm:"index" json:"-"`
}

type ComboItem struct {
	ID         uint     `gorm:"primarykey" json:"id"`
	ComboID    uint     `gorm:"not null;index" json:"combo_id"`
	MenuItemID uint     `gorm:"not null" json:"menu_item_id"`
	Quantity   int      `gorm:"default:1;not null" json:"quantity"`
	MenuItem   MenuItem `gorm:"foreignKey:MenuItemID" json:"item"`
}

type Combo struct {
	ID              uint           `gorm:"primarykey" json:"id"`
	Name            string         `gorm:"not null" json:"name"`
	Description     string         `json:"description"`
	DiscountPercent float64        `gorm:"not null" json:"discount_percent"`
	IsAvailable     bool           `gorm:"default:true" json:"is_available"`
	Items           []ComboItem    `gorm:"foreignKey:ComboID" json:"items"`
	CreatedAt       time.Time      `json:"created_at"`
	UpdatedAt       time.Time      `json:"updated_at"`
	DeletedAt       gorm.DeletedAt `gorm:"index" json:"-"`
}

type Promotion struct {
	ID              uint           `gorm:"primarykey" json:"id"`
	Name            string         `gorm:"not null" json:"name"`
	Description     string         `json:"description"`
	DiscountPercent float64        `gorm:"not null" json:"discount_percent"`
	StartsAt        time.Time      `json:"starts_at"`
	EndsAt          time.Time      `json:"ends_at"`
	IsActive        bool           `gorm:"default:true" json:"is_active"`
	CreatedAt       time.Time      `json:"created_at"`
	UpdatedAt       time.Time      `json:"updated_at"`
	DeletedAt       gorm.DeletedAt `gorm:"index" json:"-"`
}
