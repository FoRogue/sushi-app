package models

import (
	"time"

	"gorm.io/gorm"
)

const (
	RoleCustomer = "customer"
	RoleCourier  = "courier"
	RoleShop     = "shop"
)

type User struct {
	ID           uint           `gorm:"primaryKey"`
	Role         string         `gorm:"type:varchar(20);not null"`
	PasswordHash string         `gorm:"not null"`
	Name         *string        `gorm:"size:255"`
	Phone        *string        `gorm:"uniqueIndex;size:20"`
	VehicleCode  *string        `gorm:"uniqueIndex;size:20"`
	FullName     *string        `gorm:"size:255"`
	Login        *string        `gorm:"uniqueIndex;size:50"`
	Address      *string        `gorm:"size:500"`
	CreatedAt    time.Time
	UpdatedAt    time.Time
	DeletedAt    gorm.DeletedAt `gorm:"index"`
}

type RefreshToken struct {
	ID        uint           `gorm:"primaryKey"`
	UserID    uint           `gorm:"not null;index"`
	Token     string         `gorm:"uniqueIndex;not null"`
	ExpiresAt time.Time      `gorm:"not null"`
	CreatedAt time.Time
	DeletedAt gorm.DeletedAt `gorm:"index"`
}
