# syntax=docker/dockerfile:1.6

# ─────────────────────────────────────────────────────────────
# Stage 1 : Build Flutter Web
# ─────────────────────────────────────────────────────────────
FROM ghcr.io/cirruslabs/flutter:3.32.0 AS build

WORKDIR /app

# Copie les manifests pour cache des deps
COPY pubspec.yaml pubspec.lock ./

# Pré-fetch des dependencies (cache layer)
RUN flutter pub get

# Copie tout le code source
COPY . .

# Le fichier .env.production est injecté par le CI dans assets/env/.env.production
# avant le build Docker (cf. workflow web-deploy.yml).

# Build web release (CanvasKit par défaut pour le rendu)
RUN flutter build web --release --base-href "/"

# ─────────────────────────────────────────────────────────────
# Stage 2 : Nginx static server
# ─────────────────────────────────────────────────────────────
FROM nginx:1.27-alpine

# Conf Nginx custom (gzip, SPA fallback, headers sécurité, cache)
COPY deploy/web/nginx.conf /etc/nginx/conf.d/default.conf

# Copie les artefacts Flutter web
COPY --from=build /app/build/web /usr/share/nginx/html

# Healthcheck sur la racine
HEALTHCHECK --interval=30s --timeout=5s --start-period=10s --retries=3 \
  CMD wget -q -O - http://localhost:80/ > /dev/null || exit 1

EXPOSE 80
