# Spec Technique — search

| Champ         | Valeur              |
|---------------|---------------------|
| Module        | search              |
| Version       | 0.1.0               |
| Date          | 2026-06-04          |
| Source        | Rétro-ingénierie    |

## Architecture du module

Le module `search` est délibérément simple : pas de BLoC dédié, pas de cache réseau. Toute la logique de contrôle (debounce, état de la query, historique en mémoire) réside dans le `State` du `StatefulWidget` principal (`_SearchState`). Ce choix est documenté ci-dessous dans la section "Décisions techniques".

Le rendu est découpé en deux sous-widgets privés inlined dans le même fichier :
- `_BrowseOrResults` — switcher conditionnel mode browse / mode résultats.

Les quatre widgets extraits dans `widgets/` sont tous des `StatelessWidget` purs, sans état propre.

### Flux de données

```
Utilisateur frappe
  └─> _onQueryChanged (setState re-render)
        └─> Timer(800ms) → _runSearch()
              └─> _historyService.addSearch(query)   [SharedPreferences]
              └─> setState { _searchedMangas = mangaService.searchForMangas(query) }
                    └─> HomepageMangaList(mangas: Future<List<MangaQuickViewDto>>)
```

### Résolution du service d'historique

`_historyService` est résolu via un getter avec fallback defensif :

```dart
SearchHistoryService get _historyService {
  try {
    return getIt<SearchHistoryService>();
  } catch (_) {
    return SearchHistoryService();
  }
}
```

Cela signifie que `SearchHistoryService` peut ne pas être enregistré dans GetIt ; une instance est créée à la volée si nécessaire. Ce pattern est inhabituel dans le codebase (tous les autres services sont enregistrés dans `service_locator.dart`).

## Fichiers impactés

| Fichier | Rôle | Lignes |
|---------|------|--------|
| `lib/features/search/views/search.dart` | Vue principale (StatefulWidget + _BrowseOrResults) | ~293 |
| `lib/features/search/services/search_history.service.dart` | Persistance historique via SharedPreferences | ~71 |
| `lib/features/search/widgets/search_bar_input.dart` | Barre de recherche pilule (animated container) | ~103 |
| `lib/features/search/widgets/popular_genres_wrap.dart` | Section genres populaires (Wrap de chips) | ~109 |
| `lib/features/search/widgets/search_history_list.dart` | Liste historique + header + row individuelle | ~209 |
| `lib/features/search/widgets/search_header.dart` | Titre "Rechercher" en haut de page | ~35 |

Fichiers en dehors du module impactés :

| Fichier | Rôle | Nature de la dépendance |
|---------|------|------------------------|
| `lib/features/manga/services/manga.service.dart` | Fournit `searchForMangas()` | Consommé en lecture |
| `lib/features/home/widgets/homepage_manga_list.dart` | Rendu des résultats | Réutilisé comme widget |
| `lib/features/manga/dto/manga_quick_view.dto.dart` | DTO résultats de recherche | Type de données partagé |

## Schéma BDD

Pas de base de données. L'historique est stocké dans `SharedPreferences` sous la clé `search_history` (type `List<String>`).

## API / Endpoints

| Méthode | Route | Description | Auth |
|---------|-------|-------------|------|
| POST | `/mangas/search` | Recherche de mangas par pattern | JWT (via HttpService) |

Paramètre body : `{ "search_pattern": "<query>" }`.
Retour : `List<MangaQuickViewDto>` (titre, cover URL, muId, etc.).

## Patterns identifiés

### StatefulWidget sans BLoC (décision assumée)

La vue `Search` est un `StatefulWidget` qui porte l'intégralité de l'état local : debounce timer, query active, Future des résultats, liste d'historique en mémoire. Ce choix a été fait car :
- Pas de cache réseau à gérer (les résultats ne sont pas mis en cache).
- Pas de synchronisation offline (aucune action à rejouer).
- L'état est purement local à la page (non partagé avec d'autres modules).
- Un BLoC aurait introduit des Events/States pour une logique qui se résout en quelques lignes.

Ce pattern est identique à celui utilisé par `recommendations` (voir discovery section 10).

### Debounce manuel via `dart:async.Timer`

Le debounce n'utilise pas de package dédié. Un `Timer` est annulé et recréé à chaque frappe. La valeur est 800 ms dans le code (la discovery mentionnait 500 ms — à valider).

### Historique : MRU (Most Recently Used), limite 10

L'historique est une liste ordonnée du plus récent au plus ancien. Un terme déjà présent est retiré de sa position actuelle puis réinséré en tête (déduplication + repositionnement). La limite de 10 est appliquée à la fois dans `addSearch` et dans `saveHistory`.

### Mise à jour optimiste de l'historique

Les suppressions (individuelle et globale) mettent à jour l'état local (`setState`) immédiatement, avant la persistence asynchrone dans `SharedPreferences`. Les erreurs de persistence sont silencieusement ignorées.

### Genres populaires hardcodés

La liste `_popularGenres` est une constante statique dans `_SearchState` :
`['Shounen', 'Seinen', 'Romance', 'Action', 'Aventure', 'Drama', 'Fantasy', 'Sci-Fi']`.
Ces termes ne sont pas traduits (commentaire dans le code : "termes manga universels"). Il n'existe pas d'endpoint API pour les récupérer dynamiquement.

### Responsive layout

La page utilise `LayoutBuilder` pour détecter les largeurs >= 1200 px (desktop). Dans ce cas, le contenu est centré et contraint à `maxWidth: 720`. En dessous, le contenu prend toute la largeur.

### Design System V1 "Refined Classic"

Tous les widgets utilisent les tokens du design system :
- `AppColors.dsBgDark / dsBgLight` — fond de page
- `AppColors.dsSurfaceDark / Colors.white` — fond des cards
- `AppColors.dsHairline(brightness)` — bordure hairline
- `AppColors.dsText2/3(brightness)` — niveaux de texte
- `AppColors.dsBorder(brightness)` — bordure chips
- `AppSpacing.m, s, l` — espacements
- `scheme.primary` — couleur bordure barre active et bouton "Effacer"

La barre de recherche utilise un `AnimatedContainer` (durée 150 ms) pour la transition de la bordure hairline vers la bordure primaire.

## Tests existants

| Fichier | Ce qu'il teste | Statut |
|---------|---------------|--------|
| Aucun | — | Absent |

Le module `search` n'a pas de fichier de test dédié dans le projet (7 fichiers de tests référencés dans la discovery, aucun pour search).

## Points de dette technique

- `SearchHistoryService` n'est pas enregistré dans `service_locator.dart` (ou de manière incertaine), ce qui force le fallback defensif dans `_historyService`. À vérifier et aligner avec le pattern GetIt du reste du codebase.
- La valeur du debounce (800 ms dans le code vs 500 ms dans la discovery) doit être arbitrée.
- Absence de gestion d'erreur explicite pour les rejets du `Future` retourné par `searchForMangas` : délégué implicitement à `HomepageMangaList`.
- Pas de comportement offline pour les résultats de recherche (pas de cache). Cohérent avec le choix d'architecture actuel mais à documenter si la feature doit évoluer.
- Les genres populaires hardcodés ne peuvent pas être mis à jour sans relivraison de l'app.
