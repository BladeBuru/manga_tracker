# Spec Technique — reader

| Champ         | Valeur              |
|---------------|---------------------|
| Module        | reader              |
| Version       | 0.4.0               |
| Date          | 2026-09-05          |
| Source        | Rétro-ingénierie + Sprint responsive/social/stats-v2 + Chantier correctifs-août |

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

**Ajouts sprint responsive/social/stats-v2 :**

| Fichier | Modification |
|---------|-------------|
| `lib/features/manga/views/web_view_io.dart` | NEW — Appel `recordChapterLog(muId, chapter)` fire-and-forget à chaque changement de chapitre détecté (branché sur `_handleDetected`) |
| `lib/features/reader/views/offline_reader_view_io.dart` | NEW — Appel `recordChapterLog(muId, chapter)` fire-and-forget au chargement d'un chapitre hors-ligne |

**Ajouts chantier correctifs-août (fix/reader-cloudflare) :**

| Fichier | Rôle | Lignes (approx.) |
|---------|------|-----------------|
| `lib/features/reader/services/challenge_allowlist.dart` | Liste blanche stricte des domaines de vérification anti-robot (Cloudflare, hCaptcha, reCAPTCHA, `/cdn-cgi/`). Correspondance par suffixe de domaine. | ~85 |
| `lib/features/reader/services/challenge_loop_detector.dart` | Détecteur de boucle de défi : déclenche `ChallengeEscapeDialog` après 3 présentations du même défi en < 90 s. Réinitialise sur changement de défi ou résolution. | ~68 |
| `lib/features/reader/services/web_view_user_agent.dart` | Construit l'UA honnête : retire `; wv`, `Version/4.0` et `Build/…`, conserve les vraies versions Chrome et Android. | ~42 |
| `lib/features/reader/services/reader_web_view_settings.dart` | Centralise les `InAppWebViewSettings` du lecteur. Persistance cookie, DOM/DB/third-party activés explicitement, `sharedCookiesEnabled: true` sur iOS. | ~55 |
| `lib/features/reader/widgets/challenge_escape_dialog.dart` | Dialog i18n ×7 langues proposant « Ouvrir dans le navigateur / Réessayer / Fermer » après détection de boucle. | ~110 |
| `lib/features/reader/widgets/reader_action_bar.dart` | Barre d'actions du lecteur à deux niveaux : actions rapides (Rafraîchir, Bloqueur de pub) + menu trois points (Télécharger la page, Copier URL, Mode interactif, Aide). | ~195 |

**Modifications chantier correctifs-août sur fichiers existants :**

