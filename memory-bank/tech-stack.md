# 🧰 Tech Stack — Manga Tracker

> Objectif : stack **simple, robuste et scalable** alignée sur le PRD et l'Implementation Plan.
> Principe : privilégier des composants standards, observables, testables et faciles à automatiser en CI/CD.

---

## Vue d'ensemble

- **App client** : Flutter (mobile d'abord, web en bonus)
- **API** : Node.js (NestJS) + PostgreSQL
- **Cache / Jobs** : Redis (+ BullMQ) - prévu
- **ML Recos** : Service Python (LightFM) exposé via FastAPI - prévu
- **Fichiers** (avatars, assets) : S3 compatible (MinIO/Wasabi/Supabase) - prévu
- **Auth** : JWT (first-party) + Google OAuth2 (prévu)
- **Notifications** : À définir
- **Observabilité** : À définir
- **CI/CD** : GitHub Actions (lint, tests, build, versioning, release) - prévu

---

## 1) Client — Flutter

### Langage et SDK
- **Langage** : Dart (>= 3.7.2)
- **Flutter SDK** : Version récente avec support Material 3

### Gestion d'état
- **State management** : **BLoC** (flutter_bloc ^8.1.3, bloc ^8.1.2)
  - Pattern BLoC pour une architecture réactive et testable
  - Utilisation de `Equatable` pour la comparaison d'états
  - BLoCs principaux : `HomePageBloc`, `LibraryBloc`, `DetailBloc`, `ConnectivityBloc`
  - `DetailBloc` en factory (une instance par page) pour éviter les race conditions

### Navigation
- **Navigation** : **MaterialApp** avec `PageView` et `Navigator`
  - Bottom navigation bar avec PageView pour la navigation entre les pages principales
  - Navigation par routes classiques (MaterialPageRoute)
  - Pas de go_router actuellement (peut être migré ultérieurement)

### HTTP et réseau
- **HTTP client principal** : `http` (^1.3.0)
- **HTTP client alternatif** : `dio` (^5.4.0) - disponible mais non utilisé actuellement
- **Service HTTP personnalisé** : `HttpService` avec gestion automatique des tokens JWT
  - Refresh automatique des tokens expirés
  - Gestion des erreurs 401 (Unauthorized)
- **Variables d'environnement** : `flutter_dotenv` (^5.1.0)
  - Support dev/production avec fichiers `.env.development` et `.env.production`

### Stockage local
- **Stockage sécurisé** : `flutter_secure_storage` (^9.2.4)
  - Tokens JWT (accessToken, refreshToken)
  - Données sensibles
  - Support Linux : `flutter_secure_storage_linux` (^1.2.3)
- **Préférences légères** : `shared_preferences` (^2.2.3)
  - Données non sensibles
  - Préférences utilisateur
- **Pas de Hive** : Utilisation de flutter_secure_storage pour le cache offline (via JSON)

### Mode hors ligne
- **Connectivité** : `connectivity_plus` (^5.0.2)
  - Détection de l'état de connexion réseau
- **Cache d'images** : `cached_network_image` (^3.3.1)
  - Cache automatique des images pour le mode offline
  - Base de données : `sqflite` (^2.3.3+1) - utilisée par flutter_cache_manager
- **Services offline** :
  - `OfflineCacheService` : Gestion du cache des données (bibliothèque, détails, recherche, informations utilisateur)
  - `CacheHelperService` : Helper pour faciliter l'utilisation du cache avec fallback
  - `SyncService` : Synchronisation automatique des actions hors ligne
  - Queue d'actions offline avec retry automatique
  - Cache des informations utilisateur (7 jours) avec mise à jour en arrière-plan

### Authentification
- **Biométrie** : `local_auth` (^2.1.6)
  - Authentification par empreinte digitale / Face ID
  - Sauvegarde sécurisée des identifiants
- **Service d'authentification** : `AuthService`
  - Login / Register
  - Gestion des tokens JWT
  - Refresh automatique

### UI et Design
- **Thème** : Material 3 (partiellement implémenté)
  - `AppTheme` avec thème clair
  - Thème sombre prévu (commenté dans main.dart)
- **Polices** : `google_fonts` (^6.1.1)
- **Composants UI** :
  - `auto_size_text` (^3.0.0) pour les textes adaptatifs
  - `fancy_button_flutter` (^1.0.3+1)
  - `html` (^0.15.4) pour le parsing HTML
- **Markdown** : `flutter_markdown` (^0.7.1)
  - Affichage du changelog
  - Documentation utilisateur

### WebView et liens externes
- **WebView** : `webview_flutter` (^4.0.7) + `webview_flutter_web` (^0.2.3)
- **WebView avancé** : `flutter_inappwebview` (^6.0.0)
  - Redirection vers plateformes légales de lecture
  - Navigation dans les sites externes
- **Lanceur d'URL** : `url_launcher` (^6.3.1)

### Utilitaires
- **Dependency Injection** : `get_it` (^8.0.3)
  - Service locator centralisé
  - Support des singletons et factories
  - Initialisation asynchrone avec dépendances
- **Gestion de fichiers** :
  - `path_provider` (^2.1.2) : Chemins système
  - `open_file` (^3.3.2) : Ouverture de fichiers
- **Info système** :
  - `package_info_plus` (^4.0.0) : Informations sur l'app (version, build)
  - `device_info_plus` (^11.4.0) : Informations sur l'appareil
- **Permissions** : `permission_handler` (^11.3.1)
- **Intents Android** : `android_intent_plus` (^5.3.0)

### Développement et tests
- **Storybook** : `dashbook` (^0.1.10)
  - Documentation des composants UI
  - Tests visuels
- **Linting** : `flutter_lints` (^5.0.0)
- **Tests** : `flutter_test` (SDK)
  - Tests unitaires et widget tests
  - Tests d'intégration prévus

### CI/CD et Build
- **Icônes** : `flutter_launcher_icons` (^0.13.1)
  - Génération automatique des icônes d'application
- **CI/CD** : GitHub Actions (prévu)
  - Linter automatique
  - Build APK automatisé
  - Versioning automatique
  - Publication GitHub Release avec changelog

### Internationalisation
- **i18n** : `flutter_localizations` (SDK) + `intl` (^0.20.2)
  - Support complet de 7 langues : Français (FR), Anglais (EN), Allemand (DE), Japonais (JA), Coréen (KO), Portugais (PT), Espagnol (ES)
  - Fichiers ARB dans `lib/l10n/` pour chaque langue
  - `LanguageService` pour la gestion et la persistance de la préférence de langue
  - Sélecteur de langue dans le profil utilisateur avec drapeaux
  - Changement de langue dynamique sans redémarrage de l'application

### Notifications
- **Push notifications** : `firebase_messaging` - prévu mais non implémenté actuellement

---

## 2) Backend — Node.js / NestJS

> **Note** : Le backend est géré dans un repository séparé. Cette section documente l'architecture backend prévue/intégrée.

- **Framework** : NestJS (ou Express)
- **Base de données** : PostgreSQL
- **Authentification** : JWT (accessToken + refreshToken)
- **Documentation API** : Swagger
- **Cache** : Redis (prévu)
- **Queue** : BullMQ (prévu)

---

## 3) Architecture des données

### DTOs (Data Transfer Objects)
- `MangaQuickViewDto` : Vue rapide d'un manga (liste, bibliothèque)
- `MangaDetailDto` : Détails complets d'un manga
- `MangaRecommendationViewDto` : Recommandations de mangas
- `AuthorDto` : Informations sur les auteurs
- `SeasonChapterDto` : Informations sur les chapitres
- `ReadingStatus` : Enum pour le statut de lecture
- `UserDto` / `UserInformationDto` : Informations utilisateur

### Services
- `AuthService` : Authentification
- `MangaService` : Récupération des données mangas
- `LibraryService` : Gestion de la bibliothèque utilisateur
- `UserService` : Gestion du profil utilisateur (avec cache des informations utilisateur)
- `LanguageService` : Gestion de la langue de l'application et persistance
- `AppUpdateService` : Gestion des mises à jour et changelog
- `ConnectivityService` : Détection de la connectivité
- `OfflineCacheService` : Cache offline (bibliothèque, détails, recherche, profil)
- `SyncService` : Synchronisation des actions offline
- `CacheHelperService` : Helper pour le cache avec fallback

---

## 4) Patterns d'architecture

### Feature-based architecture
```
lib/
  core/           # Services partagés, thème, composants réutilisables
  features/        # Modules par fonctionnalité
    auth/         # Authentification
    home/         # Page d'accueil
    library/      # Bibliothèque utilisateur
    manga/        # Détails et gestion des mangas
    profile/      # Profil utilisateur
    search/       # Recherche
    reader/       # Lecture (prévu)
```

### BLoC Pattern
- Chaque feature a son propre BLoC (`*_bloc.dart`)
- Events (`*_event.dart`) pour les actions utilisateur
- States (`*_state.dart`) pour l'état de l'UI
- Séparation claire entre logique métier et présentation

### Service Locator Pattern
- `GetIt` pour l'injection de dépendances
- Services enregistrés dans `service_locator.dart`
- Initialisation asynchrone avec dépendances

### Offline-First Architecture
- Cache automatique des données
- Queue d'actions offline
- Synchronisation automatique à la reconnexion
- Détection intelligente du mode offline basée sur les erreurs réseau

---

## 5) Sécurité

- **Stockage sécurisé** : Tokens JWT dans flutter_secure_storage
- **Authentification biométrique** : Sauvegarde sécurisée des identifiants
- **Refresh automatique** : Renouvellement transparent des tokens
- **Gestion des erreurs** : Exceptions personnalisées pour les erreurs d'authentification

---

## 6) Performance

- **Cache d'images** : `cached_network_image` pour réduire la bande passante
- **Lazy loading** : BLoCs en lazy singleton pour économiser la mémoire
- **Factory pattern** : `DetailBloc` en factory pour éviter les race conditions
- **Optimisation des listes** : Utilisation de ListView.builder pour les grandes listes

---

## 7) Évolutions prévues

- Migration vers `go_router` pour une navigation déclarative
- Intégration de `firebase_messaging` pour les notifications push
- Activation du thème sombre
- Internationalisation complète
- Tests d'intégration avec `patrol` (e2e)
- CI/CD complet avec GitHub Actions
