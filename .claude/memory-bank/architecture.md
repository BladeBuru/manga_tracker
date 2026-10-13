# Architecture — Manga Tracker Flutter

## Stack technique

| Technologie | Version | Usage |
|------------|---------|-------|
| Flutter | 3.x | Framework UI (Mobile actuel + iOS/Web prévus) |
| Dart | 3.7.2+ | Langage (null safety obligatoire) |
| flutter_bloc | ^8.1.3 | State management — BLoC pattern |
| get_it | ^8.0.3 | Injection de dépendances (Service Locator) |
| http | ^1.3.0 | Client HTTP (via HttpService) |
| flutter_secure_storage | ^9.2.4 | Tokens JWT |
| shared_preferences | ^2.2.3 | Cache offline + préférences |
| cached_network_image | ^3.3.1 | Images réseau avec cache |
| connectivity_plus | ^5.0.2 | Détection connectivité |
| local_auth | ^2.1.6 | Biométrie (Face ID / empreinte) |
| flutter_inappwebview | ^6.0.0 | WebView avancée |
| google_fonts | ^6.1.1 | Polices |
| flutter_localizations + intl | SDK + ^0.20.2 | i18n — 7 langues (ARB) |

| go_router | ^14.6.2 (14.8.1) | Navigation — URL réelles web, onglets `StatefulShellRoute`, garde d'auth |

À faire (évolution) :
- Abstraction de `workmanager` (Android-only)
- Création de `app_spacing.dart` (token manquant)

---

## Structure du projet

```
lib/
├── core/                          # Code partagé
│   ├── bloc/                      # ConnectivityBloc (singleton)
│   ├── components/                # Widgets réutilisables (8 composants)
│   ├── network/                   # HttpService (JWT auto-refresh)
│   ├── notifier/                  # Toasts
│   ├── service_locator/           # GetIt
│   ├── services/                  # Services partagés (cache, sync, app update...)
│   ├── storage/                   # StorageService (flutter_secure_storage)
│   └── theme/                     # AppColors, AppRadius, AppTextStyle, AppTheme
│
├── features/
│   ├── auth/                      # Login, register, biométrie
│   ├── home/                      # Tendances, nouveautés, populaires
│   ├── library/                   # Bibliothèque utilisateur
│   ├── manga/                     # Détails manga + lecture
│   ├── profile/                   # Profil utilisateur
│   ├── reader/                    # Services WebView
│   ├── search/                    # Recherche
│   └── download/                  # Téléchargements offline (utilise dart:io — à abstraire)
│
├── l10n/                          # ARB : 7 langues
└── main.dart
```

---

## Pattern BLoC (OBLIGATOIRE)

```
UI (View) → Event → BLoC → State → UI (View)
```

| BLoC | Enregistrement GetIt | Rôle |
|------|---------------------|------|
| `HomePageBloc` | Lazy singleton | Tendances / nouveautés / populaires |
| `LibraryBloc` | Lazy singleton | Bibliothèque utilisateur |
| `DetailBloc` | **FACTORY** ⚠️ | Détails manga — une instance par page |
| `ConnectivityBloc` | Singleton | État connexion réseau |

**`DetailBloc` en factory = NON-NÉGOCIABLE** (évite les race conditions entre pages).

---

## Services clés

| Service | GetIt | Rôle |
|---------|-------|------|
| `StorageService` | Async singleton | flutter_secure_storage wrapper |
| `AuthService` | Singleton | Login / register / refresh JWT |
| `HttpService` | Singleton | HTTP avec JWT auto-refresh |
| `MangaService` | Singleton | Récupération mangas |
| `LibraryService` | Async singleton | Bibliothèque CRUD |
| `UserService` | Singleton | Profil (avec cache 7 jours) |
| `OfflineCacheService` | Singleton | Cache JSON des données |
| `CacheHelperService` | Singleton | Fallback API → cache |
| `SyncService` | Singleton | Synchronisation offline |
| `LanguageService` | Singleton | Langue + persistance |
| `NotificationService` | Singleton | Notifs locales (Android-only actuellement) |
| `AuthSession` | Singleton (restaurée avant `runApp`) | Statut de session vu par le garde du routeur (`signedOut` / `authenticated` / `rejected`) |
| `WebVersionWatcher` | — (classe, web) | Compare la version compilée à `/version.json` → bandeau « Recharger » |
| `OfflineCachePurgeService` | — (fonction utilitaire) | `purgeUserScopedCache()` — efface le cache de l'utilisateur courant (appelé par `logout()` et changement de compte uniquement) |
| `RecommendationDismissalService` | Lazy singleton (sans `dependsOn`) | Rejet et annulation de rejet de recommandations |
| `ReadingPositionService` | Lazy singleton (sans `dependsOn`) | Synchronisation serveur de la position de lecture — throttle 10 s/manga, `flush()` à la sortie, jamais bloquant |
| `ReadingResumeService` | Lazy singleton (sans `dependsOn`) | Collecte position locale + serveur, applique `ReadingResumePolicy` |
| `ScrollPositionService` | Singleton | Sauvegarde / restauration de la position dans les WebViews |
| `ReadingPositionStore` | — (classe instanciée) | Persistance locale des positions (`SharedPreferences`), purgée par `purgeUserScopedCache()` |
| `ReaderViewportProbe` | — (classe instanciée) | Seul point de contact JavaScript pour mesurer une page de lecture |

