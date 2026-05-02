package models

import "time"

type User struct {
	ID           uint   `gorm:"primaryKey"`
	Name         string `gorm:"size:255;not null"`
	Phone        string `gorm:"uniqueIndex;size:20;not null"`
	PasswordHash string `gorm:"not null"`
	Role         string `gorm:"type:varchar(20);default:'client'"`
	CreatedAt    time.Time
	UpdatedAt    time.Time
}
