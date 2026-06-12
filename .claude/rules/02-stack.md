# Stack technique du projet

> Fichier généré automatiquement par le subagent `stack-detector` lors de l'initialisation.
> Dernière détection : 2026-06-04

---

## Résumé

Application mobile Flutter (Android actif, iOS + Web en roadmap). Single repo, pas de monorepo. Le backend est **externe** (API REST distincte). L'app est purement cliente.

---

## Application Flutter

- **Framework :** Flutter 3.x (Material 3, `useMaterial3: true`)
- **Langage :** Dart 3.7+ (`environment.sdk: ^3.7.2`) — null safety obligatoire
- **Version applicative :** 0.10.0+21 (versionName / versionCode)
- **Plateformes cibles :**
  - Android (production actuelle)
  - iOS (roadmap)
  - Web (roadmap — build web déjà en CI)

### State management

- `flutter_bloc ^8.1.3` + `bloc ^8.1.2` — pattern BLoC strict (Event → BLoC → State)
- `equatable ^2.0.5` — comparaison d'états et d'events

### Injection de dépendances

- `get_it ^8.0.3` — Service Locator centralisé dans `lib/core/service_locator/service_locator.dart`
- Enregistrement : singletons, lazy singletons, singletons async, factories (DetailBloc en factory obligatoire)

### Navigation

- `go_router ^14.6.2` — migration depuis MaterialPageRoute complète
- Router centralisé dans `lib/core/router/app_router.dart`
- Routes définies : `/` (startup), `/login`, `/register`, `/forgot-password`, `/home` (shell avec BottomNav), `/manga/:muId`, `/manga/:muId/read`, `/manga/:muId/read-offline`, `/downloads`, `/notifications-settings`, `/my-data`, `/custom-selectors`
- Deep-linking URL actif pour le web (F5 + partage + bouton back)

### HTTP

- `http ^1.3.0` — client HTTP principal via `HttpService` centralisé (`lib/core/network/http_service.dart`)
- `dio ^5.4.0` — présent dans les dépendances (usage secondaire)
- `flutter_dotenv ^5.1.0` — chargement des variables d'environnement depuis les assets
- URL de l'API construite par `lib/core/network/uri_builder.dart` via `MT_API_URL` (dotenv)
- Fichiers env : `assets/env/.env.development` / `assets/env/.env.production`

### Stockage local

