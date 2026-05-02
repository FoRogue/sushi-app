# gateway

Единая точка входа для всех клиентов (Flutter). Проверяет JWT токены и проксирует запросы к нужному микросервису.

**Порт:** `8080`

## Переменные окружения

| Переменная          | Описание                            |
|---------------------|-------------------------------------|
| JWT_SECRET          | Секрет для валидации JWT            |
| AUTH_SERVICE_URL    | Адрес auth-service                  |
| CATALOG_SERVICE_URL | Адрес catalog-service               |
| ORDER_SERVICE_URL   | Адрес order-service                 |
| PORT                | Порт gateway (по умолч. 8080)       |

## Запуск

```bash
cp .env.example .env
go run ./cmd/main.go
```

## Маршрутизация

Gateway принимает все запросы на `localhost:8080` и перенаправляет их:

| Маршрут gateway          | Куда уходит              | JWT |
|--------------------------|--------------------------|-----|
| `/api/auth/*`            | auth-service             | Нет |
| `/api/catalog/*`         | catalog-service          | Да  |
| `/api/orders/*`          | order-service            | Да  |

### Пример пути

```
Flutter → POST /api/auth/login/customer
              ↓
          gateway:8080
              ↓  переписывает путь
          auth-service:8081 → POST /api/login/customer
```

## Авторизация

Для защищённых маршрутов (`/api/catalog/*`, `/api/orders/*`) нужен заголовок:

```
Authorization: Bearer <access_token>
```

Если токен валидный — gateway добавляет в запрос к сервису:
- `X-User-ID` — ID пользователя
- `X-User-Role` — роль (`customer`, `courier`, `shop`)

## Коды ошибок

| Код | Причина                        |
|-----|--------------------------------|
| 401 | Токен отсутствует или истёк    |
