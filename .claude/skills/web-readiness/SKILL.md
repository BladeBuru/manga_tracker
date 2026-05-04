---
name: web-readiness
description: Préparer Manga Tracker Flutter pour le build Web — retirer dart:io, migrer vers go_router (deep-linking), layouts responsive (LayoutBuilder), PWA (web/manifest.json, service worker), configurer CORS côté API, tester flutter run -d chrome.
---

# Skill : Web readiness — Manga Tracker Flutter

Préparer l'app pour le build web Flutter (PWA + hébergement Firebase / Netlify / Cloudflare Pages).

---

## 1. Bloquants connus dans le code

Avant tout, lancer la skill `/cross-platform-audit` pour repérer :
- `dart:io` direct (casse le build web)
- `Platform.is*` non abstrait
- `MaterialPageRoute` (à migrer en `go_router` pour le deep-linking)
- `workmanager` / `flutter_local_notifications` Android-only

---

## 2. Migration `go_router`

### Pourquoi
- Le web nécessite des **URLs réelles** (`/library/123` au lieu d'une stack opaque).
- Sans go_router, recharger une page profonde casse la nav.

### Plan
1. Ajouter `go_router: ^14.x` dans `pubspec.yaml`.
2. Créer `lib/core/router/app_router.dart` avec un `GoRouter` configuré.
3. Convertir `Navigator.push(MaterialPageRoute(...))` en `context.go('/route')` ou `context.push('/route')`.
4. Pour les pages de détail manga (DetailBloc factory) :
   ```dart
   GoRoute(
     path: '/manga/:muId',
     pageBuilder: (context, state) => MaterialPage(
       child: BlocProvider(
         create: (_) => getIt<DetailBloc>()..add(LoadDetail(muId: state.pathParameters['muId']!)),
         child: const LateDetailView(),
       ),
     ),
   ),
   ```
5. Documenter dans `.claude/memory-bank/decisions.md`.

---

## 3. Responsive layouts

```dart
// Breakpoints standard
const kMobileBreakpoint = 600.0;
const kTabletBreakpoint = 900.0;
const kDesktopBreakpoint = 1200.0;

LayoutBuilder(
  builder: (context, constraints) {
    if (constraints.maxWidth >= kDesktopBreakpoint) return _DesktopLayout();
    if (constraints.maxWidth >= kTabletBreakpoint) return _TabletLayout();
    return _MobileLayout();
  },
)
```

À auditer :
- Pages principales (Home, Library, Search, Profile)
- Pages de détail manga
- Auth (Login, Register)

---

## 4. PWA — `web/manifest.json`

```json
{
  "name": "Manga Tracker",
  "short_name": "MangaTracker",
  "start_url": "/",
  "display": "standalone",
  "background_color": "#FFFFFF",
  "theme_color": "#D32F2F",
  "description": "Track your manga reading progress",
  "orientation": "portrait-primary",
  "prefer_related_applications": false,
  "icons": [
    { "src": "icons/Icon-192.png", "sizes": "192x192", "type": "image/png" },
    { "src": "icons/Icon-512.png", "sizes": "512x512", "type": "image/png" },
    { "src": "icons/Icon-maskable-192.png", "sizes": "192x192", "type": "image/png", "purpose": "maskable" },
    { "src": "icons/Icon-maskable-512.png", "sizes": "512x512", "type": "image/png", "purpose": "maskable" }
  ]
}
```

Service worker généré par Flutter (`flutter_service_worker.js`) — vérifier qu'il est activé dans `web/index.html`.

---

## 5. `web/index.html`

- [ ] Meta viewport responsive : `<meta name="viewport" content="width=device-width, initial-scale=1.0, maximum-scale=1.0, user-scalable=no">`
- [ ] Lien vers `manifest.json`
- [ ] Theme color
- [ ] Open Graph tags pour le partage (optionnel)
- [ ] Favicon multi-formats

---

## 6. CORS côté API

L'API NestJS (projet `API-mangaTracker/`) doit accepter le domaine web prod dans `CORS_ORIGINS` :

```env
# .env.production (côté API)
CORS_ORIGINS=https://app.manga-tracker.com,https://manga-tracker.com
```

Coordonner avec le projet API : voir `.claude/rules/nest-main-security.md` du projet API.

---

## 7. Stockage offline

`flutter_secure_storage` fonctionne sur Web mais utilise WebCrypto / IndexedDB. Vérifier :

- [ ] Tokens JWT bien persistés sur Web
- [ ] `OfflineCacheService` (`shared_preferences`) marche sur Web (oui, via localStorage)
- [ ] Pas de `dart:io` dans le code de cache

---

## 8. Build & déploiement

```bash
# Build web release
flutter build web --release --base-href "/" --web-renderer canvaskit

# Tester localement
flutter run -d chrome --web-port 8080

# Déployer (exemple Firebase Hosting)
firebase deploy --only hosting
```

À ajouter au CI : un workflow `.github/workflows/web_release.yml` qui build + déploie sur push à `main`.

---

## 9. Plan d'action complet

L'agent doit produire :

```markdown
## Web readiness — Manga Tracker Flutter

### 🔴 Bloquants build web
- [ ] [Item] — [fichier:ligne] — fix : [action]

### 🟠 À implémenter avant beta
- [ ] go_router migration
- [ ] Responsive layouts
- [ ] PWA manifest
- [ ] Service worker
- [ ] CORS API mis à jour

### 🟡 Améliorations
- [ ] [Item]

### ✅ Déjà OK
- [ ] [Item]

### Plan d'exécution
1. Phase 1 : fix bloquants (dart:io, Platform.is*)
2. Phase 2 : go_router
3. Phase 3 : responsive
4. Phase 4 : PWA + déploiement
```

---

## Liens

- `.claude/skills/cross-platform-audit/SKILL.md` — audit préalable
- `.claude/docs/cross-platform.md` — patterns d'abstraction
- `.claude/docs/deployment.md` — config CI/CD
