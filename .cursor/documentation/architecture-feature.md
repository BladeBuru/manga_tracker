# Documentation : Structure d'une Feature — Manga Tracker Flutter

## Pattern standard d'une feature

```
lib/features/[feature]/
├── bloc/
│   ├── [feature]_bloc.dart       # class [Feature]Bloc extends Bloc<Event, State>
│   ├── [feature]_event.dart      # part of '[feature]_bloc.dart'
│   └── [feature]_state.dart      # part of '[feature]_bloc.dart'
├── dto/
│   └── [model]_dto.dart          # fromJson / toJson
├── exceptions/
│   └── [feature]_exception.dart  # Exceptions métier
├── helpers/
│   └── [feature]_helper.dart     # Fonctions utilitaires
├── services/
│   └── [feature]_service.dart    # Logique métier + HTTP
├── views/
│   └── [feature]_bloc_view.dart  # Page principale avec BlocBuilder
└── widgets/
    └── [component]_widget.dart   # Sous-composants réutilisables
```

---

## Features existantes

### `auth` — Authentification

| Composant | Fichier | Rôle |
|-----------|---------|------|
| Services | `auth.service.dart`, `biometric.service.dart` | Login, register, refresh, biométrie |
| Views | `login_view.dart`, `register_view.dart`, `startup_page.dart` | Écrans d'authentification |
| Widgets | — | — |
| Exceptions | `auth_exceptions.dart` | `InvalidCredentialsException`, `InvalidTokenException` |

---

### `home` — Page d'accueil

| Composant | Fichier | Rôle |
|-----------|---------|------|
| BLoC | `home_page_bloc.dart` | Chargement tendances / nouveautés / populaires |
| States | `HomePageInitial`, `HomePageLoading`, `HomePageLoaded`, `HomePageError` | — |
| Events | `LoadHomePage` | — |
| Views | `home_page_bloc_view.dart` | Page principale avec filtres |
| Widgets | — | Composants de la home |

**Enregistrement GetIt** : Lazy singleton

---

### `library` — Bibliothèque utilisateur

| Composant | Fichier | Rôle |
|-----------|---------|------|
| BLoC | `library_bloc.dart` | Gestion bibliothèque |
| States | `LibraryInitial`, `LibraryLoading`, `LibraryLoaded(isOffline)`, `LibraryError` | — |
| Events | `LoadLibrary`, `RefreshLibrary` | — |
| Services | `library.service.dart` | CRUD bibliothèque + offline |
| Views | `library_bloc_view.dart` | Vue liste avec indicateur offline |

**Enregistrement GetIt** : Lazy singleton

---

### `manga` — Détails d'un manga

| Composant | Fichier | Rôle |
|-----------|---------|------|
| BLoC | `detail_bloc.dart` | Détails + actions bibliothèque |
| States | `DetailInitial`, `DetailLoading`, `DetailLoaded(isOffline, pendingActions)`, `DetailError` | — |
| Events | `LoadDetail`, `AddToLibrary`, `RemoveFromLibrary`, `UpdateReadingStatus`, `SaveProgress` | — |
| DTOs | `manga_quick_view_dto.dart`, `manga_detail_dto.dart` | — |
| Services | `manga.service.dart` | Récupération mangas |
| Views | `late_detail_view.dart`, `row_chapter.dart`, `web_view.dart` | Détail + lecture |

**Enregistrement GetIt** : **FACTORY** (obligatoire — une instance par page)

```dart
// Navigation vers une page de détails
Navigator.of(context).push(MaterialPageRoute(
  builder: (_) => BlocProvider(
    create: (_) => getIt<DetailBloc>()..add(LoadDetail(muId: muId)),
    child: const LateDetailView(),
  ),
));
```

---

### `profile` — Profil utilisateur

| Composant | Fichier | Rôle |
|-----------|---------|------|
| Services | `user.service.dart` | Profil + changement MDP + suppression compte |
| DTOs | `user_dto.dart`, `user_information_dto.dart` | — |
| Views | `profile.dart` | Page profil avec sections et options |
| Widgets | `profile_option_tile.dart`, `profile_section.dart`, `profile_header.dart` | Composants réutilisables |

---

### `search` — Recherche

| Composant | Fichier | Rôle |
|-----------|---------|------|
| Views | `search.dart` | Recherche de mangas |

---

### `reader` — Lecture (en cours)

| Composant | Fichier | Rôle |
|-----------|---------|------|
| Services | `ad_blocker_service.dart`, `captcha_detection_service.dart`, `scroll_position_service.dart`, `webview_navigation_service.dart` | Services WebView |

---

## Core — Code partagé

```
lib/core/
├── bloc/
│   └── connectivity_bloc.dart     # ConnectivityBloc (singleton)
├── components/                    # Widgets réutilisables
│   ├── manga_card.dart
│   ├── manga_row.dart
│   ├── filter_button.dart
│   ├── welcome_header.dart
│   ├── manga_type.dart
│   ├── profile_option_tile.dart
│   ├── profile_section.dart
│   ├── profile_header.dart
│   └── changelog_card.dart
├── network/
│   └── http_service.dart          # HttpService (JWT auto-refresh)
├── notifier/
│   └── notifier.dart              # Notifications toast
├── service_locator/
│   └── service_locator.dart       # GetIt — enregistrement de tous les services
├── services/
│   ├── app_update_service.dart
│   ├── cache_helper_service.dart
│   ├── connectivity_service.dart
│   ├── offline_cache_service.dart
│   └── sync_service.dart
├── storage/
│   └── storage_service.dart       # flutter_secure_storage wrapper
└── theme/
    ├── app_theme.dart             # Material 3 ThemeData
    └── app_radius.dart            # AppRadius — design tokens
```

---

## Navigation principale

```
main.dart
└── MyApp (MaterialApp)
    └── StartupPage
        ├── LoginView (si non authentifié)
        └── BottomNavbar (si authentifié)
            ├── [0] HomePageBlocView (HomePageBloc)
            ├── [1] LibraryBlocView (LibraryBloc)
            ├── [2] Search
            └── [3] Profile
```

Chaque page de détails est ouverte via `MaterialPageRoute` avec `DetailBloc` en factory.

---

## Ordre d'initialisation GetIt (`service_locator.dart`)

```
1. StorageService (async singleton)
2. AuthService (dépend de StorageService)
3. HttpService (dépend de StorageService + AuthService)
4. MangaService (dépend de HttpService)
5. ConnectivityService (async singleton)
6. OfflineCacheService (dépend de StorageService)
7. LibraryService (dépend de HttpService + MangaService + ConnectivityService + OfflineCacheService)
8. SyncService (dépend de ConnectivityService + OfflineCacheService + LibraryService)
9. CacheHelperService (dépend de ConnectivityService + OfflineCacheService)
10. UserService (dépend de HttpService + OfflineCacheService)
11. LanguageService
12. AppUpdateService
13. BLoCs (lazy singletons ou factories)
```

**Règle** : Ne jamais enregistrer un service avant ses dépendances.
