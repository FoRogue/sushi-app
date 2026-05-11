FROM golang:1.25-alpine AS builder
WORKDIR /app
COPY go.mod ./
RUN go mod download
COPY . .
RUN CGO_ENABLED=0 GOOS=linux go build -o /order-service ./cmd/main.go

FROM alpine:3.20
WORKDIR /app
COPY --from=builder /order-service .
EXPOSE 8083
CMD ["./order-service"]
