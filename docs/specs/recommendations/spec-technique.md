# Spec Technique — recommendations

| Champ         | Valeur              |
|---------------|---------------------|
| Module        | recommendations     |
| Version       | 0.1.0               |
| Date          | 2026-06-04          |
| Source        | Rétro-ingénierie    |

---

## Architecture du module

Le module `recommendations` ne possède pas de BLoC dédié. L'état de chaque vue est géré localement via `StatefulWidget` avec appel direct à `RecommendationService` via `getIt`. Ce choix est documenté en section "Patterns identifiés".

Le module s'articule autour de trois couches :

**Service** (`lib/features/manga/services/recommendation.service.dart`) — placé dans `features/manga/` (pas dans `features/recommendations/`). Gère les deux endpoints REST, le cache offline pour le flux paginé, et les codes HTTP sans `dart:io` (constantes locales).

**Vues** (`lib/features/recommendations/views/`) — deux `StatefulWidget` indépendants, chacun owning son propre état de chargement. Elles partagent le même widget de bascule `RecommendationsSegmentedToggle`.

**Widget de navigation** (`lib/features/recommendations/widgets/`) — `RecommendationsSegmentedToggle` : pill chips custom qui navigue par `go_router` entre `/recommendations` et `/recommendations/by-genre`.

**DTOs utilisés dans ce module :**
- `MangaQuickViewDto` — utilisé pour l'affichage dans les deux vues recommendations
- `MangaRecommendationView` — utilisé uniquement dans la fiche détail manga (`detail_recommendations_section.dart`), pas dans les vues de ce module malgré son nom

---

## Fichiers impactés

| Fichier | Rôle | Lignes |
|---------|------|--------|
| `lib/features/recommendations/views/paginated_recommendations_view.dart` | Vue infinite-scroll (flux unifié par score) | ~175 |
| `lib/features/recommendations/views/recommendations_by_genre_view.dart` | Vue par genre (carrousels segmentés) | ~195 |
| `lib/features/recommendations/widgets/recommendations_segmented_toggle.dart` | Toggle pill "Tout / Par genre" avec navigation go_router | ~132 |
| `lib/features/manga/services/recommendation.service.dart` | Service REST + cache offline | ~112 |
| `lib/features/manga/dto/manga_recommendation_view.dto.dart` | DTO pour recommandations similaires (fiche détail) | ~43 |
| `lib/core/services/offline_cache_service.dart` | Méthodes `cacheRecommendations` / `getCachedRecommendations` | lignes 113-138 |
| `lib/core/service_locator/service_locator.dart` | Enregistrement `RecommendationService` | ligne 55-57 |
| `lib/core/router/app_router.dart` | Routes `/recommendations` et `/recommendations/by-genre` | lignes 258-265 |
| `lib/features/home/helpers/homepage_data_loader.dart` | `loadRecommendations()` : aperçu 5 items pour la home | lignes 42-52 |
| `lib/features/home/bloc/homepage_state.dart` | Champs `recommendations` et `recommendationsByGenre` dans l'état home | - |
| `lib/features/manga/widgets/detail_recommendations_section.dart` | Section recommandations similaires dans la fiche détail | - |
| `lib/features/manga/services/manga.service.dart` | `getMangaRecommendations(muId)` : recommandations similaires fiche détail | lignes 148-204 |
| `test/features/manga/dto/manga_recommendation_view_dto_test.dart` | Tests non-régression du DTO | ~109 |

---

## Schéma BDD

Aucune base de données locale dédiée. Le cache est stocké dans `flutter_secure_storage` via `OfflineCacheService` :

| Clé de stockage | Contenu | Expiration |
|-----------------|---------|-----------|
| `cached_recommendations` | `List<MangaQuickViewDto>` sérialisé en JSON | Aucune expiration explicite visible dans le code — persiste jusqu'au prochain fetch réussi |

La vue par genre (`getRecommendationsByGenre`) n'utilise pas de cache — retour map vide silencieux en cas d'erreur.

---

## API / Endpoints

| Méthode | Route | Description | Auth |
|---------|-------|-------------|------|
| `GET` | `/recommendations?limit=N&offset=N` | Liste paginée par score décroissant | JWT obligatoire |
| `GET` | `/recommendations/by-genre?topGenres=N&perGenre=N` | Map `{genre: [mangas]}` des top genres | JWT obligatoire |
| `GET` | `/mangas/recommendations/:muId` | Recommandations similaires d'un manga (fiche détail) | JWT obligatoire |

**Comportements HTTP notables :**

- `GET /recommendations` : 200 ou 201 → désérialise `List`. 401/403 → liste vide, pas de cache. Autre code → fallback cache si présent, sinon exception. Erreur réseau → fallback cache si présent, sinon liste vide.
- `GET /recommendations/by-genre` : 200 ou 201 → désérialise `Map<String, List>`. Toute autre réponse ou exception → map vide silencieuse (pas de cache, pas de propagation d'erreur à l'UI).
- `GET /mangas/recommendations/:muId` : 200 → liste. 403 → `InvalidCredentialsException` (rethrow). Timeout (18s) → 1 retry après 500ms. Erreur réseau → 1 retry après 500ms puis liste vide.

