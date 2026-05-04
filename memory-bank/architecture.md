# 🏗️ Architecture — Manga Tracker

> Architecture Flutter basée sur une approche **feature-based** avec **BLoC pattern** pour la gestion d'état réactive.

---

## 📐 Vue d'ensemble

L'application Manga Tracker suit une architecture modulaire orientée features, avec une séparation claire entre :
- **Core** : Services partagés, thème, composants réutilisables
- **Features** : Modules indépendants par fonctionnalité métier
- **BLoC Pattern** : Gestion d'état réactive et testable

---

## 📁 Structure du projet

```
lib/
├── core/                          # Code partagé entre toutes les features
│   ├── bloc/                      # BLoCs globaux (ConnectivityBloc)
│   ├── components/                # Composants UI réutilisables
│   ├── network/                    # Services réseau (HttpService)
│   ├── notifier/                  # Système de notifications toast
│   ├── service_locator/            # Injection de dépendances (GetIt)
│   ├── services/                   # Services partagés
│   │   ├── app_update_service.dart
│   │   ├── cache_helper_service.dart
│   │   ├── connectivity_service.dart
│   │   ├── offline_cache_service.dart
│   │   └── sync_service.dart
│   ├── storage/                   # Services de stockage
│   └── theme/                     # Thème Material 3
│
├── features/                       # Modules par fonctionnalité
│   ├── auth/                      # Authentification
│   │   ├── exceptions/
│   │   ├── services/
│   │   ├── views/
│   │   └── widgets/
│   ├── home/                      # Page d'accueil
│   │   ├── bloc/                  # HomePageBloc
│   │   ├── views/
│   │   └── widgets/
│   ├── library/                   # Bibliothèque utilisateur
│   │   ├── bloc/                  # LibraryBloc
│   │   ├── services/
│   │   └── views/
│   ├── manga/                     # Gestion des mangas
│   │   ├── bloc/                  # DetailBloc (factory)
│   │   ├── dto/                   # Data Transfer Objects
│   │   ├── helpers/
│   │   ├── services/
│   │   ├── views/
│   │   └── widgets/
│   ├── profile/                   # Profil utilisateur
│   │   ├── dto/
│   │   ├── helpers/
│   │   ├── services/
│   │   ├── views/
│   │   └── widgets/
│   ├── reader/                   # Lecture (prévu)
│   └── search/                    # Recherche
│
├── stories/                       # Storybook (Dashbook)
└── main.dart                      # Point d'entrée
```

---

## 🔄 Pattern BLoC (Business Logic Component)

### Principe

Chaque feature utilise le pattern BLoC pour séparer la logique métier de l'UI :

```
UI (View) → Event → BLoC → State → UI (View)
```

### Composants BLoC

1. **Event** (`*_event.dart`) : Actions utilisateur (ex: `LoadHomePage`, `AddToLibrary`)
2. **State** (`*_state.dart`) : État de l'UI (ex: `HomePageLoading`, `HomePageLoaded`)
3. **BLoC** (`*_bloc.dart`) : Logique métier qui transforme les Events en States

### BLoCs implémentés

#### HomePageBloc
- **Responsabilité** : Gestion de la page d'accueil (tendances, nouveautés, populaires)
- **État** : `HomePageInitial`, `HomePageLoading`, `HomePageLoaded`, `HomePageError`
- **Fonctionnalités** :
  - Chargement des mangas populaires, nouveaux, tendances
  - Gestion du mode offline
  - Cache automatique

#### LibraryBloc
- **Responsabilité** : Gestion de la bibliothèque utilisateur
- **État** : `LibraryInitial`, `LibraryLoading`, `LibraryLoaded`, `LibraryError`
- **Fonctionnalités** :
  - Chargement de la bibliothèque
  - Gestion du mode offline avec indicateur
  - Affichage des actions en attente

#### DetailBloc
- **Responsabilité** : Gestion de la page de détails d'un manga
- **État** : `DetailInitial`, `DetailLoading`, `DetailLoaded`, `DetailError`
- **Fonctionnalités** :
  - Chargement des détails d'un manga
  - Ajout/suppression de la bibliothèque
  - Sauvegarde de la progression de lecture
  - Mise à jour du statut de lecture
  - Gestion du mode offline
- **Important** : Enregistré en **factory** (une instance par page) pour éviter les race conditions

#### ConnectivityBloc
- **Responsabilité** : Détection de l'état de connexion réseau
- **État** : `ConnectivityInitial`, `ConnectivityConnected`, `ConnectivityDisconnected`

---

## 🧩 Injection de dépendances (GetIt)

### Service Locator

Le fichier `service_locator.dart` centralise l'enregistrement de tous les services et BLoCs.

### Types d'enregistrement

