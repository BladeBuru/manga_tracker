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
│   └── [feature]_exception.dart
├── helpers/
│   └── [feature]_helper.dart
├── services/
│   └── [feature]_service.dart    # Logique métier + HTTP
├── views/
│   └── [feature]_bloc_view.dart  # Page principale avec BlocBuilder
└── widgets/
    └── [component]_widget.dart   # Sous-composants
```

---

## Features existantes

### `auth`
| Composant | Fichier | Rôle |
|-----------|---------|------|
| Services | `auth.service.dart`, `biometric.service.dart` | Login, register, refresh, biométrie |
| Views | `login_view.dart`, `register_view.dart`, `startup_page.dart` | Écrans d'auth |
| Exceptions | `auth_exceptions.dart` | `InvalidCredentialsException`, `InvalidTokenException` |

### `home`
| Composant | Fichier | Rôle |
|-----------|---------|------|
| BLoC | `home_page_bloc.dart` (lazy singleton) | Tendances / nouveautés / populaires |
| Events | `LoadHomePage` | — |
| States | `HomePageInitial`, `HomePageLoading`, `HomePageLoaded`, `HomePageError` | — |
| Views | `home_page_bloc_view.dart` | Page principale |

### `library`
| Composant | Fichier | Rôle |
|-----------|---------|------|
| BLoC | `library_bloc.dart` (lazy singleton) | Bibliothèque |
| Events | `LoadLibrary`, `RefreshLibrary` | — |
| States | `LibraryInitial`, `LibraryLoading`, `LibraryLoaded(isOffline)`, `LibraryError` | — |
| Services | `library.service.dart` | CRUD + offline |
| Views | `library_bloc_view.dart` | Vue liste avec offline banner |

### `manga`
| Composant | Fichier | Rôle |
|-----------|---------|------|
| BLoC | `detail_bloc.dart` (**FACTORY** ⚠️) | Détails + actions library |
| Events | `LoadDetail`, `AddToLibrary`, `RemoveFromLibrary`, `UpdateReadingStatus`, `SaveProgress` | — |
| States | `DetailInitial`, `DetailLoading`, `DetailLoaded(isOffline, pendingActions)`, `DetailError` | — |
| DTOs | `manga_quick_view_dto.dart`, `manga_detail_dto.dart` | — |
| Services | `manga.service.dart` | Récupération mangas |
| Views | `late_detail_view.dart`, `row_chapter.dart`, `web_view.dart` | Détail + lecture |

⚠️ **Navigation vers DetailView** :
```dart
Navigator.of(context).push(MaterialPageRoute(
  builder: (_) => BlocProvider(
    create: (_) => getIt<DetailBloc>()..add(LoadDetail(muId: muId)),
    child: const LateDetailView(),
  ),
));
```
À migrer vers `go_router` (voir skill `/web-readiness`).

### `profile`
| Composant | Fichier | Rôle |
|-----------|---------|------|
| Services | `user.service.dart` | Profil + MDP + suppression |
| DTOs | `user_dto.dart`, `user_information_dto.dart` | — |
| Views | `profile.dart` | Page profil |
| Widgets | `profile_option_tile.dart`, `profile_section.dart`, `profile_header.dart` | — |

### `search`
| Composant | Fichier | Rôle |
|-----------|---------|------|
| Views | `search.dart` | Recherche de mangas |

### `reader`
| Composant | Fichier | Rôle |
|-----------|---------|------|
| Services | `ad_blocker_service.dart`, `captcha_detection_service.dart`, `scroll_position_service.dart`, `webview_navigation_service.dart` | Services WebView |

### `download`
| Composant | Fichier | Rôle |
|-----------|---------|------|
| Services | `download_manager_service.dart` | Téléchargements offline (utilise `dart:io` — à abstraire pour iOS/Web) |

---

## Core — Code partagé

```
lib/core/
├── bloc/
│   └── connectivity_bloc.dart     # ConnectivityBloc (singleton)
├── components/                    # Widgets réutilisables
│   ├── auth_button.dart
│   ├── filter_button.dart
│   ├── search_bar.dart
│   ├── password_fields.dart
│   ├── language_selector_button.dart
│   ├── changelog_dialog.dart
│   ├── welcome_header.dart
│   └── intput_textfield.dart
├── network/
│   └── http_service.dart          # JWT auto-refresh
├── notifier/
│   └── notifier.dart              # Toasts
├── service_locator/
│   └── service_locator.dart       # GetIt
├── services/
│   ├── app_update_service.dart
│   ├── cache_helper_service.dart
│   ├── connectivity_service.dart
│   ├── offline_cache_service.dart
│   └── sync_service.dart
├── storage/
│   └── storage_service.dart       # flutter_secure_storage
└── theme/
    ├── app_colors.dart
    ├── app_radius.dart
    ├── app_text_styles.dart
    └── app_theme.dart             # Material 3 light + dark
```

À créer (évolution) : `lib/core/theme/app_spacing.dart` — voir `.claude/docs/design-system.md`.

---

## Navigation

```
main.dart
└── MyApp (MaterialApp)
    └── StartupPage
        ├── LoginView (si non auth)
        └── BottomNavbar (si auth)
            ├── [0] HomePageBlocView (HomePageBloc)
            ├── [1] LibraryBlocView (LibraryBloc)
            ├── [2] Search
            └── [3] Profile
```

Pages détail : `MaterialPageRoute` + `BlocProvider(create: (_) => getIt<DetailBloc>())`.

**Migration `go_router` prévue en v0.4 — obligatoire pour le build web.**

---

## Ordre d'initialisation GetIt

```
1. StorageService (async singleton)
2. AuthService (dépend de Storage)
3. HttpService (dépend de Storage + Auth)
4. MangaService (dépend de Http)
5. ConnectivityService (async singleton)
6. OfflineCacheService (dépend de Storage)
7. LibraryService (dépend de Http + Manga + Connectivity + OfflineCache)
8. SyncService (dépend de Connectivity + OfflineCache + Library)
9. CacheHelperService (dépend de Connectivity + OfflineCache)
10. UserService (dépend de Http + OfflineCache)
11. LanguageService
12. AppUpdateService
13. BLoCs (lazy singletons ou factories)
```

**Règle** : Ne jamais enregistrer un service avant ses dépendances.
