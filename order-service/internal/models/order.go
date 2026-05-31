package models

import (
	"time"

	"gorm.io/gorm"
)

type OrderStatus string

const (
	StatusPending   OrderStatus = "pending"
	StatusAccepted  OrderStatus = "accepted"
	StatusPickedUp  OrderStatus = "picked_up"
	StatusDelivered OrderStatus = "delivered"
	StatusCancelled OrderStatus = "cancelled"
)

type Order struct {
	ID         uint           `gorm:"primarykey" json:"id"`
	CustomerID uint           `gorm:"not null;index" json:"customer_id"`
	ShopID     uint           `gorm:"not null;index" json:"shop_id"`
	CourierID  *uint          `json:"courier_id"`
	Status     OrderStatus    `gorm:"type:varchar(20);not null;default:'pending'" json:"status"`
	TotalPrice float64        `gorm:"not null" json:"total_price"`
	Address    string         `gorm:"not null" json:"address"`
	Items      []OrderItem    `gorm:"foreignKey:OrderID" json:"items"`
	CreatedAt  time.Time      `json:"created_at"`
	UpdatedAt  time.Time      `json:"updated_at"`
	DeletedAt  gorm.DeletedAt `gorm:"index" json:"-"`
}

type OrderItem struct {
	ID         uint    `gorm:"primarykey" json:"id"`
	OrderID    uint    `gorm:"not null;index" json:"order_id"`
	MenuItemID uint    `gorm:"not null" json:"menu_item_id"`
	Name       string  `gorm:"not null" json:"name"`
	UnitPrice  float64 `gorm:"not null" json:"unit_price"`
	Quantity   int     `gorm:"not null" json:"quantity"`
}

type OrderDecline struct {
	OrderID   uint `gorm:"not null;index;uniqueIndex:idx_order_courier_decline" json:"order_id"`
	CourierID uint `gorm:"not null;index;uniqueIndex:idx_order_courier_decline" json:"courier_id"`
}
