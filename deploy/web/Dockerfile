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

# Build web release (CanvasKit par défaut pour le rendu).
# - `--pwa-strategy=none` : plus de service worker « hors ligne d'abord »
#   (il servait une version périmée de l'app depuis son cache).
# - `MT_WEB_BUILD` : version compilée, comparée à /version.json pour
#   proposer « Recharger » après un déploiement (WebVersionWatcher).
# - L'interrupteur d'arrêt remplace le service worker vide généré : les
#   navigateurs qui ont encore l'ancien s'en débarrassent seuls.
RUN APP_VERSION="$(sed -n 's/^version:[[:space:]]*//p' pubspec.yaml | tr -d '\r')" \
 && flutter build web --release --base-href "/" --pwa-strategy=none \
      --dart-define=MT_WEB_BUILD="$APP_VERSION" \
 && cp deploy/web/flutter_service_worker.js build/web/flutter_service_worker.js

# ─────────────────────────────────────────────────────────────
# Stage 2 : Nginx static server
# ─────────────────────────────────────────────────────────────
FROM nginx:1.27-alpine

# wget n'est pas garanti dans nginx:alpine — on l'ajoute explicitement
# pour le HEALTHCHECK ci-dessous. Sans ça : "wget: not found" au démarrage
# → unhealthy → docker compose up échoue / restart loop.
RUN apk add --no-cache wget

# Conf Nginx custom (gzip, SPA fallback, headers sécurité, cache)
COPY deploy/web/nginx.conf /etc/nginx/conf.d/default.conf

# Copie les artefacts Flutter web
COPY --from=build /app/build/web /usr/share/nginx/html

# Healthcheck sur /health (endpoint léger défini dans nginx.conf)
HEALTHCHECK --interval=30s --timeout=5s --start-period=10s --retries=3 \
  CMD wget -q -O - http://localhost:80/health > /dev/null || exit 1

EXPOSE 80