- `flutter_secure_storage ^9.2.4` — tokens JWT (Android + iOS + Web)
- `shared_preferences ^2.2.3` — préférences non sensibles (langue, thème, etc.)
- `sqflite ^2.3.3+1` — base SQLite embarquée (utilisée par `flutter_cache_manager` pour le cache d'images)
- Cache JSON custom via `OfflineCacheService` (`lib/core/services/offline_cache_service.dart`) — clés documentées dans `lib/core/services/cache_helper_service.dart`
- Pas de Hive, Drift, Isar ni Realm

### UI / Design System

- Material 3 (`useMaterial3: true`)
- `google_fonts ^6.2.1` — typographie
- `cached_network_image ^3.3.1` — toutes les images réseau (jamais `Image.network`)
- `auto_size_text ^3.0.0` — textes adaptatifs
- `flutter_markdown ^0.7.1` — rendu Markdown (changelogs, descriptions)
- `fancy_button_flutter ^1.0.3+1` — boutons animés (usage localisé)
- Tokens du design system dans `lib/core/theme/` :
  - `AppColors` — palette (primary, accent, success, error, warning, info)
  - `AppRadius` — rayons xs/sm/md/lg/xl/xxl/xxxl/huge/jumbo + BorderRadius pré-fabriqués
  - `AppSpacing` — espacement xs(4)/s(8)/m(16)/l(24)/xl(32)/jumbo(48) + EdgeInsets pré-fabriqués
  - `AppTextStyle` — styles de texte
  - `AppTheme` — ThemeData light + dark

### Composants réutilisables (`lib/core/components/`)

| Composant | Description |
|-----------|-------------|
| `AppCard` | Carte de contenu standard |
| `AppChip` | Pastille couleur (badge/tag/status) |
| `AppCountBadge` | Compteur rond |
| `AppEmptyState` | État vide avec icône + CTA |
| `AppErrorState` | État erreur avec retry |
| `AppListTile` | Item de liste stylisé |
| `AppAvatar` | Avatar utilisateur |
| `AuthButton` | Bouton CTA auth |
| `FilterButton` | Bouton filtre activable |
| `SearchBar` | Barre de recherche |
| `PasswordFields` | Champs password + validation |
| `IntputTextfield` | Champ texte stylisé |
| `LanguageSelectorButton` | Sélecteur de langue |
| `ChangelogDialog` | Dialog changelog |
| `WelcomeHeader` | Hero de bienvenue |
| `OfflineBanner` | Bandeau mode hors-ligne |
| `PastelTile` | Tuile pastel |
| `RefreshableMangaImage` | Image manga avec refresh |
| `ThemeToggleButton` | Bascule thème clair/sombre |
| `UserRatingStars` | Étoiles de notation |
| `VerifyEmailBanner` | Bandeau vérification email |

### i18n

- `flutter_localizations` (SDK Flutter) + `intl ^0.20.2`
- ARB dans `lib/l10n/`, fichier de référence : `app_fr.arb`
- 7 langues : FR (référence), EN, DE, JA, KO, PT, ES
- Config dans `l10n.yaml` — génération via `flutter gen-l10n`
- Accès dans les widgets : `context.l10n.clé` ou `AppLocalizations.of(context)!.clé`

### Auth

- JWT + refresh token via `HttpService` (auto-refresh transparent, 401 → refresh → retry)
- `local_auth ^2.1.6` — authentification biométrique (fingerprint, Face ID)
- `google_sign_in ^7.2.0` — OAuth Google (mobile via idToken, web via OAuth WebView)
- `app_links ^6.4.1` — deep-links (magic link email, OAuth callback)
- GDPR : `GdprService` expose les droits utilisateur via `/user/gdpr/*`

### Mode offline-first

- Détection offline : `SocketException` (pas `ConnectivityService`)
- `connectivity_plus ^5.0.2` — suivi de l'état réseau via `ConnectivityBloc`
- Fallback API → cache JSON via `OfflineCacheService` / `CacheHelperService`
- Queue d'actions offline → sync automatique à la reconnexion via `SyncService`
- Tous les états BLoC incluent `isOffline` (et `pendingActions` si applicable)

### Notifications & tâches de fond

- `flutter_local_notifications ^17.2.3` — notifications locales (Android + iOS)
- `workmanager ^0.9.0` — tâches périodiques en arrière-plan (Android-only, à abstraire)

### WebView

- `flutter_inappwebview ^6.0.0` — WebView avancée
- `webview_flutter ^4.0.7` + `webview_flutter_web ^0.2.3` — WebView cross-platform

### Utilitaires

- `path_provider ^2.1.2` — chemins système cross-platform
- `open_file ^3.3.2` — ouverture de fichiers
- `url_launcher ^6.3.1` — liens externes
- `package_info_plus ^4.0.0` — infos app (version)
- `device_info_plus ^11.4.0` — infos appareil
- `permission_handler ^11.3.1` — gestion des permissions
- `image_picker ^1.0.7` — sélecteur galerie/caméra (avatar profil)
- `html ^0.15.4` — parsing HTML
- `dashbook ^0.1.10` — storybook de composants (voir `lib/stories/`, `lib/storybook.dart`)

---

## Backend externe

L'API backend n'est **pas** dans ce repo. C'est un service REST externe hébergé séparément.

- **URL API (prod) :** `https://api.bladeburu.com`
- **URL API (dev) :** `http://localhost:3001` (ou IP locale réseau)
- **Variable d'environnement :** `MT_API_URL` dans `assets/env/.env.development` / `.env.production`
- **Type d'API :** REST (JSON)
- **Auth côté client :** JWT (access token + refresh token) stockés dans `flutter_secure_storage`
- **Client HTTP :** `lib/core/network/http_service.dart` — wrapper centralisé avec auto-refresh JWT
- **Construction des URIs :** `lib/core/network/uri_builder.dart` (normalise protocole, évite double slashes)
- **Google OAuth :** `GOOGLE_CLIENT_ID` / `GOOGLE_WEB_CLIENT_ID` dans les fichiers env
- Endpoints documentés dans `.claude/docs/api-contracts.md`

---

## Structure du code (`lib/`)

```
lib/
├── main.dart                    # Point d'entrée
├── storybook.dart               # Storybook Dashbook
├── core/
│   ├── bloc/                    # BLoCs transverses (ConnectivityBloc)
│   ├── components/              # Design system — primitives réutilisables
│   ├── network/                 # HttpService, UriBuilder, NetworkCompat (io/web)
│   ├── notifier/                # Notifiers globaux
│   ├── router/                  # app_router.dart (go_router)
│   ├── service_locator/         # service_locator.dart (GetIt setup)
│   ├── services/                # Services transverses (cache, connectivity, notifications, theme, language, sync)
│   ├── storage/                 # StorageService (flutter_secure_storage wrapper)
│   ├── theme/                   # AppColors, AppRadius, AppSpacing, AppTextStyle, AppTheme
│   └── utils/                   # Utilitaires communs
└── features/
    ├── auth/                    # Login, register, forgot-password, startup, GDPR
    ├── comments/                # Commentaires manga
    ├── download/                # Téléchargement chapitres
    ├── friends/                 # Système social
    ├── home/                    # Page d'accueil (tendances, nouveautés, populaires)
    ├── library/                 # Bibliothèque utilisateur
    ├── manga/                   # Détail manga
    ├── profile/                 # Profil, mes données, paramètres
    ├── reader/                  # Lecteur de manga
    ├── recommendations/         # Recommandations personnalisées
    ├── search/                  # Recherche
    ├── sharing/                 # Partage
    └── stats/                   # Statistiques lecture
```

Chaque feature suit la structure : `bloc/`, `services/`, `views/`, `widgets/`, `exceptions/` (selon les besoins).

---

## BLoCs enregistrés (GetIt)

| BLoC | Enregistrement | Rôle |
|------|---------------|------|
| `HomePageBloc` | Lazy singleton | Tendances / nouveautés / populaires |
| `LibraryBloc` | Lazy singleton | Bibliothèque utilisateur |
| `DetailBloc` | **Factory** | Détails manga — une instance par page (evite race conditions) |
| `ConnectivityBloc` | Singleton | État connexion réseau |

---

## Android — Configuration native

- **Gradle :** Kotlin DSL (`build.gradle.kts`)
- **compileSdk / targetSdk :** `flutter.compileSdkVersion` / `flutter.targetSdkVersion` (géré par Flutter)
- **minSdk :** `flutter.minSdkVersion`
- **NDK :** 27.0.12077973
- **Java :** VERSION_11 (`compileOptions` + `kotlinOptions`)
- **Core library desugaring :** actif (`desugar_jdk_libs:2.0.4`)
- **Flavors :** `dev` (applicationId `com.example.manga_tracker.dev`) et `prod` (applicationId `com.example.manga_tracker`)
- **Signing :** `key.properties` local (non versionné) ou variables CI (`KEYSTORE_BASE64`, `KEY_ALIAS`, `KEY_PASSWORD`, `KEYSTORE_PASSWORD`)
- **Namespace :** `com.example.manga_tracker`

---

## Outils transverses

- **Gestionnaire de paquets :** `pub` (Dart/Flutter natif)
- **Linter :** `flutter_lints ^5.0.0` (règles Flutter recommandées) + `flutter analyze`
- **Tests unitaires/widget :** `flutter_test` (SDK Flutter)
- **Mocking :** `mocktail ^1.0.3`
- **Tests présents :** `test/core/components/`, `test/features/auth/`, `test/features/manga/`, `test/widget_test.dart`
- **CI/CD :** GitHub Actions (2 workflows)
  - `release_workflow.yml` — build APK prod + bump version + GitHub Release (déclenché par PR label, workflow_dispatch, ou push master)
  - `web-deploy.yml` — build Flutter Web + image Docker + déploiement NAS TrueNAS via SSH
- **Docker :** `deploy/web/Dockerfile` — conteneur Nginx pour le build web
- **Storybook :** Dashbook (`lib/stories/`, `lib/storybook.dart`) — visualisation isolée des composants
- **Script utilitaire :** `bin/update_version_json.dart` — mise à jour de `assets/version.json`
- **Monorepo :** Non — single app Flutter

---

## Commandes principales

```bash
# Développement
flutter run                                 # Emulateur/device par défaut
flutter run --flavor dev -t lib/main.dart   # Flavor dev
flutter run --flavor prod -t lib/main.dart  # Flavor prod
flutter run -d chrome                       # Web (navigateur)

# Build
flutter build apk --flavor prod            # APK Android prod
flutter build appbundle --flavor prod      # App Bundle (.aab) pour Play Store
flutter build web --release --base-href "/" # Build web

# i18n
flutter gen-l10n                           # Régénérer les fichiers de localisation

# Tests
flutter test                               # Tous les tests
flutter test test/features/auth/           # Tests d'une feature

# Analyse
flutter analyze                            # Linter statique
flutter pub outdated                       # Dépendances obsolètes

# Dépendances
flutter pub get                            # Installer les dépendances
flutter pub upgrade                        # Mettre à jour les dépendances
```
