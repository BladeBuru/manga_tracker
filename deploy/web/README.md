# Déploiement Web — Manga Tracker

Pipeline complet : Flutter Web → Docker (Nginx) → TrueNAS NAS → `app.bladeburu.com`

---

## Architecture

```
   Browser
      ↓ HTTPS
   NPMplus (TrueNAS) ── reverse proxy + Crowdsec
      ↓ HTTP
   Container Docker `manga-tracker-web` (Nginx 1.27 alpine, port 8080:80)
      ↓ statique
   build/web/ (généré par Flutter Web --release)
```

L'app Flutter consomme l'API NestJS sur `https://api.bladeburu.com` (CORS déjà whitelisté côté API : `CORS_ORIGINS=https://api.bladeburu.com,https://app.bladeburu.com`).

---

## Prérequis (one-time setup)

### 1. Secret GitHub — `WEB_ENV_PRODUCTION`

Créer le secret avec le contenu de `assets/env/.env.production` pour le web :

```env
MT_API_URL=https://api.bladeburu.com
```

Ajouter via : **Settings → Secrets and variables → Actions → New repository secret**

### 2. Secrets déjà partagés avec l'API (réutilisés)

- `DOCKERHUB_USER`, `DOCKERHUB_TOKEN` — push Docker Hub
- `NAS_HOST`, `NAS_PORT`, `NAS_USER`, `NAS_SSH_KEY` — SSH NAS

### 3. NPMplus — Proxy host pour `app.bladeburu.com`

Dans NPMplus (TrueNAS) :
- **Domain Names** : `app.bladeburu.com`
- **Forward Hostname** : `192.168.1.119` (ou `localhost` si NPMplus tourne sur le même host)
- **Forward Port** : `8080`
- **SSL** : Let's Encrypt + Force HTTPS
- **WAF** : Crowdsec activé

### 4. DNS

`app.bladeburu.com` → IP publique du NAS (CNAME ou A record)

---

## Déploiement

### Manuel (recommandé pour première mise en ligne)

```
GitHub → Actions → Web Deploy — Manga Tracker → Run workflow
```

Le workflow :
1. **test-build** : `flutter build web` valide la compilation
2. **build-and-push** : multi-stage Docker → `bladeburu/manga-tracker-web:latest` + `:sha-XXXX`
3. **deploy** : SSH au NAS → `midclt app.create` (1ère fois) ou `app.update` → polling RUNNING (max 2min)
4. **smoke-test** : `curl https://app.bladeburu.com/` × 5 retries

### Automatique (à activer plus tard)

Décommenter dans `web-deploy.yml` :
```yaml
on:
  push:
    branches: [dev]
```

---

## Restauration / rollback

### Tag précédent
Le workflow tague chaque image avec `sha-XXXXXXXX`. Pour rollback :

```bash
# SSH NAS
midclt call -j app.update manga-tracker-web '{"custom_compose_config_string":"<compose avec ancien tag>"}'
```

Ou via l'UI TrueNAS : **Apps → manga-tracker-web → Edit → changer le tag**.

### Reconstruire à partir d'une commit
```bash
git checkout <sha>
gh workflow run web-deploy.yml
```

---

## Limitations connues (Phase 1)

L'app web fonctionne pour **auth + bibliothèque + recherche + détails manga**. Sont **désactivés** sur web (stubs propres, pas de crash) :

- ❌ Téléchargement de chapitres (pas de système de fichiers persistant)
- ❌ Lecteur hors-ligne
- ❌ WebView intégré pour les sites de scan → ouvre le lien dans un nouvel onglet
- ❌ Vérification background des nouveaux chapitres (workmanager Android-only)
- ❌ Notifications push locales

**À venir (Phase 2+)** :
- Migration `MaterialPageRoute → go_router` (deep-linking web : `/manga/:muId`)
- Layouts responsive (LayoutBuilder breakpoints)
- PWA installable (service worker activé)
- Background fetch via service worker pour les nouveaux chapitres

---

## Debug

### Logs container
```bash
ssh nas
midclt call app.query | jq '.[] | select(.name=="manga-tracker-web")'
docker logs manga-tracker-web-manga-tracker-web-1
```

### Tester nginx en local
```bash
cd manga_tracker
docker build -f deploy/web/Dockerfile -t manga-tracker-web:local .
docker run -p 8080:80 manga-tracker-web:local
# → http://localhost:8080
```

### Build size
Le build web Flutter pèse ~27 MB total (4.3 MB pour `main.dart.js` brut, ~1 MB après gzip Nginx).

---

## Sécurité

- ✅ HTTPS obligatoire (NPMplus + Let's Encrypt)
- ✅ WAF Crowdsec actif
- ✅ Headers : X-Content-Type-Options, X-Frame-Options, Referrer-Policy, Permissions-Policy
- ✅ CSP strict mais compatible avec CanvasKit (`wasm-unsafe-eval`) + Google OAuth
- ✅ Pas de secrets dans le bundle (l'`.env.production` ne contient que `MT_API_URL`)
- ✅ JWT stocké via WebCrypto (`flutter_secure_storage` web → IndexedDB chiffré)
