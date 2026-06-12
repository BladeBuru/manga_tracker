# Spec Technique — reader

| Champ         | Valeur              |
|---------------|---------------------|
| Module        | reader              |
| Version       | 0.1.0               |
| Date          | 2026-06-04          |
| Source        | Rétro-ingénierie    |

---

## Architecture du module

Le module `reader` est réparti entre deux emplacements dans `lib/features/` :
- `lib/features/manga/views/` — façade `web_view.dart` (lecteur en ligne) et ses implémentations
- `lib/features/reader/` — services, utils et vue hors-ligne

L'architecture repose sur le pattern **platform-split via conditional exports** (voir RETRO-017) : chaque point d'entrée public (`web_view.dart`, `offline_reader_view.dart`) est une façade qui réexporte soit l'implémentation IO (mobile), soit un stub web.

La WebView en ligne (`web_view_io.dart`) est un `StatefulWidget` de ~1173 lignes qui orchestre directement tous les services reader (ad-blocker, captcha, scroll, navigation). Il n'y a pas de BLoC dédié pour le reader — la logique est portée par l'état du widget.

### Flux de lecture en ligne (mobile)

```
go_router /manga/:muId/read
  → ReaderWebView (web_view.dart façade)
    → _ReaderWebViewState (web_view_io.dart)
        ├── ChapterLinkResolver.init(CustomSelectorsService)
        ├── _loadAdBlockerPreference() → SharedPreferences
        ├── _loadBlockers() → AdBlockerService.getBlockers()
        ├── _checkAndRedirectToOffline() → DownloadManagerService
        └── InAppWebView
              ├── shouldOverrideUrlLoading → AdBlockerService.shouldBlockRequest / isAllowedDomain
              │                             → _handleDetected → WebViewNavigationService.detectChapterChange
              │                             → ScrollPositionService.startSaveTimer
              │                             → _commitIfNeeded → LibraryService.saveChapterProgress
              ├── onLoadStart → CaptchaDetectionService.urlContainsCaptcha / isCaptchaDomain
              ├── onUpdateVisitedHistory → _handleDetected
              ├── onLoadStop → _detectAndHandleCaptcha
              │             → AdBlockerService.buildAdBlockScript (JS injection)
              │             → ScrollPositionService.restoreScrollPosition
              │             → _downloadCurrentPage (si autoDownload)
              ├── androidShouldInterceptRequest → AdBlockerService.shouldBlockRequest (Android)
              └── onWillPop → ReadingProgressHelper.isNearEndOfChapter
                           → LibraryService.saveChapterProgress (si near end + confirmation)
```

### Flux de lecture hors-ligne (mobile)

```
go_router /manga/:muId/read-offline?chapter=N
  → OfflineReaderView (offline_reader_view.dart façade)
    → _OfflineReaderViewState (offline_reader_view_io.dart)
        ├── DownloadManagerService.getDownloadedChapters()
        ├── _cleanHtmlForOffline() → suppression link/script/iframe externes
        └── InAppWebView (baseUrl = file://)
              ├── shouldOverrideUrlLoading → ALLOW file://, CANCEL http(s)://
              ├── androidShouldInterceptRequest → ALLOW file://, BLOCK tout le reste
              ├── onLoadStop → ReadingProgressHelper.restoreScrollPosition
              │             → Timer(2s) → _saveScrollPosition
              └── onPopInvoked → ReadingProgressHelper.isNearEndOfChapter
                              → LibraryService.saveChapterProgress (si near end)
```

---

## Fichiers impactés

| Fichier | Rôle | Lignes |
|---------|------|--------|
| `lib/features/manga/views/web_view.dart` | Façade conditional export (mobile/web) | ~11 |
| `lib/features/manga/views/web_view_io.dart` | Impl mobile — WebView en ligne avec ad-blocker, captcha, scroll, navigation | ~1173 |
| `lib/features/manga/views/web_view_web.dart` | Stub web — bouton `url_launcher` | ~64 |
| `lib/features/reader/views/offline_reader_view.dart` | Façade conditional export | ~9 |
| `lib/features/reader/views/offline_reader_view_io.dart` | Impl mobile — lecteur hors-ligne HTML | ~469 |
| `lib/features/reader/views/offline_reader_view_web.dart` | Stub web — "non disponible" | ~44 |
| `lib/features/reader/services/ad_blocker_service.dart` | Gestion ContentBlockers, JS injection, mode interactif | ~834 |
| `lib/features/reader/services/captcha_detection_service.dart` | Détection Cloudflare/reCAPTCHA/hCaptcha + cookie clearance | ~103 |
| `lib/features/reader/services/scroll_position_service.dart` | Sauvegarde/restauration scroll (SharedPreferences, timer 5s) | ~418 |
| `lib/features/reader/services/webview_navigation_service.dart` | Classification des changements de chapitre (enum ChapterChangeType) | ~97 |
| `lib/features/reader/utils/chapter_link_resolver.dart` | Extraction numéro chapitre depuis URL, construction URL suivante | ~251 |
| `lib/features/reader/utils/reading_progress_helper.dart` | Calcul position relative (near end ≤15%), get/restore scroll | ~115 |

