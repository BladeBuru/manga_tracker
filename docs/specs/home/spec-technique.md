# Spec Technique — home

| Champ         | Valeur              |
|---------------|---------------------|
| Module        | home                |
| Version       | 0.1.0               |
| Date          | 2026-06-04          |
| Source        | Rétro-ingénierie    |

## Architecture du module

Le module `home` remplit deux responsabilités distinctes.

**Shell de navigation (`BottomNavbar`)** : `Scaffold` racine contenant un `PageView` à 4 pages et une `BottomNavigationBar`. C'est ici que sont amorcées les responsabilités transverses au démarrage de l'app : vérification RGPD, démarrage du polling `NotificationCountsService`. Les BLoCs `HomePageBloc` et `LibraryBloc` sont fournis via `BlocProvider` directement dans le `PageView`.

**Page d'accueil (`HomePageBlocView`)** : vue BLoC réactive. L'event `LoadHomePage` est dispatché dans `initState`. Un `BlocConsumer` gère les redirections auth (dans `listener`) et le rendu (dans `builder`). La vue est structurée en `CustomScrollView` avec `SliverList` pour le header/filtres et `SliverList` pour la liste filtrée.

**BLoC (`HomePageBloc`)** : lazy singleton GetIt. Orchestre le chargement des 4 sections en parallèle. Délègue tous les fetchers à `HomePageDataLoader` pour respecter la limite de 200 lignes. Contient la logique stale-while-revalidate : émission du cache avant le `Future.wait`, puis remplacement par les données fraîches.

**Helper (`HomePageDataLoader`)** : classe non-BLoC, non-singleton, instanciée directement dans `HomePageBloc`. Encapsule les appels `CacheHelperService.loadSearchResults` pour chaque section. Contient également la logique de re-fetch forcé sur `emailVerified == false`.

## Fichiers impactés

| Fichier | Rôle | Lignes |
|---------|------|--------|
| `lib/features/home/bloc/homepage_bloc.dart` | BLoC principal — orchestre le chargement et les états | ~161 |
| `lib/features/home/bloc/homepage_event.dart` | Définition des 6 events | ~39 |
| `lib/features/home/bloc/homepage_state.dart` | Définition des 4 états (Initial, Loading, Loaded, Error, ActionInProgress) | ~135 |
| `lib/features/home/helpers/homepage_data_loader.dart` | Fetchers réseau + cache + `HomeCacheSnapshot` | ~145 |
| `lib/features/home/views/homepage_bloc_view.dart` | Vue principale BLoC (CustomScrollView + filtres + sliver) | ~386 |
| `lib/features/home/views/bottom_navbar.dart` | Shell de navigation 4 tabs + RGPD consent + badge notifs | ~322 |
| `lib/features/home/views/home_page.dart` | Vue legacy StatefulWidget + FutureBuilder (probablement non utilisée) | ~263 |
| `lib/features/home/widgets/homepage_manga_list.dart` | Widget `FutureBuilder` wrappant une liste de `MangaRow` | ~64 |

## Schéma BDD

Pas de base de données locale dédiée au module home. Les données transitent par `CacheHelperService` qui utilise `shared_preferences` (clés JSON) :

| Clé cache | Données | Expiration |
|-----------|---------|-----------|
| `cached_search_popular` | Liste `MangaQuickViewDto` populaires | 24h (géré par `CacheHelperService`) |
| `cached_search_new` | Liste `MangaQuickViewDto` nouveautés | 24h |
| `cached_search_trending` | Liste `MangaQuickViewDto` tendances | 24h |

Les recommandations ne sont pas mises en cache dans `HomeCacheSnapshot` (retour nul en offline).

## API / Endpoints consommés

| Méthode | Route (relative à `MT_API_URL`) | Description | Auth |
|---------|--------------------------------|-------------|------|
| GET | `/api/mangas/trending` | Mangas en tendance | JWT |
| GET | `/api/mangas/popular` | Mangas populaires | JWT |
| GET | `/api/mangas/new` | Nouveaux mangas | JWT |
| GET | `/api/users/me` | Informations utilisateur connecté | JWT |
| GET | `/api/recommendations?limit=5` | Recommandations personnalisées | JWT |
| GET | `/api/gdpr/consent-status` | Statut du consentement RGPD | JWT |
| POST | `/api/gdpr/consent` | Enregistrer le consentement | JWT |

