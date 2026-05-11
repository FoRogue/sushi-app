# ── Stage 1: Build Flutter web ───────────────────────────────────────────────
FROM ghcr.io/cirruslabs/flutter:stable AS builder

WORKDIR /app

# Cache pub dependencies separately from source
COPY pubspec.yaml pubspec.lock* ./
RUN flutter pub get

# Copy source and build
COPY . .
RUN flutter build web --release

# ── Stage 2: Serve with nginx ─────────────────────────────────────────────────
FROM nginx:1.27-alpine

COPY --from=builder /app/build/web /usr/share/nginx/html
COPY nginx.conf /etc/nginx/conf.d/default.conf

EXPOSE 80
CMD ["nginx", "-g", "daemon off;"]
