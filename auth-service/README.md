# auth-service

Сервис аутентификации. Отвечает за регистрацию, вход и управление JWT токенами для трёх типов пользователей.

**Порт:** `8081`

## Переменные окружения

| Переменная    | Описание                        |
|---------------|---------------------------------|
| DB_HOST       | Хост PostgreSQL                 |
| DB_PORT       | Порт PostgreSQL (по умолч. 5432)|
| DB_DATABASE   | Название БД (`sushi_auth_db`)   |
| DB_USERNAME   | Пользователь БД                 |
| DB_PASSWORD   | Пароль БД                       |
| JWT_SECRET    | Секрет для подписи JWT          |
| PORT          | Порт сервиса (по умолч. 8081)   |

## Запуск

```bash
cp .env.example .env
# заполнить .env

go run ./cmd/main.go
```

## API

Все маршруты с префиксом `/api`.

---

### Регистрация покупателя

`POST /api/register/customer`

**Тело запроса:**
```json
{
  "name": "Иван",
  "phone": "+79991234567",
  "password": "secret123"
}
```

**Ответ `201`:**
```json
{ "message": "Регистрация успешна" }
```

---

### Регистрация курьера

`POST /api/register/courier`

**Тело запроса:**
```json
{
  "full_name": "Иванов Иван Иванович",
  "vehicle_code": "А123БВ777",
  "password": "secret123"
}
```

**Ответ `201`:**
```json
{ "message": "Регистрация успешна" }
```

---

### Регистрация магазина

`POST /api/register/shop`

**Тело запроса:**
```json
{
  "name": "Суши Бар №1",
  "login": "sushi_bar_1",
  "address": "г. Москва, ул. Пушкина, д. 1",
  "password": "secret123"
}
```

**Ответ `201`:**
```json
{ "message": "Регистрация успешна" }
```

---

### Вход покупателя

`POST /api/login/customer`

**Тело запроса:**
```json
{
  "phone": "+79991234567",
  "password": "secret123"
}
```

**Ответ `200`:**
```json
{
  "access_token": "<JWT, живёт 15 минут>",
  "refresh_token": "<токен, живёт 30 дней>"
}
```

---

### Вход курьера

`POST /api/login/courier`

**Тело запроса:**
```json
{
  "vehicle_code": "А123БВ777",
  "password": "secret123"
}
```

**Ответ `200`:**
```json
{
  "access_token": "...",
  "refresh_token": "..."
}
```

---

### Вход магазина

`POST /api/login/shop`

**Тело запроса:**
```json
{
  "login": "sushi_bar_1",
  "password": "secret123"
}
```

**Ответ `200`:**
```json
{
  "access_token": "...",
  "refresh_token": "..."
}
```

---

### Обновление токенов

`POST /api/refresh`

**Тело запроса:**
```json
{
  "refresh_token": "<refresh_token из login>"
}
```

**Ответ `200`:**
```json
{
  "access_token": "<новый access_token>",
  "refresh_token": "<новый refresh_token>"
}
```

> Refresh токен одноразовый — после использования выдаётся новая пара токенов (rotation).

---

## Коды ошибок

| Код | Причина                              |
|-----|--------------------------------------|
| 400 | Неверный формат запроса              |
| 401 | Неверные учётные данные              |
| 409 | Пользователь уже существует          |
| 500 | Внутренняя ошибка сервера            |
