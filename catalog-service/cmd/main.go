package main

import (
	"fmt"
	"log"
	"os"
	"time"

	"catalog-service/internal/handlers"
	"catalog-service/internal/middleware"
	"catalog-service/internal/models"

	"github.com/gin-contrib/cors"
	"github.com/gin-gonic/gin"
	"github.com/joho/godotenv"
	"gorm.io/driver/postgres"
	"gorm.io/gorm"
)

func main() {
	if err := godotenv.Load(); err != nil {
		log.Println("No .env file, using environment variables")
	}

	dsn := fmt.Sprintf(
		"host=%s port=%s user=%s password=%s dbname=%s sslmode=disable",
		os.Getenv("DB_HOST"),
		os.Getenv("DB_PORT"),
		os.Getenv("DB_USERNAME"),
		os.Getenv("DB_PASSWORD"),
		os.Getenv("DB_DATABASE"),
	)

	var db *gorm.DB
	var err error
	for i := range 10 {
		db, err = gorm.Open(postgres.Open(dsn), &gorm.Config{})
		if err == nil {
			break
		}
		log.Printf("db connect attempt %d failed: %v", i+1, err)
		time.Sleep(2 * time.Second)
	}
	if err != nil {
		log.Fatal("failed to connect to database:", err)
	}

	if err := db.AutoMigrate(
		&models.MenuItem{},
		&models.Combo{},
		&models.ComboItem{},
		&models.Promotion{},
	); err != nil {
		log.Fatal("failed to migrate:", err)
	}

	seed(db)

	items := handlers.NewItemHandler(db)
	combos := handlers.NewComboHandler(db)
	promos := handlers.NewPromotionHandler(db)

	r := gin.Default()
	r.Use(cors.Default())

	api := r.Group("/api")
	shopOnly := middleware.RequireRole("shop")

	itemsGroup := api.Group("/items")
	{
		itemsGroup.GET("", items.List)
		itemsGroup.GET("/:id", items.Get)
		itemsGroup.POST("", shopOnly, items.Create)
		itemsGroup.PUT("/:id", shopOnly, items.Update)
		itemsGroup.DELETE("/:id", shopOnly, items.Delete)
	}

	combosGroup := api.Group("/combos")
	{
		combosGroup.GET("", combos.List)
		combosGroup.GET("/:id", combos.Get)
		combosGroup.POST("", shopOnly, combos.Create)
		combosGroup.PUT("/:id", shopOnly, combos.Update)
		combosGroup.DELETE("/:id", shopOnly, combos.Delete)
	}

	promosGroup := api.Group("/promotions")
	{
		promosGroup.GET("", promos.List)
		promosGroup.GET("/:id", promos.Get)
		promosGroup.POST("", shopOnly, promos.Create)
		promosGroup.PUT("/:id", shopOnly, promos.Update)
		promosGroup.DELETE("/:id", shopOnly, promos.Delete)
	}

	port := os.Getenv("PORT")
	if port == "" {
		port = "8082"
	}

	log.Printf("catalog-service running on :%s", port)
	log.Fatal(r.Run(":" + port))
}