## États BLoC

| État | Quand | Champs notables |
|------|-------|-----------------|
| `HomePageInitial` | État par défaut au démarrage | — |
| `HomePageLoading` | Chargement initial sans cache | — |
| `HomePageLoaded` | Données disponibles (fraîches ou stale) | `isStale`, `isOffline`, `pendingActions`, `recommendations`, `recommendationsByGenre` |
| `HomePageError` | Erreur réseau + pas de cache | `message`, `isOffline`, champs `cached*` |
| `HomePageActionInProgress` | Rechargement d'une section isolée | `action` (label texte), données actuelles |

## Patterns identifiés

- **Stale-while-revalidate** : `HomeCacheSnapshot.toLoaded(stale: true)` émis avant le `Future.wait`, puis remplacé par les données fraîches. Permet un affichage instantané au démarrage.
- **Chargement parallèle** : `Future.wait([loadPopular, loadNew, loadTrending, loadUserInfo])` — les 4 requêtes s'exécutent en parallèle. Les recommandations sont chargées séparément après (graceful degradation silencieuse en cas d'erreur).
- **Extraction helper** : `HomePageDataLoader` extraite du BLoC pour respecter la limite de 200 lignes. Non-singleton, instanciée dans le constructeur du BLoC.
- **`HomeCacheSnapshot`** : objet value immuable représentant un snapshot du cache, avec méthode `toLoaded()` pour convertir directement en état BLoC.
- **Lazy singleton BLoC** : `HomePageBloc` enregistré en `registerLazySingleton` dans GetIt — une seule instance partagée pendant toute la session.
- **`BlocConsumer`** : séparation entre `listener` (effets de bord — redirection auth) et `builder` (rendu UI).
- **`LayoutBuilder` responsive** : padding horizontal adaptatif selon `constraints.maxWidth` (< 600 : 25dp, 600-1200 : 25dp, > 1200 : centrage avec max-width 1100).
- **`_section<T>()` factorisé** : handler générique dans le BLoC pour les rechargements de section isolés — émet `ActionInProgress`, fetch, puis `copyWith` ou `HomePageError`.
- **Re-fetch `emailVerified`** : si le cache dit `emailVerified == false`, un `forceRefresh: true` est tenté silencieusement pour détecter une vérification externe.

## Décisions notables documentées ici (non-ADR)

- **`home_page.dart` coexiste avec `homepage_bloc_view.dart`** : `home_page.dart` est un `StatefulWidget` legacy avec `FutureBuilder` et gestion connectivité locale. Il n'est pas référencé dans `BottomNavbar` et semble être une version antérieure non nettoyée. Dette technique : à supprimer ou confirmer l'usage.
- **`HomepageMangaList` accepte un `Future`** : ce widget wrapping `FutureBuilder` est utilisé à la fois dans `home_page.dart` (legacy) et dans `search.dart`. Dans `homepage_bloc_view.dart` (version BLoC), la liste est construite directement via `SliverList` sans `HomepageMangaList`.
- **`ConnectivitySubscription` dans `HomePageBloc`** : le BLoC s'abonne au stream de connectivité mais ne dispatch aucun event en réaction (le listener est vide `(_) {}`). La reconnexion automatique n'est gérée que dans `home_page.dart` (version legacy).
- **Hardcoding couleur dans `BottomNavbar`** : `unselectedColor = const Color(0xffb8b8d2)` est une couleur hardcodée, pas un token `AppColors`. Dette design system.
- **`FilterButton` avec état local** : `indexButtonBar` est un état local `StatefulWidget` dans `HomePageBlocView` — ne passe pas par le BLoC. Cohérent avec le pattern (état purement UI).

## Tests existants

| Fichier | Ce qu'il teste | Statut |
|---------|---------------|--------|
| Aucun fichier de test identifié pour la feature home | — | Absent |

Le module home n'a pas de tests unitaires (BLoC) ni de widget tests identifiés dans les 7 fichiers de tests existants du projet.