1. **Singleton** : Une seule instance partagée (ex: `StorageService`, `HttpService`)
2. **Lazy Singleton** : Instance créée à la première utilisation (ex: `HomePageBloc`, `LibraryBloc`)
3. **Factory** : Nouvelle instance à chaque appel (ex: `DetailBloc`)
4. **Async Singleton** : Initialisation asynchrone avec dépendances (ex: `StorageService`, `LibraryService`)

### Ordre d'initialisation

```md
1. StorageService (async)
2. AuthService (dépend de StorageService)
3. HttpService (dépend de StorageService, AuthService)
4. MangaService (dépend de HttpService)
5. ConnectivityService (async)
6. OfflineCacheService (dépend de StorageService)
7. LibraryService (dépend de HttpService, MangaService, ConnectivityService, OfflineCacheService)
8. SyncService (dépend de ConnectivityService, OfflineCacheService, LibraryService)
9. CacheHelperService (dépend de ConnectivityService, OfflineCacheService)
10. BLoCs (lazy singletons ou factories)
```

---

## 🌐 Architecture réseau

### HttpService

Service centralisé pour toutes les requêtes HTTP :

- **Gestion automatique des tokens JWT**
  - Ajout automatique du header `Authorization: Bearer <token>`
  - Détection des tokens expirés
  - Refresh automatique via `refreshToken`
  - Retry automatique en cas d'erreur 401

- **Méthodes publiques** :
  - `getWithAuthTokens()` : GET avec authentification
  - `postWithAuthTokens()` : POST avec authentification
  - `putWithAuthTokens()` : PUT avec authentification
  - `deleteWithAuthTokens()` : DELETE avec authentification

### Services métier

- **AuthService** : Authentification (login, register, refresh token)
- **MangaService** : Récupération des données mangas (détails, recherche, recommandations)
- **LibraryService** : Gestion de la bibliothèque (ajout, suppression, statut, progression)
- **UserService** : Gestion du profil utilisateur (infos avec cache, changement de mot de passe, suppression)
- **LanguageService** : Gestion de la langue de l'application (persistance, changement dynamique)

---

## 💾 Architecture offline-first

### Principe

L'application fonctionne en mode **offline-first** :
1. Tentative de chargement depuis l'API
2. En cas d'erreur réseau → Chargement depuis le cache
3. Mise en file d'attente des actions utilisateur
4. Synchronisation automatique à la reconnexion

### Services offline

#### OfflineCacheService
- **Cache des données** :
  - Bibliothèque utilisateur (`cached_library`)
  - Détails de manga (`cached_manga_detail_<muId>`)
  - Page d'accueil (`cached_homepage`)
  - Résultats de recherche (`cached_search_<query>`)
  - Informations utilisateur (`cached_user_info`) - cache de 7 jours avec mise à jour en arrière-plan
- **Queue d'actions offline** (`offline_queue`) :
  - Ajout/suppression de manga
  - Mise à jour du statut de lecture
  - Sauvegarde de la progression
  - Mise à jour des liens personnalisés
- **Métadonnées** : Timestamps pour la gestion de l'expiration du cache

#### CacheHelperService
- **Helper avec fallback automatique** :
  - Tentative de chargement depuis l'API
  - En cas d'erreur réseau → Chargement depuis le cache
  - Propagation des erreurs pour détection du mode offline

#### SyncService
- **Synchronisation automatique** :
  - Détection de la reconnexion
  - Traitement de la queue d'actions offline
  - Retry automatique des actions échouées
  - Gestion des échecs (conservation pour retry ultérieur)

### Détection du mode offline

Le mode offline est détecté via les **erreurs réseau** plutôt que la connectivité :
- Les BLoCs écoutent les exceptions réseau
- En cas d'erreur → Émission d'un état `isOffline: true`
- Affichage d'indicateurs visuels (badge orange)
- Affichage du nombre d'actions en attente

---

## 🎨 Architecture UI

### Navigation

- **BottomNavigationBar** avec `PageView` :
  - Page d'accueil (HomePageBlocView)
  - Bibliothèque (LibraryBlocView)
  - Recherche (Search)
  - Profil (Profile)

- **Navigation par routes** :
  - `MaterialPageRoute` pour les détails et autres pages
  - `NavigatorKey` global pour la navigation depuis les services

### Thème

- **Material 3** partiellement implémenté
- Thème clair actif
- Thème sombre prévu (commenté)
- `AppRadius` centralise les rayons d'arrondi et sert de design token partagé
- Composants réutilisables dans `core/components/`

### Composants réutilisables

