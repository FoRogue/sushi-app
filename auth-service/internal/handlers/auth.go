package handlers

import (
	"net/http"

	"auth-service/internal/models"
	"auth-service/internal/services"

	"github.com/gin-gonic/gin"
	"golang.org/x/crypto/bcrypt"
	"gorm.io/gorm"
)

type AuthHandler struct {
	service *services.AuthService
	db      *gorm.DB
}

func NewAuthHandler(db *gorm.DB, jwtSecret string) *AuthHandler {
	return &AuthHandler{
		service: services.NewAuthService(db, jwtSecret),
		db:      db,
	}
}

func hashPassword(password string) (string, error) {
	hash, err := bcrypt.GenerateFromPassword([]byte(password), bcrypt.DefaultCost)
	return string(hash), err
}

func checkPassword(hash, password string) bool {
	return bcrypt.CompareHashAndPassword([]byte(hash), []byte(password)) == nil
}

// --- Register ---

type RegisterCustomerInput struct {
	Name     string `json:"name" binding:"required"`
	Phone    string `json:"phone" binding:"required"`
	Password string `json:"password" binding:"required,min=6"`
}

func (h *AuthHandler) RegisterCustomer(c *gin.Context) {
	var input RegisterCustomerInput
	if err := c.ShouldBindJSON(&input); err != nil {
		c.JSON(http.StatusBadRequest, gin.H{"error": err.Error()})
		return
	}

	var existing models.User
	if h.db.Where("phone = ?", input.Phone).First(&existing).Error == nil {
		c.JSON(http.StatusConflict, gin.H{"error": "Телефон уже зарегистрирован"})
		return
	}

	hash, err := hashPassword(input.Password)
	if err != nil {
		c.JSON(http.StatusInternalServerError, gin.H{"error": "Ошибка сервера"})
		return
	}

	name, phone := input.Name, input.Phone
	user := models.User{Role: models.RoleCustomer, PasswordHash: hash, Name: &name, Phone: &phone}
	if err := h.db.Create(&user).Error; err != nil {
		c.JSON(http.StatusInternalServerError, gin.H{"error": "Не удалось создать пользователя"})
		return
	}

	c.JSON(http.StatusCreated, gin.H{"message": "Регистрация успешна"})
}

type RegisterCourierInput struct {
	VehicleCode string `json:"vehicle_code" binding:"required"`
	Password    string `json:"password" binding:"required,min=6"`
}

func (h *AuthHandler) RegisterCourier(c *gin.Context) {
	var input RegisterCourierInput
	if err := c.ShouldBindJSON(&input); err != nil {
		c.JSON(http.StatusBadRequest, gin.H{"error": err.Error()})
		return
	}

	var existing models.User
	if h.db.Where("vehicle_code = ?", input.VehicleCode).First(&existing).Error == nil {
		c.JSON(http.StatusConflict, gin.H{"error": "Такой код уже зарегистрирован"})
		return
	}

	hash, err := hashPassword(input.Password)
	if err != nil {
		c.JSON(http.StatusInternalServerError, gin.H{"error": "Ошибка сервера"})
		return
	}

	vc := input.VehicleCode
	user := models.User{Role: models.RoleCourier, PasswordHash: hash, VehicleCode: &vc}
	if err := h.db.Create(&user).Error; err != nil {
		c.JSON(http.StatusInternalServerError, gin.H{"error": "Не удалось создать пользователя"})
		return
	}

	c.JSON(http.StatusCreated, gin.H{"message": "Регистрация успешна"})
}

type RegisterShopInput struct {
	Name     string `json:"name" binding:"required"`
	Address  string `json:"address" binding:"required"`
	Password string `json:"password" binding:"required,min=6"`
}

func (h *AuthHandler) RegisterShop(c *gin.Context) {
	var input RegisterShopInput
	if err := c.ShouldBindJSON(&input); err != nil {
		c.JSON(http.StatusBadRequest, gin.H{"error": err.Error()})
		return
	}

	var existing models.User
	if h.db.Where("address = ?", input.Address).First(&existing).Error == nil {
		c.JSON(http.StatusConflict, gin.H{"error": "Такой адрес уже зарегистрирован"})
		return
	}

	hash, err := hashPassword(input.Password)
	if err != nil {
		c.JSON(http.StatusInternalServerError, gin.H{"error": "Ошибка сервера"})
		return
	}

	name, address := input.Name, input.Address
	user := models.User{Role: models.RoleShop, PasswordHash: hash, Name: &name, Address: &address}
	if err := h.db.Create(&user).Error; err != nil {
		c.JSON(http.StatusInternalServerError, gin.H{"error": "Не удалось создать пользователя"})
		return
	}

	c.JSON(http.StatusCreated, gin.H{"message": "Регистрация успешна"})
}

