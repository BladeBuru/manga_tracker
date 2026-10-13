# Déploiement Web — Manga Tracker

Pipeline complet : Flutter Web → Docker (Nginx) → TrueNAS NAS → `app.bladeburu.com`

---

## Architecture

```
   Browser
      ↓ HTTPS
   NPMplus (TrueNAS) ── reverse proxy + Crowdsec
      ↓ HTTP
   Container Docker `manga-tracker-web` (Nginx 1.27 alpine, port 8090:80)
      ↓ statique
   build/web/ (généré par Flutter Web --release)
```

L'app Flutter consomme l'API NestJS sur `https://api.bladeburu.com` (CORS déjà whitelisté côté API : `CORS_ORIGINS=https://api.bladeburu.com,https://app.bladeburu.com`).

---

## Prérequis (one-time setup)

### 1. Secret GitHub — `ENV_PRODUCTION` (déjà existant)

Le workflow réutilise le secret `ENV_PRODUCTION` déjà en place pour le release APK
(contient `MT_API_URL=https://api.bladeburu.com`). Aucune action.

### 2. Secrets à ajouter (mêmes valeurs que dans le repo API-mangaTracker)

GitHub isole les secrets par repo (pas de partage cross-repo). Il faut donc copier
les valeurs depuis le repo API :

| Secret | Source |
|---|---|
| `DOCKERHUB_USER` | repo API → Settings → Secrets → copier la valeur |
| `DOCKERHUB_TOKEN` | repo API |
| `NAS_HOST` | repo API |
| `NAS_PORT` | repo API |
| `NAS_USER` | repo API |
| `NAS_SSH_KEY` | repo API (clé privée multi-ligne) |

**Note** : on réutilise volontairement la même clé SSH déjà autorisée sur le NAS
plutôt que d'en créer une nouvelle (simplicité). Si tu veux une isolation forte
plus tard, génère une clé dédiée `web-deploy` et ajoute son `.pub` au NAS via
TrueNAS UI / `~/.ssh/authorized_keys`.

### 3. NPMplus — Proxy host pour `app.bladeburu.com`

Dans NPMplus (TrueNAS) :
- **Domain Names** : `app.bladeburu.com`
- **Forward Hostname** : `192.168.1.119` (ou `localhost` si NPMplus tourne sur le même host)
- **Forward Port** : `8090`
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

**Fait** :
- ✅ `go_router` + URL réelles (`usePathUrlStrategy`, plus de `/#/`) : chaque
  écran a son URL, y compris les onglets (`/home`, `/library`, `/search`,
  `/profile`) et les pages empilées ; F5, lien partagé et boutons du
  navigateur rouvrent l'écran affiché. nginx renvoie `index.html` pour toute
  URL de l'application (`try_files … /index.html`).
- ✅ Garde d'authentification : lien direct sans session → `/login?from=…`,
  retour à la page demandée après connexion ; l'historique ne garde ni `/`
  ni `/login` derrière l'application.

**À venir** :
- Layouts responsive restants (LayoutBuilder breakpoints)
- PWA installable — **sans** service worker de cache (voir ci-dessous)

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
docker run -p 8090:80 manga-tracker-web:local
# → http://localhost:8090
# Syntaxe seule : docker run --rm -v "$PWD/deploy/web/nginx.conf:/etc/nginx/conf.d/default.conf:ro" nginx:1.27-alpine nginx -t
```

### Build size
Le build web Flutter pèse ~27 MB total (4.3 MB pour `main.dart.js` brut, ~1 MB après gzip Nginx).

---

## Cache et service worker (depuis 2026-10)

Symptôme d'origine : sur un ordinateur, la page de connexion affichée était
celle d'une version vieille de plusieurs mois, jusqu'à l'effacement manuel
des données du site. Cause : le service worker « hors ligne d'abord » généré
par défaut par `flutter build web` servait l'application depuis son cache.

- **Build** : `--pwa-strategy=none` (Dockerfile + CI) et
  `web/flutter_bootstrap.js` qui démarre l'app **sans** inscrire de service
  worker.
- **Interrupteur d'arrêt** : `deploy/web/flutter_service_worker.js` est copié
  par-dessus le fichier vide généré. Un navigateur qui a encore l'ancien
  service worker le télécharge à sa vérification de mise à jour : il vide
  les caches, se désinscrit et recharge les onglets. `web/index.html`
  désinscrit aussi tout service worker existant avant de démarrer l'app
  (rechargement unique si la page venait de lui).
- **nginx** : aucun fichier d'un build Flutter web n'a de hash dans son nom
  → tout est revalidé (`no-cache`, réponses 304), le cœur (`index.html`,
  `main.dart.js`, `flutter_bootstrap.js`, `flutter_service_worker.js`,
  `version.json`) n'est jamais stocké (`no-store`) ; seuls les images et
  `canvaskit/` gardent un cache d'un jour, sans `immutable`. (Avant : 30 jours
  `immutable` sur tout `.js` non listé, polices et images — dont la police
  d'icônes, réduite à chaque build.)
- **Dans l'app** : `--dart-define=MT_WEB_BUILD=<version+build>` ;
  `WebVersionWatcher` compare cette version à `/version.json` au démarrage
  et au retour sur l'onglet → bandeau « Une nouvelle version est disponible
  — Recharger ».

> ⚠️ En-têtes de sécurité : dans nginx, un `add_header` dans un `location`
> remplace ceux du niveau `server`. Les en-têtes ci-dessous ne partent donc
> pas avec les réponses servies par ces `location` (constaté en prod :
> `nosniff` et `X-Frame-Options` sont ajoutés en amont, **aucune CSP**).
> Avant d'appliquer la CSP, l'élargir (`connect-src` doit autoriser
> `https://www.gstatic.com` pour CanvasKit et `https://fonts.gstatic.com`
> pour Google Fonts), sinon l'application ne s'affiche plus.

## Sécurité

- ✅ HTTPS obligatoire (NPMplus + Let's Encrypt)
- ✅ WAF Crowdsec actif
- ✅ Headers : X-Content-Type-Options, X-Frame-Options, Referrer-Policy, Permissions-Policy
- ⚠️ CSP écrite mais **non appliquée** (cf. « Cache et service worker ») — à élargir avant activation
- ✅ Pas de secrets dans le bundle (l'`.env.production` ne contient que `MT_API_URL`)
- ✅ JWT stocké via WebCrypto (`flutter_secure_storage` web → IndexedDB chiffré)