**Classes pures du lecteur** (ni Flutter, ni GetIt, ni réseau — la vue exécute,
elle ne décide pas) : `ChapterCommitPolicy` (quel chapitre est lu),
`ReaderNavigationPolicy` (anti-redirection), `ReadingResumePolicy` (quel
chapitre ouvrir et à quelle position), `ReadingPositionCalculator`
(pixels ⇄ pourcentage), `WebViewResultParser` (retours `Map` **et** `String`).

---

## Mode offline-first

1. Appel API → succès → mise en cache → état `isOffline: false`
2. Appel API → échec → `classifyFailure()` → cache → état `isOffline: true`
3. Actions offline → queue dans `OfflineCacheService`
4. Reconnexion → `SyncService` traite la queue automatiquement

**Règle** : Détecter l'offline via **`classifyFailure()`** (`lib/core/network/failure_classifier.dart`), PAS via `on SocketException` seul. Les 4 modes : `network` (réseau mort), `sessionExpired` (credentials absents localement), `sessionRejected` (401/403 serveur), `other`. Le cache est servi en lecture pour les 4 modes (décision produit 2026-08-31). Sur `sessionRejected` → `SessionRejectedBanner` non bloquant.

**Contrepartie purge** : `AuthService.logout()` appelle `purgeUserScopedCache()`. `clearSessionTokens()` (invalidation automatique) **ne purge pas** — sinon l'utilisateur perdrait ses données en cache malgré une authentification précédente valide.

---

## Navigation

```
main.dart (usePathUrlStrategy + AuthSession.restore avant runApp)
└── MaterialApp.router (go_router — core/router/app_router.dart)
    ├── /                StartupPage (restauration, biométrie, « Quoi de neuf ? »)
    ├── /login /register /forgot-password /auth/*   (publiques)
    ├── StatefulShellRoute — BottomNavbar + MainTabsPager (PageView)
    │   ├── /home      HomePageBlocView   (+ /home/section/:id plein écran)
    │   ├── /library   LibraryBlocView
    │   ├── /search    Search
    │   └── /profile   Profile            (+ /profile/edit plein écran)
    └── pages plein écran : /manga/:muId (+ /read, /read-offline), /authors/:id,
        /friends(/:userId), /stats, /inbox, /reading-groups(/:id), /downloads…
```

- **Garde** : `resolveAuthRedirect` (pure) + `AuthSession.routerRefresh`.
  Aucune session → `/login?from=…` ; connecté sur `/login` / `/register` /
  `/` (démarrage fini) → `from` validé ou `/home` ; session **rejetée** →
  jamais de redirection (offline-first).
- **Web** : chaque écran a son URL (pages empilées comprises,
  `optionURLReflectsImperativeAPIs`) ; `HistoryAwareRouteInformationProvider`
  tient l'historique du navigateur cohérent (retour dans l'app = vrai
  `history.go(-n)`, restauration redirigée = remplacement, `await push(...)`
  terminés au retour du navigateur) ; `RouteExtrasCodec` garde les extras.
- **Helpers** : `popOrGo` / `AppBackButton` (page ouverte par lien direct),
  `goToLogin` (invitation à se reconnecter, jamais `push('/login')`),
  `AuthNavigation` (transitions d'auth en remplacement d'historique).
- `DetailBloc` reste créé par page (`BlocProvider(create: getIt<DetailBloc>())`).

---

## Internationalisation

7 langues : FR (référence), EN, DE, JA, KO, PT, ES.
Fichiers ARB dans `lib/l10n/`. `LanguageService` pour la persistance et le changement dynamique.
**Zéro texte hardcodé** — tout via `context.l10n.maCle`.

---

## Cibles plateformes (évolution)

| Plateforme | État | Notes |
|------------|------|-------|
| Android | ✅ Actif | CI/CD release_workflow.yml en place |
| iOS | 🔴 Scaffoldé non wiré | Voir `.claude/skills/ios-readiness/SKILL.md` |
| Web | ✅ Déployé (`app.bladeburu.com`) | URL réelles, garde d'auth, sans service worker — `deploy/web/README.md` |

Tout nouveau code doit être platform-agnostic par défaut. Voir `.claude/docs/cross-platform.md` pour les patterns d'abstraction.
