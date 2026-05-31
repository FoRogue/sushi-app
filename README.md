# Sushi Delivery App

Automated information system for sushi roll delivery. Diploma project.

## Stack

- **Backend:** Go (microservices)
- **Mobile:** Flutter
- **Internal RPC:** gRPC + protobuf
- **External API:** REST + WebSocket
- **Database:** PostgreSQL (one per service)
- **Cache / Pub-Sub:** Redis
- **Containerization:** Docker + Docker Compose

## Architecture

```
Flutter App
    |
API Gateway (Go) — JWT validation, routing
    |
    ├── auth-service    + PostgreSQL
    ├── catalog-service + PostgreSQL
    └── order-service   + PostgreSQL
    
Redis — refresh tokens, order event pub/sub, cache
```

## User Roles

| Role | Registration | Access |
|------|-------------|--------|
| Customer | Phone + password | Place orders, track delivery |
| Courier | Full name + vehicle code | Accept, deliver, or decline orders |
| Shop | Name + login + address + password | Manage catalog, accept orders |

## Getting Started

```bash
cp auth-service/.env.example auth-service/.env
# fill in your values

docker compose up --build
```
