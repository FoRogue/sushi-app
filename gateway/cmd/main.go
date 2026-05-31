package main

import (
	"log"
	"os"

	"gateway/internal/middleware"
	"gateway/internal/proxy"

	"github.com/gin-contrib/cors"
	"github.com/gin-gonic/gin"
	"github.com/joho/godotenv"
)

func main() {
	if err := godotenv.Load(); err != nil {
		log.Println("No .env file, using environment variables")
	}

	jwtSecret := os.Getenv("JWT_SECRET")
	authURL := os.Getenv("AUTH_SERVICE_URL")
	catalogURL := os.Getenv("CATALOG_SERVICE_URL")
	orderURL := os.Getenv("ORDER_SERVICE_URL")

	r := gin.Default()
	r.Use(cors.Default())

	api := r.Group("/api")

	// Публичные маршруты — без JWT
	authProxy := proxy.New(authURL, "auth")
	auth := api.Group("/auth")
	{
		auth.POST("/register/*path", authProxy)
		auth.POST("/login/*path", authProxy)
		auth.POST("/refresh", authProxy)
	}

	// Защищённые маршруты — требуют валидный JWT
	authMW := middleware.Auth(jwtSecret)

	// Защищённые эндпоинты auth-service (список магазинов и др.)
	usersProxy := proxy.New(authURL, "users")
	usersGroup := api.Group("/users")
	usersGroup.Use(authMW)
	usersGroup.Any("/*path", usersProxy)

	catalog := api.Group("/catalog")
	catalog.Use(authMW)
	catalog.Any("/*path", proxy.New(catalogURL, "catalog"))

	orders := api.Group("/orders")
	orders.Use(authMW)
	orders.Any("/*path", proxy.New(orderURL, "orders"))

	port := os.Getenv("PORT")
	if port == "" {
		port = "8080"
	}

	log.Printf("gateway running on :%s", port)
	log.Fatal(r.Run(":" + port))
}