---

## Schéma BDD (si applicable)

Pas de base de données relationnelle. Données persistées :

| Stockage | Clé | Type | Contenu |
|----------|-----|------|---------|
| `SharedPreferences` | `ad_blocker_enabled` | `bool` | Préférence d'activation du bloqueur de pub |
| `SharedPreferences` | `scroll_position_{muId}_{chapter}` | `double` | Position verticale de scroll en pixels |
| `SharedPreferences` | `cookies_{domain}` | `String` | Cookies HTTP du domaine (pour téléchargements) |
| `CustomSelectorsService` | (fichier JSON interne) | `List<CustomSelector>` | Sélecteurs CSS personnalisés par domaine (`adBlocker` ou `urlPattern`) |

---

## API / Endpoints consommés

| Service | Méthode | Endpoint | Description |
|---------|---------|----------|-------------|
| `LibraryService` | `saveChapterProgress(muId, chapter)` | `PUT /api/library/{muId}/progress` (déduit) | Enregistre le dernier chapitre lu |
| `LibraryService` | `updateCustomLink(muId, url)` | `PUT /api/library/{muId}/custom-link` (déduit) | Met à jour le lien personnalisé |

Le reader ne consomme pas directement l'API REST — il délègue à `LibraryService`.

---

## Patterns identifiés

### Platform-split via conditional exports (RETRO-017)
```dart
// web_view.dart
export 'web_view_io.dart'
    if (dart.library.html) 'web_view_web.dart';
```
Toute la logique mobile (`flutter_inappwebview`, `dart:io`) est dans les fichiers `_io.dart`. Les stubs web n'importent rien de platform-specific.

### Stateful widget sans BLoC
Le reader n'utilise pas de BLoC. L'état est entièrement géré dans `_ReaderWebViewState` et `_OfflineReaderViewState`. Choix justifié par la nature de la WebView (state local fort, cycle de vie lié au widget).

### Threshold "near end" pour la progression
La règle `percentageFromEnd <= 15` est implémentée dans `ReadingProgressHelper.isNearEndOfChapter` et appliquée depuis deux points distincts : `web_view_io.dart` (`_onWillPop`) et `offline_reader_view_io.dart` (`dispose` + `onPopInvoked`).

### ContentBlocker + JavaScript injection (deux couches de blocage)
Le bloqueur de pub opère en deux couches indépendantes :
1. `ContentBlocker` (niveau réseau WebKit) — bloque les requêtes vers les domaines de la `denyHosts` liste avant qu'elles n'atteignent le réseau.
2. Script JavaScript (niveau DOM) — supprime les éléments publicitaires via CSS selectors et un `MutationObserver` qui relance le nettoyage à chaque mutation du DOM + un `setInterval(removeAds, 2000)`.

Sur Android, un troisième niveau via `androidShouldInterceptRequest` retourne une réponse HTTP 403 pour les requêtes vers les domaines de la liste.