- `ProfileOptionTile` : Option de menu du profil
- `ProfileSection` : Section groupée dans le profil
- `ProfileHeader` : En-tête du profil avec avatar
- `ChangelogCard` : Carte d'affichage du changelog
- `MangaCard` : Carte de présentation d'un manga
- `MangaRow` : Ligne de manga dans une liste
- `FilterButton` : Bouton de filtre
- `WelcomeHeader` : En-tête de bienvenue
- `MangaType` : Widget pour afficher les genres/tags (utilisé dans les listes)
- **Genres dans les détails** : Affichage des genres dans `LateDetailView` avec des `Chip` Material 3 stylisés en `Wrap`, placés après les informations principales

---

## 🔐 Sécurité

### Authentification

- **JWT** : AccessToken (courte durée) + RefreshToken (longue durée)
- **Stockage sécurisé** : `flutter_secure_storage` pour les tokens
- **Refresh automatique** : Via `HttpService` en cas d'expiration
- **Biométrie** : `local_auth` pour l'authentification rapide
  - Sauvegarde sécurisée des identifiants

### Gestion des erreurs

- **Exceptions personnalisées** :
  - `InvalidCredentialsException` : Erreurs d'authentification
  - `InvalidTokenException` : Tokens invalides
- **Gestion centralisée** : Via `Notifier` pour les messages utilisateur

---

## 📊 Flow de données

### Exemple : Chargement de la page d'accueil

```
1. User ouvre l'app → HomePageBlocView.initState()
2. HomePageBlocView → HomePageBloc.add(LoadHomePage())
3. HomePageBloc → HomePageBloc._onLoadHomePage()
   a. Émet HomePageLoading()
   b. Appelle CacheHelperService.loadHomePageData()
   c. CacheHelperService → MangaService.getPopularMangas()
   d. Si erreur réseau → CacheHelperService.getCachedHomePageData()
4. HomePageBloc → Émet HomePageLoaded(...) ou HomePageError(...)
5. HomePageBlocView → BlocBuilder reconstruit l'UI
```

### Exemple : Ajout d'un manga en mode offline

```
1. User clique "Ajouter à la bibliothèque" → DetailBloc.add(AddToLibrary(muId))
2. DetailBloc → LibraryService.addMangaToLibrary(muId)
3. Si erreur réseau :
   a. OfflineCacheService.queueOfflineAction(AddMangaAction)
   b. DetailBloc → Émet DetailLoaded(isOffline: true, pendingActions: 1)
4. UI → Affiche indicateur offline + nombre d'actions en attente
5. À la reconnexion :
   a. SyncService détecte la connexion
   b. SyncService → Traite la queue d'actions
   c. DetailBloc → Émet DetailLoaded(isOffline: false, pendingActions: 0)
```

---

## 🔄 Cycle de vie de l'application

### Initialisation

```
main()
  → WidgetsFlutterBinding.ensureInitialized()
  → dotenv.load() (dev/prod)
  → setupServiceLocator()
  → await getIt.allReady() (initialisation asynchrone)
  → runApp(MyApp())
```

### Démarrage

```
MyApp()
  → StartupPage()
    → Vérifie l'authentification
    → Vérifie les mises à jour
    → Redirige vers LoginView ou BottomNavbar
```

### Navigation principale

```
BottomNavbar (PageView)
  → HomePageBlocView (HomePageBloc)
  → LibraryBlocView (LibraryBloc)
  → Search
  → Profile
```

---

## 🧪 Testabilité

### Avantages de l'architecture BLoC

- **Séparation des responsabilités** : Logique métier isolée de l'UI
- **Testabilité** : BLoCs testables indépendamment de l'UI
- **Réactivité** : UI réactive aux changements d'état
- **Prévisibilité** : Flow unidirectionnel (Events → States)

### Tests prévus

- **Unit tests** : Tests des BLoCs et Services
- **Widget tests** : Tests des composants UI
- **Integration tests** : Tests end-to-end (prévu avec `patrol`)

---

## 🚀 Évolutions prévues

### Court terme

- Migration vers `go_router` pour une navigation déclarative
- Activation du thème sombre
- Tests d'intégration

### Moyen terme

- Optimisation de la performance (lazy loading, pagination)
- Internationalisation complète
- Notifications push

### Long terme

- Architecture modulaire avec packages séparés
- Micro-frontends pour certaines features
- Migration vers une architecture plus découplée

---

## 📝 Notes importantes

### Race conditions

- **DetailBloc en factory** : Chaque page de détails a sa propre instance pour éviter les interférences entre pages

### Performance

- **Lazy singletons** : BLoCs créés à la demande pour économiser la mémoire
- **Cache intelligent** : Expiration après 24h, nettoyage automatique
- **Images** : `cached_network_image` pour le cache automatique des images

### Maintenabilité

- **Feature-based** : Chaque feature est indépendante et peut être modifiée sans affecter les autres
- **Services réutilisables** : Code partagé dans `core/` pour éviter la duplication
- **DTOs** : Séparation claire entre les données API et les modèles internes

