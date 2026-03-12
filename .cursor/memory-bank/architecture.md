# Architecture — Manga Tracker Flutter

## Stack technique

| Technologie | Version | Usage |
|------------|---------|-------|
| Flutter | 3.x | Framework UI (Mobile + Web) |
| Dart | 3.7.2+ | Langage (null safety obligatoire) |
| flutter_bloc | ^8.1.3 | State management — BLoC pattern |
| get_it | ^8.0.3 | Injection de dépendances (Service Locator) |
| http | ^1.3.0 | Client HTTP (via HttpService) |
| flutter_secure_storage | ^9.2.4 | Tokens JWT (stockage sécurisé) |
| shared_preferences | ^2.2.3 | Cache offline + préférences |
| cached_network_image | ^3.3.1 | Images réseau avec cache |
| connectivity_plus | ^5.0.2 | Détection connectivité |
| local_auth | ^2.1.6 | Biométrie (Face ID / empreinte) |
| flutter_inappwebview | ^6.0.0 | WebView avancée (plateformes légales) |
| google_fonts | ^6.1.1 | Polices |
| flutter_localizations + intl | SDK + ^0.20.2 | i18n — 7 langues (ARB) |

---

## Structure du projet

```
lib/
├── core/                          # Code partagé
│   ├── bloc/                      # ConnectivityBloc (singleton)
│   ├── components/                # Widgets réutilisables (MangaCard, MangaRow…)
│   ├── network/                   # HttpService (JWT auto-refresh)
│   ├── notifier/                  # Notifications toast
│   ├── service_locator/           # GetIt — service_locator.dart
│   ├── services/                  # Services partagés
│   │   ├── app_update_service.dart
│   │   ├── cache_helper_service.dart
│   │   ├── connectivity_service.dart
│   │   ├── offline_cache_service.dart
│   │   └── sync_service.dart
│   ├── storage/                   # StorageService (flutter_secure_storage)
│   └── theme/                     # AppTheme (Material 3) + AppRadius
│
├── features/
│   ├── auth/                      # Login, register, biométrie
│   ├── home/                      # Tendances, nouveautés, populaires
│   ├── library/                   # Bibliothèque utilisateur
│   ├── manga/                     # Détails manga + lecture
│   ├── profile/                   # Profil utilisateur
│   ├── reader/                    # Services WebView (en cours)
│   └── search/                    # Recherche de mangas
│
├── l10n/                          # ARB : app_fr.arb, app_en.arb, app_de.arb…
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

---

## Mode offline-first

1. Appel API → succès → mise en cache → état `isOffline: false`
2. Appel API → `SocketException` → chargement cache → état `isOffline: true`
3. Actions offline → queue dans `OfflineCacheService`
4. Reconnexion → `SyncService` traite la queue automatiquement

**Règle** : Détecter l'offline via `SocketException`, PAS via `ConnectivityService`.

---

## Navigation

```
StartupPage → LoginView (si non auth) | BottomNavbar (si auth)
BottomNavbar [PageView] :
  [0] HomePageBlocView  [1] LibraryBlocView  [2] Search  [3] Profile
Pages détail : MaterialPageRoute + BlocProvider(create: (_) => getIt<DetailBloc>())
```

Migration `go_router` prévue en v0.4.

---

## Internationalisation

- 7 langues : FR (référence), EN, DE, JA, KO, PT, ES
- Fichiers ARB dans `lib/l10n/`
- `LanguageService` pour la persistance et le changement dynamique
- **Zéro texte hardcodé** dans les widgets — tout via `context.l10n.maCle`
