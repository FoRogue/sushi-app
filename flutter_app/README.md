# Flutter App — Sushi Delivery

Одно Flutter-приложение для трёх ролей: **customer** (покупатель), **courier** (курьер), **shop** (магазин).
После логина приложение смотрит на `role` в JWT-токене и показывает нужный интерфейс.

---

## Архитектура взаимодействия

```
Flutter App
    │
    │  REST (JSON)        единственная точка входа
    ▼
API Gateway :8080
    │
    ├── /api/auth/*      → auth-service   :8081
    ├── /api/catalog/*   → catalog-service :8082
    └── /api/orders/*    → order-service  :8083
```

Приложение **никогда не ходит напрямую** к сервисам — только через gateway на порт 8080.

### Токены
- При логине получаем `access_token` (живёт ~15 мин) и `refresh_token` (~30 дней).
- `access_token` кладём в заголовок: `Authorization: Bearer <token>`.
- Когда `access_token` протух — тихо обновляем через `POST /api/auth/refresh`.
- `refresh_token` и `access_token` храним в `shared_preferences` (на Flutter Web `flutter_secure_storage` зависает из-за WebCrypto API).

---

## Экраны по ролям

### customer — Покупатель

| Экран | Описание |
|-------|----------|
| **Каталог** | Список роллов/суши/напитков. Фильтр по типу. |
| **Карточка позиции** | Фото, описание, цена, кнопка "В корзину". |
| **Комбо-сеты** | Список сетов со скидкой и расчётом цены. |
| **Корзина** | Позиции + количество + итоговая сумма. |
| **Оформление заказа** | Ввод адреса доставки, подтверждение. |
| **Мои заказы** | История заказов + текущий статус. |
| **Детали заказа** | Состав + статус в реальном времени. |

### courier — Курьер

| Экран | Описание |
|-------|----------|
| **Доступные заказы** | Заказы со статусом `accepted` — можно взять. |
| **Мои доставки** | Взятые заказы (`picked_up`). |
| **Детали заказа** | Адрес доставки + состав + кнопка смены статуса. |

Статусы которые курьер меняет:
- Нажал "Забрал заказ" → `accepted` → `picked_up`
- Нажал "Подтвердить доставку" → `picked_up` → `delivered`
- Нажал "Отказаться" → заказ возвращается в пул, курьер больше не видит его

### shop — Магазин

| Экран | Описание |
|-------|----------|
| **Входящие заказы** | Новые заказы (`pending`). Принять / Отменить. |
| **В работе** | Принятые заказы (`accepted`). |
| **Каталог (управление)** | Список позиций с кнопками редактировать / вкл-выкл. |
| **Добавить / редактировать позицию** | Форма: название, цена, тип, доступность. |
| **Комбо-сеты** | Список сетов, создание/редактирование. |
| **Акции** | Список акций, создание/редактирование. |

---

## Машина состояний заказа

```
  [customer]         [shop]           [courier]
      │                │                  │
   создаёт          принимает          берёт заказ
      │                │                  │
  pending  ──────► accepted ──────► picked_up ──────► delivered
      │                │
      └──── cancelled ◄┘
         (customer или shop)
```

---

## Что ждём от реализации

### Обязательно (MVP)
- [ ] Авторизация (логин) с сохранением токенов
- [ ] Автообновление access_token через refresh
- [ ] Роль-роутинг после логина (три разных "домашних" экрана)
- [ ] Каталог с фильтрацией для customer
- [ ] Корзина (локальный стейт)
- [ ] Создание заказа
- [ ] Просмотр своих заказов с текущим статусом
- [ ] Смена статуса заказа (shop принимает, courier доставляет)

### Желательно
- [ ] Реальный тайм статус через WebSocket или polling каждые 5 сек
- [ ] Экран комбо-сетов
- [ ] Экран акций
- [ ] Pull-to-refresh везде где есть списки
- [ ] Обработка ошибок сети (нет интернета, 401, 5xx)

### Не в MVP
- Пуш-уведомления
- Карта для курьера
- Оплата онлайн

---

## API — ключевые запросы

```
# Логин
POST /api/auth/login/customer
{ "phone": "+79001234567", "password": "secret" }
→ { "access_token": "...", "refresh_token": "..." }

# Обновление токена
POST /api/auth/refresh
{ "refresh_token": "..." }
→ { "access_token": "..." }

# Каталог
GET /api/catalog/items?type=roll
GET /api/catalog/combos
GET /api/catalog/promotions

# Заказы
POST /api/orders/
{ "shop_id": 3, "address": "ул. Пушкина, д. 1", "items": [{ "menu_item_id": 5, "quantity": 2 }] }

GET /api/orders          # список (каждый видит своё по роли)
GET /api/orders/:id

PATCH /api/orders/:id/status
{ "status": "accepted" }   # shop принимает
{ "status": "picked_up" }  # courier берёт
{ "status": "delivered" }  # courier доставил
{ "status": "cancelled" }  # shop или customer отменяет
```

---

## Рекомендуемый стек

| Задача | Пакет |
|--------|-------|
| HTTP-клиент | `dio` + interceptor для токенов |
| Хранение токенов | `shared_preferences` |
| Стейт-менеджмент | `riverpod` или `bloc` |
| Навигация | `go_router` |
| JSON-модели | `freezed` + `json_serializable` |

---

## Структура `lib/` (план)

```
lib/
├── main.dart
├── app.dart                 # MaterialApp + go_router
├── core/
│   ├── api/
│   │   ├── dio_client.dart  # базовый dio с interceptor
│   │   └── endpoints.dart   # константы URL
│   └── storage/
│       └── token_storage.dart
├── features/
│   ├── auth/
│   │   ├── data/            # AuthRepository, модели
│   │   └── presentation/    # LoginScreen
│   ├── catalog/
│   │   ├── data/
│   │   └── presentation/    # CatalogScreen, ItemCard, ComboScreen
│   ├── orders/
│   │   ├── data/
│   │   └── presentation/    # CartScreen, OrdersScreen, OrderDetailScreen
│   └── shop/
│       ├── data/
│       └── presentation/    # IncomingOrdersScreen, CatalogManagementScreen
└── shared/
    ├── widgets/             # общие компоненты
    └── models/              # общие модели (если нужны)
```