| Fichier | Modification |
|---------|-------------|
| `lib/features/reader/services/ad_blocker_service.dart` | Script JS : nettoyage suspendu pendant un défi actif, éléments `[data-cfasync]`/`iframe[sandbox]` épargnés, `'ad'` reconnu en tant que **mot entier** (`\bad\b`) et non sous-chaîne. Script rendu arrêtable via `window.__mtAdBlock.stop()` et idempotent (ne s'empile plus à chaque rechargement). |
| `lib/features/manga/views/web_view_io.dart` | Amorçage du user-agent via `WebViewUserAgent.apply(controller)` avant le premier chargement. URL initiale chargée **après** application du UA. Barre d'actions remplacée par `ReaderActionBar`. Branchement `ChallengeLoopDetector` + `ChallengeEscapeDialog`. |

**Suppressions fix/reader-redirect-regression :**

| Fichier | Raison |
|---------|--------|
| `lib/features/reader/services/web_view_user_agent.dart` | Supprimé — le UA modifié (sans `; wv`) supprimait les indices `Sec-CH-UA` cohérents avec la vraie version Chrome, détectés par les vérifications anti-robot comme une incohérence. Retour au UA de la plateforme (décision documentée dans `.claude/memory-bank/decisions.md`). |
| `test/features/reader/web_view_user_agent_test.dart` | Supprimé avec la classe testée. |

**Ajouts fix/reader-redirect-regression :**

| Fichier | Rôle | Lignes (approx.) |
|---------|------|-----------------|
| `lib/features/reader/services/reader_navigation_policy.dart` | Politique de navigation pure (`ReaderNavigationPolicy`) : décide si une URL doit être ouverte dans la WebView ou annulée. Même domaine de base → OK, vérification anti-robot → OK, pub/autre domaine → CANCEL. Testée avec `AdBlockerService` réel. | ~63 |

**Modifications fix/reader-redirect-regression sur fichiers existants :**

| Fichier | Modification |
|---------|-------------|
| `lib/features/reader/services/reader_web_view_settings.dart` | Retour à `initialUrlRequest` + `initialSettings` posés une seule fois. `useShouldOverrideUrlLoading: true` explicite, `supportMultipleWindows: false`, `javaScriptCanOpenWindowsAutomatically: false`, `requestedWithHeaderOriginAllowList: {}`. Suppression de l'appel `WebViewUserAgent`. |
| `lib/features/manga/views/web_view_io.dart` | Suppression du `controller.setSettings(...)` post-chargement (racine de la régression v0.13.0 : sur Android, cet appel remplace l'objet de réglages ENTIER par un neuf, réinitialisant `useShouldOverrideUrlLoading` à `false`). Retour à `initialSettings`. |
| `lib/features/reader/widgets/reader_action_bar.dart` | Interrupteur `Switch` du bloqueur de pub rétabli (actif par défaut, désactivé pendant un défi, rétabli après) avec un seul nœud sémantique. |

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

### Captcha-aware ad-blocker (révisé chantier correctifs-août)
Quand un défi anti-robot est détecté, le bloqueur est mis en pause (`_adBlockerEnabled = false`, `_captchaDetected = true`) **et** le script JS est explicitement arrêté via `window.__mtAdBlock.stop()`. Sans cet arrêt, le `setInterval` interne continuait à s'exécuter même après désactivation côté Flutter. Le script est désormais idempotent (une seule instance active) et ne s'empile plus à chaque `onLoadStop`.

Le nettoyage DOM épargnait déjà les iframes, mais la correspondance `el.className.includes('ad')` et `el.id.includes('ad')` — par sous-chaîne — supprimait des éléments légitimes. Elle est remplacée par une correspondance en **mot entier** (`\bad\b`). Les attributs `[data-cfasync]` et `iframe[sandbox]` sont explicitement protégés.

### Liste blanche des vérifications anti-robot (ChallengeAllowlist)
`ChallengeAllowlist` centralise une liste stricte de domaines et préfixes de chemin correspondant aux vérifications légitimes : domaines Cloudflare (`challenges.cloudflare.com`, `cloudflare.com`), hCaptcha (`hcaptcha.com`), reCAPTCHA (`google.com/recaptcha`), et endpoints `/cdn-cgi/` servis par le site lui-même. La correspondance se fait par **suffixe** de domaine (pas par `contains`) : un hôte imitant `challenges.cloudflare.com` dans un sous-domaine tiers n'est pas autorisé. Branché sur `shouldBlockRequest` et `isAllowedDomain`.

### Détecteur de boucle de défi (ChallengeLoopDetector)
`ChallengeLoopDetector` compte les présentations du même défi Cloudflare (même URL de défi ou même empreinte DOM). Après 3 présentations en moins de 90 secondes, il notifie `web_view_io.dart` qui affiche `ChallengeEscapeDialog` — proposant d'ouvrir dans le navigateur système, de réessayer, ou de fermer. Un rechargement demandé explicitement par l'utilisateur (bouton Rafraîchir) ne compte pas comme une présentation de boucle. Le compteur se réinitialise sur changement de défi ou sur résolution (cookie `cf_clearance` présent).

### UA de la plateforme (suppression de WebViewUserAgent — fix/reader-redirect-regression)
`WebViewUserAgent` a été supprimé lors du fix de la régression v0.13.0. La modification du UA (retrait de `; wv`) créait une incohérence avec les indices `Sec-CH-UA` envoyés par le moteur Chromium, détectée par les vérifications anti-robot comme un client suspect. La WebView utilise désormais le UA natif de la plateforme, sans modification. Cette décision est documentée dans `.claude/memory-bank/decisions.md`.

### Protection anti-redirection — ReaderNavigationPolicy (fix/reader-redirect-regression)
`ReaderNavigationPolicy` est une classe pure extraite de la logique inline de `web_view_io.dart`. Elle centralise la règle de navigation : même domaine de base → `ALLOW`, domaine de vérification anti-robot (via `ChallengeAllowlist`) → `ALLOW`, toute autre URL → `CANCEL`. Elle remplace le mixin de garde ad-hoc précédent et est couverte par des tests unitaires avec un `AdBlockerService` réel.

La racine de la régression v0.13.0 était un appel `controller.setSettings(...)` effectué après le chargement initial pour appliquer le user-agent. Sur Android, cet appel remplace l'objet de réglages entier par un nouveau : `useShouldOverrideUrlLoading` repassait à `false`, rendant le garde `shouldOverrideUrlLoading` (et donc `ReaderNavigationPolicy`) inopérant. Le correctif revient à `initialUrlRequest` + `initialSettings` posés une seule fois, avec `useShouldOverrideUrlLoading: true` explicite.

### Barre d'actions à deux niveaux (ReaderActionBar)
`ReaderActionBar` remplace l'ancienne barre à 6 commandes à plat. Actions rapides (toujours visibles) : Rafraîchir + Bloqueur de pub (interrupteur `Switch` rétabli dans fix/reader-redirect-regression — actif par défaut, désactivé pendant un défi, rétabli après, avec un seul nœud sémantique). Actions secondaires (menu trois points) : Télécharger la page, Copier l'URL, Mode de désignation des publicités, Aide. Le bouton Bloqueur agit **immédiatement** sur la page active (activation) ou recharge avec préservation de position (désactivation — nécessaire pour faire réapparaître les éléments déjà retirés). Textes i18n ×7 langues.

### Sélecteurs personnalisés extensibles
`AdBlockerService` et `ChapterLinkResolver` consultent `CustomSelectorsService` pour charger des règles spécifiques au domaine. Type `adBlocker` = sélecteur CSS à masquer. Type `urlPattern` = regex pour extraire le numéro de chapitre depuis l'URL. Cela permet à l'utilisateur d'étendre les règles via l'UI "Custom Selectors" sans mise à jour de l'application.

### Journal de lecture — `recordChapterLog` fire-and-forget (RETRO-015)

À chaque chapitre détecté (en ligne via `_handleDetected` dans `web_view_io.dart`, hors-ligne au chargement dans `offline_reader_view_io.dart`), un appel `recordChapterLog(muId, chapter)` est effectué en fire-and-forget (pas d'`await`, pas de gestion d'erreur). Ce mécanisme alimente le journal de lecture côté API, utilisé par les stats v2 (`chaptersPerWeek`, `readingHistory` dans `UserStatsDto`). L'échec silencieux est intentionnel — le journal est best-effort et ne doit pas bloquer la lecture.

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
| `test/features/reader/challenge_allowlist_test.dart` | Liste blanche : domaines autorisés, correspondance suffixe (pas sous-chaîne), rejet d'un hôte imitateur | Ajouté chantier correctifs-août |
| `test/features/reader/challenge_loop_detector_test.dart` | Comptage des défis, déclenchement après 3 occurrences en < 90 s, réinitialisation sur changement de défi, exemption du bouton Rafraîchir | Ajouté chantier correctifs-août |
| `test/features/reader/web_view_user_agent_test.dart` | Retrait des jetons `; wv` / `Version/4.0` / `Build/…`, conservation des vraies versions Chrome et Android | Ajouté chantier correctifs-août |
| `test/features/reader/ad_blocker_challenge_test.dart` | Absence des sélecteurs fautifs (`iframe[sandbox]`, `[data-cfasync]`, correspondance sous-chaîne `'ad'`) dans le script produit par `buildAdBlockScript`, arrêtabilité du script | Ajouté chantier correctifs-août |
| `test/features/reader/reader_navigation_policy_test.dart` | `ReaderNavigationPolicy` : même domaine autorisé, pub annulée, autre domaine annulé, vérification anti-robot autorisée | Ajouté fix/reader-redirect-regression |
| `test/features/reader/reader_web_view_settings_test.dart` | `ReaderWebViewSettings` : `useShouldOverrideUrlLoading: true`, absence de `setSettings(` après init, `initialUrlRequest` présent | Ajouté fix/reader-redirect-regression |
| `test/features/reader/reader_invariants_test.dart` | Fil de détente sur le source de `web_view_io.dart` : callback `shouldOverrideUrlLoading` branché, absence de `controller.setSettings(`, `initialUrlRequest` utilisé | Ajouté fix/reader-redirect-regression |

**Supprimés fix/reader-redirect-regression :**

| Fichier | Raison |
|---------|--------|
| `test/features/reader/web_view_user_agent_test.dart` | Supprimé avec `WebViewUserAgent`. |

**Note** : les services `AdBlockerService`, `CaptchaDetectionService`, `ScrollPositionService`, `WebViewNavigationService` et les utils `ChapterLinkResolver`, `ReadingProgressHelper` restent non couverts hors des cas ci-dessus. Le comportement effectif face à un vrai défi Cloudflare ne peut pas être prouvé en test unitaire (dépend de l'infrastructure distante). Total CI : 217 tests verts (flutter-ci.yml, analyse + tests sur chaque PR).
