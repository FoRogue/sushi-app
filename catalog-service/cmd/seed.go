package main

import (
	"log"
	"time"

	"catalog-service/internal/models"

	"gorm.io/gorm"
)

func seed(db *gorm.DB) {
	var count int64
	db.Model(&models.MenuItem{}).Count(&count)
	if count > 0 {
		return
	}

	log.Println("seeding catalog data...")

	items := []models.MenuItem{
		// Суши (нигири)
		{Name: "Лосось нигири", Description: "Классический нигири с нежным лососем", Price: 120, Type: models.TypeSushi, IsAvailable: true},
		{Name: "Тунец нигири", Description: "Нигири с благородным тунцом", Price: 135, Type: models.TypeSushi, IsAvailable: true},
		{Name: "Угорь нигири", Description: "Нигири с копчёным угрём под соусом терияки", Price: 155, Type: models.TypeSushi, IsAvailable: true},
		{Name: "Хотатэ нигири", Description: "Нигири с нежным морским гребешком", Price: 145, Type: models.TypeSushi, IsAvailable: true},
		// Роллы
		{Name: "Калифорния", Description: "Краб, авокадо, огурец, икра тобико", Price: 340, Type: models.TypeRoll, IsAvailable: true},
		{Name: "Филадельфия", Description: "Лосось, сливочный сыр Philadelphia, огурец", Price: 420, Type: models.TypeRoll, IsAvailable: true},
		{Name: "Дракон", Description: "Угорь, авокадо, краб, кунжут", Price: 490, Type: models.TypeRoll, IsAvailable: true},
		{Name: "Спайси лосось", Description: "Лосось, острый соус, зелёный лук, кунжут", Price: 360, Type: models.TypeRoll, IsAvailable: true},
		{Name: "Радуга", Description: "Краб, авокадо, огурец, ассорти рыбы сверху", Price: 470, Type: models.TypeRoll, IsAvailable: true},
		{Name: "Запечённый с лососем", Description: "Лосось, сливочный сыр, запечённый под соусом", Price: 380, Type: models.TypeRoll, IsAvailable: true},
		// Напитки
		{Name: "Зелёный чай", Description: "Классический японский зелёный чай", Price: 80, Type: models.TypeDrink, IsAvailable: true},
		{Name: "Мисо суп", Description: "Традиционный суп с тофу и водорослями вакамэ", Price: 120, Type: models.TypeDrink, IsAvailable: true},
		{Name: "Имбирный лимонад", Description: "Освежающий лимонад с имбирём и лимоном", Price: 150, Type: models.TypeDrink, IsAvailable: true},
		{Name: "Кокосовое молоко", Description: "Натуральное охлаждённое кокосовое молоко", Price: 130, Type: models.TypeDrink, IsAvailable: true},
	}
	db.Create(&items)

	var salmon, california, philly, dragon, tea, miso models.MenuItem
	db.Where("name = ?", "Лосось нигири").First(&salmon)
	db.Where("name = ?", "Калифорния").First(&california)
	db.Where("name = ?", "Филадельфия").First(&philly)
	db.Where("name = ?", "Дракон").First(&dragon)
	db.Where("name = ?", "Зелёный чай").First(&tea)
	db.Where("name = ?", "Мисо суп").First(&miso)

	combos := []models.Combo{
		{Name: "Сет Токио", Description: "Ролл Калифорния + 3 нигири с лососем + зелёный чай", DiscountPercent: 15, IsAvailable: true},
		{Name: "Сет Сакура", Description: "Филадельфия + Дракон — идеальный дуэт", DiscountPercent: 10, IsAvailable: true},
		{Name: "Сет Семейный", Description: "2× Калифорния + Филадельфия + 2× мисо суп — на двоих", DiscountPercent: 20, IsAvailable: true},
	}
	for i := range combos {
		db.Create(&combos[i])
	}

	comboItems := []models.ComboItem{
		// Сет Токио
		{ComboID: combos[0].ID, MenuItemID: california.ID, Quantity: 1},
		{ComboID: combos[0].ID, MenuItemID: salmon.ID, Quantity: 3},
		{ComboID: combos[0].ID, MenuItemID: tea.ID, Quantity: 1},
		// Сет Сакура
		{ComboID: combos[1].ID, MenuItemID: philly.ID, Quantity: 1},
		{ComboID: combos[1].ID, MenuItemID: dragon.ID, Quantity: 1},
		// Сет Семейный
		{ComboID: combos[2].ID, MenuItemID: california.ID, Quantity: 2},
		{ComboID: combos[2].ID, MenuItemID: philly.ID, Quantity: 1},
		{ComboID: combos[2].ID, MenuItemID: miso.ID, Quantity: 2},
	}
	for i := range comboItems {
		db.Create(&comboItems[i])
	}

	now := time.Now()
	promos := []models.Promotion{
		{
			Name:            "Счастливые часы",
			Description:     "Скидка 20% на все роллы с 12:00 до 14:00 каждый день",
			DiscountPercent: 20,
			StartsAt:        time.Date(now.Year(), now.Month(), now.Day(), 12, 0, 0, 0, time.Local),
			EndsAt:          time.Date(now.Year(), 12, 31, 14, 0, 0, 0, time.Local),
			IsActive:        true,
		},
		{
			Name:            "Вечерний бонус",
			Description:     "При заказе от 1000 ₽ после 19:00 — напиток в подарок",
			DiscountPercent: 0,
			StartsAt:        time.Date(now.Year(), now.Month(), now.Day(), 19, 0, 0, 0, time.Local),
			EndsAt:          time.Date(now.Year(), 12, 31, 23, 0, 0, 0, time.Local),
			IsActive:        true,
		},
	}
	for i := range promos {
		db.Create(&promos[i])
	}

	log.Println("catalog seeding done: 14 items, 3 combos, 2 promotions")
}
