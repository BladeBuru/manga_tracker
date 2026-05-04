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

À faire (évolution) :
- `go_router` (obligatoire pour build web)
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

---

## Mode offline-first

1. Appel API → succès → mise en cache → état `isOffline: false`
2. Appel API → `SocketException` → cache → état `isOffline: true`
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

Migration `go_router` prévue v0.4 — **obligatoire avant le build web**.

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
| Web | 🔴 Scaffoldé non wiré | Voir `.claude/skills/web-readiness/SKILL.md` |

Tout nouveau code doit être platform-agnostic par défaut. Voir `.claude/docs/cross-platform.md` pour les patterns d'abstraction.
