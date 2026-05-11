FROM golang:1.25-alpine AS builder
WORKDIR /app
COPY go.mod go.sum ./
RUN go mod download
COPY . .
RUN CGO_ENABLED=0 GOOS=linux go build -o /catalog-service ./cmd/

FROM alpine:3.20
WORKDIR /app
COPY --from=builder /catalog-service .
EXPOSE 8082
CMD ["./catalog-service"]
