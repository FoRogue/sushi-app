package main

import (
	"fmt"
	"log"
	"os"

	"auth-service/internal/handlers"
	"auth-service/internal/models"

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
		"host=%s user=%s password=%s dbname=%s port=%s sslmode=disable",
		os.Getenv("DB_HOST"),
		os.Getenv("DB_USERNAME"),
		os.Getenv("DB_PASSWORD"),
		os.Getenv("DB_DATABASE"),
		os.Getenv("DB_PORT"),
	)

	db, err := gorm.Open(postgres.Open(dsn), &gorm.Config{})
	if err != nil {
		log.Fatal("Failed to connect to database:", err)
	}

	if err := db.AutoMigrate(&models.User{}, &models.RefreshToken{}); err != nil {
		log.Fatal("Failed to migrate database:", err)
	}

	h := handlers.NewAuthHandler(db, os.Getenv("JWT_SECRET"))

	r := gin.Default()
	r.Use(cors.Default())

	api := r.Group("/api")
	{
		api.POST("/register/customer", h.RegisterCustomer)
		api.POST("/register/courier", h.RegisterCourier)
		api.POST("/register/shop", h.RegisterShop)

		api.POST("/login/customer", h.LoginCustomer)
		api.POST("/login/courier", h.LoginCourier)
		api.POST("/login/shop", h.LoginShop)

		api.POST("/refresh", h.Refresh)
	}

	port := os.Getenv("PORT")
	if port == "" {
		port = "8081"
	}

	log.Printf("auth-service running on :%s", port)
	log.Fatal(r.Run(":" + port))
}
