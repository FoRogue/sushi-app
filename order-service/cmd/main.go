package main

import (
	"fmt"
	"log"
	"os"
	"time"

	"order-service/internal/clients"
	"order-service/internal/handlers"
	"order-service/internal/middleware"
	"order-service/internal/models"

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

	if err := db.AutoMigrate(&models.Order{}, &models.OrderItem{}, &models.OrderDecline{}); err != nil {
		log.Fatal("failed to migrate:", err)
	}

	catalogURL := os.Getenv("CATALOG_SERVICE_URL")
	catalog := clients.NewCatalogClient(catalogURL)
	orders := handlers.NewOrderHandler(db, catalog)

	r := gin.Default()
	r.Use(cors.Default())

	api := r.Group("/api")
	customerOnly := middleware.RequireRole("customer")
	allRoles := middleware.RequireRole("customer", "courier", "shop")
	courierOnly := middleware.RequireRole("courier")

	ordersGroup := api.Group("")
	{
		ordersGroup.POST("/", customerOnly, orders.Create)
		ordersGroup.GET("/", allRoles, orders.List)
		ordersGroup.GET("/:id", allRoles, orders.Get)
		ordersGroup.PATCH("/:id/status", allRoles, orders.UpdateStatus)
		ordersGroup.POST("/:id/decline", courierOnly, orders.Decline)
	}

	port := os.Getenv("PORT")
	if port == "" {
		port = "8083"
	}

	log.Printf("order-service running on :%s", port)
	log.Fatal(r.Run(":" + port))
}
