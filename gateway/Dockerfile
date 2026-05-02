FROM golang:1.25-alpine AS builder
WORKDIR /app
COPY . .
RUN go mod tidy && CGO_ENABLED=0 GOOS=linux go build -o /gateway ./cmd/main.go

FROM alpine:3.20
WORKDIR /app
COPY --from=builder /gateway .
EXPOSE 8080
CMD ["./gateway"]