---

## Patterns identifiés

**StatefulWidget scroll-driven sans BLoC** — choix délibéré documenté dans `discovery.md`. L'état local (`_items`, `_offset`, `_loading`, `_hasMore`) est géré dans `_PaginatedRecommendationsViewState`. La logique de pagination est dans `_loadMore()` et `_onScrollNotification()`. Pas d'injection de dépendances via constructeur : accès direct à `getIt<RecommendationService>()` depuis la vue.

Comparer avec `search.dart` (même pattern StatefulWidget sans BLoC pour les cas simples) et avec `StatsBloc` (BLoC complet pour les lectures-seules avec état plus complexe).

**FutureBuilder pour la vue par genre** — `_byGenreFuture` est un `late Future` initialisé dans `initState`. Le refresh recrée le Future via `setState`. Pattern `FutureBuilder` avec `ConnectionState.done` pour afficher le résultat.

**Responsive intégré** — Grille avec breakpoints dans `_PaginatedRecommendationsViewState` :
- `>= 1200px` : 6 colonnes
- `>= 800px` : 5 colonnes
- `>= 600px` : 4 colonnes
- `< 600px` : 3 colonnes (aspect ratio 0.62)

Vue par genre avec breakpoints séparés :
- `>= 1200px` : centré avec `ConstrainedBox(maxWidth: 1100)` + padding 32
- `>= 600px` : padding 24
- `< 600px` : layout mobile standard

**Service sans `dart:io`** — `RecommendationService` définit les codes HTTP comme constantes locales (`_httpOk = 200`, etc.) pour éviter l'import `dart:io` et rester compatible Web.

**RecommendationsSegmentedToggle** — widget custom pill (pas `SegmentedButton` Material 3). Deux `_SegChip` avec `AnimatedContainer` (durée 150ms). Actif : fond `dsRedSoft` + border primary + icone check. Inactif : fond surface + hairline border. Navigation via `context.go()` go_router.

**Clé de cache sécurisée** — Le cache `cached_recommendations` est stocké dans `flutter_secure_storage` (pas `shared_preferences`). Contient des données utilisateur (liste de mangas personnalisés), justifiant le stockage sécurisé.

**Deux DTOs distincts pour deux contextes** :
- `MangaQuickViewDto` — utilisé dans les vues recommendations (flux paginé + par genre) et dans la home
- `MangaRecommendationView` — utilisé dans la fiche détail uniquement, porte les champs `inLibrary` et `readingStatus` (contexte bibliothèque)

---

## Décisions documentées ici (non-ADR)

**Pas de BLoC pour recommendations** : les vues gérent leur état localement. Justification déduite : les recommandations sont en lecture seule, sans mutation de bibliothèque depuis ces vues, et sans partage d'état entre plusieurs consommateurs. Le pattern StatefulWidget suffit. Si des mutations (ajouter à la bibliothèque depuis la vue) étaient ajoutées, un BLoC deviendrait nécessaire.

**Service dans `features/manga/` et non `features/recommendations/`** : `RecommendationService` et `MangaRecommendationView` sont placés dans `lib/features/manga/` malgré leur usage dans `features/recommendations/`. Probablement un choix historique (le service était utilisé initialement uniquement depuis la fiche détail manga). Ce découpage peut générer de la confusion lors de la maintenance.

**Cache uniquement pour le flux paginé** : la vue par genre n'est pas cachée. Elle retourne silencieusement une map vide en cas d'erreur. Le flux paginé, lui, est caché dans `flutter_secure_storage`. La distinction est fonctionnelle : le flux paginé est le point d'entrée principal (affiché dans la BottomNavBar) et doit résister à une perte de connexion ; la vue par genre est complémentaire.

**Page size fixe à 50** : `_pageSize = 50` est une constante dans `_PaginatedRecommendationsViewState`. La home charge uniquement 5 items (`limit: 5`) via `HomePageDataLoader`. Pas de configuration exposée.

---

## Tests existants

| Fichier | Ce qu'il teste | Statut |
|---------|---------------|--------|
| `test/features/manga/dto/manga_recommendation_view_dto_test.dart` | Non-régression `MangaRecommendationView.fromJson` : null safety muId/title, rating 0/null → "N/A", readingStatus null → readLater, inLibrary absent → false, muId string | Existant |
| Tests `PaginatedRecommendationsView` | Logique de pagination, chargement au scroll, refresh | Absent |
| Tests `RecommendationsByGenreView` | FutureBuilder, filtrage genres vides, refresh | Absent |
| Tests `RecommendationService` | Fallback cache, comportement 401/403, silent errors | Absent |
| Tests `RecommendationsSegmentedToggle` | Navigation go_router, état selected/unselected | Absent |
