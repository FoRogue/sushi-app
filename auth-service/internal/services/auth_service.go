package services

import (
	"crypto/rand"
	"encoding/hex"
	"time"

	"auth-service/internal/models"

	"github.com/golang-jwt/jwt/v5"
	"gorm.io/gorm"
)

type Claims struct {
	UserID uint   `json:"user_id"`
	Role   string `json:"role"`
	jwt.RegisteredClaims
}

type AuthService struct {
	db        *gorm.DB
	jwtSecret string
}

func NewAuthService(db *gorm.DB, jwtSecret string) *AuthService {
	return &AuthService{db: db, jwtSecret: jwtSecret}
}

func (s *AuthService) GenerateTokenPair(userID uint, role string) (accessToken, refreshToken string, err error) {
	claims := Claims{
		UserID: userID,
		Role:   role,
		RegisteredClaims: jwt.RegisteredClaims{
			ExpiresAt: jwt.NewNumericDate(time.Now().Add(15 * time.Minute)),
			IssuedAt:  jwt.NewNumericDate(time.Now()),
		},
	}

	token := jwt.NewWithClaims(jwt.SigningMethodHS256, claims)
	accessToken, err = token.SignedString([]byte(s.jwtSecret))
	if err != nil {
		return
	}

	b := make([]byte, 32)
	if _, err = rand.Read(b); err != nil {
		return
	}
	refreshToken = hex.EncodeToString(b)

	err = s.db.Create(&models.RefreshToken{
		UserID:    userID,
		Token:     refreshToken,
		ExpiresAt: time.Now().Add(30 * 24 * time.Hour),
	}).Error
	return
}

func (s *AuthService) RefreshTokens(refreshToken string) (newAccess, newRefresh string, err error) {
	var rt models.RefreshToken
	if err = s.db.Where("token = ? AND expires_at > ?", refreshToken, time.Now()).First(&rt).Error; err != nil {
		return
	}

	var user models.User
	if err = s.db.First(&user, rt.UserID).Error; err != nil {
		return
	}

	s.db.Delete(&rt)
	return s.GenerateTokenPair(user.ID, user.Role)
}

func (s *AuthService) ValidateAccessToken(tokenString string) (*Claims, error) {
	token, err := jwt.ParseWithClaims(tokenString, &Claims{}, func(t *jwt.Token) (interface{}, error) {
		return []byte(s.jwtSecret), nil
	})
	if err != nil {
		return nil, err
	}
	claims, ok := token.Claims.(*Claims)
	if !ok || !token.Valid {
		return nil, jwt.ErrTokenInvalidClaims
	}
	return claims, nil
}