### Captcha-aware ad-blocker
Quand un captcha est détecté (dans l'URL via `urlContainsCaptcha`, au niveau du domaine via `isCaptchaDomain`, ou dans le DOM via injection JS), le bloqueur est mis en pause (`_adBlockerEnabled = false`, `_captchaDetected = true`). L'état précédent est mémorisé dans `_adBlockerWasEnabled` pour permettre la réactivation après résolution. La résolution est détectée par la présence du cookie `cf_clearance`.

### Sélecteurs personnalisés extensibles
`AdBlockerService` et `ChapterLinkResolver` consultent `CustomSelectorsService` pour charger des règles spécifiques au domaine. Type `adBlocker` = sélecteur CSS à masquer. Type `urlPattern` = regex pour extraire le numéro de chapitre depuis l'URL. Cela permet à l'utilisateur d'étendre les règles via l'UI "Custom Selectors" sans mise à jour de l'application.

### Isolation réseau complète du lecteur hors-ligne
Le `OfflineReaderView` bloque toutes les requêtes HTTP/HTTPS via `shouldOverrideUrlLoading` (retourne `CANCEL` pour tout sauf `file://`) et `androidShouldInterceptRequest` (retourne 403 pour tout sauf `file://`). Le HTML est préalablement nettoyé de toutes les balises pointant vers des ressources externes (`_cleanHtmlForOffline`).

### Sauvegarde de cookies pour les téléchargements
Après chaque chargement de page, les cookies du domaine sont extraits via `CookieManager.instance().getCookies()` et persistés dans `SharedPreferences` sous `cookies_{domain}`. L'objectif documenté est de faciliter les téléchargements automatiques post-captcha (le cookie `cf_clearance` présent indique que le captcha a été résolu).

---

## Décisions documentées en spec-technique (candidats ADR rejetés)

### Bloqueur de pub embarqué dans le lecteur
L'application intègre un bloqueur de publicités directement dans la WebView. La `denyHosts` liste statique contient ~40 domaines publicitaires connus. Les sélecteurs CSS couvrent ~100 patterns. Un mode interactif permet d'ajouter des sélecteurs personnalisés persistés. Cette décision est confine au module reader (Q3=NON → rejeté comme ADR). Les sélecteurs personnalisés créés via le mode interactif sont stockés dans `CustomSelectorsService` avec un ID de la forme `interactive_{domain}_{timestamp}`.

### Détection CAPTCHA — stratégies en cascade
La détection opère selon l'ordre : (1) URL de la requête (patterns `challenge`, `cf_challenge`, `challenges.cloudflare.com`), (2) domaine hôte (liste `isCaptchaDomain`), (3) inspection DOM (iframes Cloudflare, éléments `[id*=cf-]`, éléments `[id*=recaptcha]`, iframes hCaptcha). La résolution est détectée par cookie `cf_clearance` ou `clearance`. Confiné au module reader (Q3=NON).

### Extraction du numéro de chapitre depuis l'URL — resolver multi-stratégies
`ChapterLinkResolver.extractChapter()` applique dans l'ordre : (0) patterns regex personnalisés par domaine (depuis `CustomSelectorsService`), (1) paramètres de requête (`chapter`, `chapitre`, `ch`, `ep`, `episode`, `episode_no`, `num`, `no`), (2) 6 patterns regex dans le chemin de l'URL (formats `/chapter-N/`, `/cN/`, `/chN/`, `/ep-N/`, `/manga/N/`, `slug-chapitre-N/`). Une version synchrone (`extractChapterSync`) existe pour la compatibilité mais n'utilise que les patterns par défaut (pas de customSelectors). Confiné au module reader (AP-3 + Q3=NON).

### Scroll : seuil de non-sauvegarde à 95%
`ScrollPositionService.saveScrollPosition` ne sauvegarde pas la position si `(scrollPosition / (documentHeight - windowHeight)) * 100 > 95`. Ce seuil est symétrique du seuil "near end" de 15% dans `ReadingProgressHelper` : un utilisateur proche du bas a de grandes chances d'être à la fin du chapitre, et sa position ne doit pas être restaurée au prochain chargement. Décision de granularité fine, confinée à un seul service (Q1=NON → rejeté).

### Lecteur hors-ligne : fallback `PageView.builder` pour les chapitres sans HTML
Si un chapitre téléchargé ne possède pas de `htmlPath` mais a des `imagePaths`, `OfflineReaderView` affiche les images dans un `PageView.builder` (swipe horizontal). Ce mode ne sauvegarde ni la progression ni la position de scroll. Il semble être un vestige d'un format de téléchargement antérieur.

---

## Tests existants

| Fichier | Ce qu'il teste | Statut |
|---------|---------------|--------|
| — | Aucun test pour le module reader | Absent |

Le module reader n'a aucun test unitaire ou widget test. Les services (`AdBlockerService`, `CaptchaDetectionService`, `ScrollPositionService`, `WebViewNavigationService`) et les utils (`ChapterLinkResolver`, `ReadingProgressHelper`) sont testables en isolation mais non couverts.