// --- Login ---

type LoginCustomerInput struct {
	Phone    string `json:"phone" binding:"required"`
	Password string `json:"password" binding:"required"`
}

func (h *AuthHandler) LoginCustomer(c *gin.Context) {
	var input LoginCustomerInput
	if err := c.ShouldBindJSON(&input); err != nil {
		c.JSON(http.StatusBadRequest, gin.H{"error": err.Error()})
		return
	}

	var user models.User
	if err := h.db.Where("phone = ? AND role = ?", input.Phone, models.RoleCustomer).First(&user).Error; err != nil {
		c.JSON(http.StatusUnauthorized, gin.H{"error": "Неверный телефон или пароль"})
		return
	}

	if !checkPassword(user.PasswordHash, input.Password) {
		c.JSON(http.StatusUnauthorized, gin.H{"error": "Неверный телефон или пароль"})
		return
	}

	access, refresh, err := h.service.GenerateTokenPair(user.ID, user.Role)
	if err != nil {
		c.JSON(http.StatusInternalServerError, gin.H{"error": "Ошибка генерации токена"})
		return
	}

	c.JSON(http.StatusOK, gin.H{"access_token": access, "refresh_token": refresh})
}

type LoginCourierInput struct {
	VehicleCode string `json:"vehicle_code" binding:"required"`
	Password    string `json:"password" binding:"required"`
}

func (h *AuthHandler) LoginCourier(c *gin.Context) {
	var input LoginCourierInput
	if err := c.ShouldBindJSON(&input); err != nil {
		c.JSON(http.StatusBadRequest, gin.H{"error": err.Error()})
		return
	}

	var user models.User
	if err := h.db.Where("vehicle_code = ? AND role = ?", input.VehicleCode, models.RoleCourier).First(&user).Error; err != nil {
		c.JSON(http.StatusUnauthorized, gin.H{"error": "Неверный код или пароль"})
		return
	}

	if !checkPassword(user.PasswordHash, input.Password) {
		c.JSON(http.StatusUnauthorized, gin.H{"error": "Неверный код или пароль"})
		return
	}

	access, refresh, err := h.service.GenerateTokenPair(user.ID, user.Role)
	if err != nil {
		c.JSON(http.StatusInternalServerError, gin.H{"error": "Ошибка генерации токена"})
		return
	}

	c.JSON(http.StatusOK, gin.H{"access_token": access, "refresh_token": refresh})
}

type LoginShopInput struct {
	Address  string `json:"address" binding:"required"`
	Password string `json:"password" binding:"required"`
}

func (h *AuthHandler) LoginShop(c *gin.Context) {
	var input LoginShopInput
	if err := c.ShouldBindJSON(&input); err != nil {
		c.JSON(http.StatusBadRequest, gin.H{"error": err.Error()})
		return
	}

	var user models.User
	if err := h.db.Where("address = ? AND role = ?", input.Address, models.RoleShop).First(&user).Error; err != nil {
		c.JSON(http.StatusUnauthorized, gin.H{"error": "Неверный адрес или пароль"})
		return
	}

	if !checkPassword(user.PasswordHash, input.Password) {
		c.JSON(http.StatusUnauthorized, gin.H{"error": "Неверный адрес или пароль"})
		return
	}

	access, refresh, err := h.service.GenerateTokenPair(user.ID, user.Role)
	if err != nil {
		c.JSON(http.StatusInternalServerError, gin.H{"error": "Ошибка генерации токена"})
		return
	}

	c.JSON(http.StatusOK, gin.H{"access_token": access, "refresh_token": refresh})
}

// --- Refresh ---

type RefreshInput struct {
	RefreshToken string `json:"refresh_token" binding:"required"`
}

func (h *AuthHandler) Refresh(c *gin.Context) {
	var input RefreshInput
	if err := c.ShouldBindJSON(&input); err != nil {
		c.JSON(http.StatusBadRequest, gin.H{"error": err.Error()})
		return
	}

	access, refresh, err := h.service.RefreshTokens(input.RefreshToken)
	if err != nil {
		c.JSON(http.StatusUnauthorized, gin.H{"error": "Недействительный refresh token"})
		return
	}

	c.JSON(http.StatusOK, gin.H{"access_token": access, "refresh_token": refresh})
}
