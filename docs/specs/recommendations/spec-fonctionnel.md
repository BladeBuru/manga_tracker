# Spec Fonctionnelle — recommendations [DRAFT — à valider par le dev]

| Champ      | Valeur              |
|------------|---------------------|
| Module     | recommendations     |
| Version    | 0.1.0               |
| Date       | 2026-06-04          |
| Auteur     | retro-documenter    |
| Statut     | DRAFT               |
| Source     | Rétro-ingénierie    |

> **[DRAFT — à valider par le dev]** Cette spec a été générée par rétro-ingénierie
> à partir du code existant. Elle doit être relue et validée par un développeur
> qui connaît le contexte métier.

---

## ADRs

Aucun ADR créé pour cette feature — toutes les décisions candidates ont été rejetées par la politique ADR v2.3.0 (voir Rapport ADR en fin de session). Les décisions techniques sont documentées dans `spec-technique.md`.

---

## Contexte et objectif

Le module recommendations expose à l'utilisateur connecté une liste de mangas qu'il n'a pas encore dans sa bibliothèque mais qui correspondent à ses goûts, calculés côté API à partir des genres et titres déjà sauvegardés. L'objectif est de favoriser la découverte de nouveaux mangas sans effort de recherche manuelle.

Le module est présenté sous deux angles complémentaires :
- un flux unifié par score décroissant (infinite scroll) accessible depuis la BottomNavBar via `/recommendations` ;
- une vue par genre (carrousels segmentés) accessible depuis la home ("Voir plus par genre") et depuis le toggle au sein de la vue principale via `/recommendations/by-genre`.

Un aperçu de 5 recommandations personnalisées est également intégré dans la page d'accueil (`HomePageBloc` / `HomepageBlocView`), depuis laquelle l'utilisateur peut accéder aux deux vues dédiées.

Les recommandations similaires entre mangas (section "Vous pourriez aussi aimer" de la fiche détail) sont distinctes et gérées par `MangaService.getMangaRecommendations`, non par ce module.

---

## Règles métier (déduites du code)

1. Les recommandations sont personnalisées par utilisateur : les deux endpoints reqièrent un JWT valide. En cas de réponse 401 ou 403, la liste retournée est vide sans cache (évite la fuite de données entre utilisateurs).
2. La vue paginée charge les recommandations par pages de 50 items. Le chargement suivant est déclenché automatiquement quand il reste moins de 500 px de contenu en dessous de la position de scroll actuelle.
3. La pagination s'arrête dès que l'API renvoie une page incomplète (`length < pageSize`). Il n'y a pas de nombre total de pages communiqué par l'API.
4. La vue par genre demande les 5 genres les plus représentés dans la bibliothèque, avec 10 mangas par genre au maximum (`topGenres=5, perGenre=10`).
5. Les genres vides (liste vide côté API) sont filtrés côté client et ne génèrent pas de section.
6. Un `RefreshIndicator` (pull-to-refresh) est disponible sur les deux vues. La vue paginée remet le cache local à zéro et recommence depuis l'offset 0.
7. La vue paginée met en cache les recommandations dans `flutter_secure_storage` (clé `cached_recommendations`) après chaque fetch réussi. En cas d'échec réseau, le cache est utilisé en fallback. En cas de 401/403, le cache n'est pas touché.
8. La vue par genre ne dispose pas de cache offline : en cas d'erreur réseau, elle retourne une map vide et la section est masquée silencieusement.
9. Le rating `0` ou `null` est normalisé en `"N/A"` côté DTO et non affiché sur la carte manga.
10. L'utilisateur ne peut pas interagir avec les recommandations (pas d'ajout à la bibliothèque depuis ces vues) — elles sont en lecture seule et naviguent vers la fiche détail via `MangaCard`.

---

## Cas d'usage (déduits)

### CU-001 — Découvrir des recommandations personnalisées (flux unifié)

L'utilisateur ouvre la page "Recommandations" (BottomNavBar ou bouton "Voir plus" depuis la home). La première page (50 items) se charge immédiatement. L'utilisateur scrolle : à moins de 500 px du bas, la page suivante se charge en arrière-plan. Une icône de chargement apparaît en bas de la grille. La pagination s'arrête quand l'API renvoie moins de 50 items. L'utilisateur peut tap sur un manga pour accéder à sa fiche détail.

### CU-002 — Découvrir des recommandations par genre

L'utilisateur bascule sur l'onglet "Par genre" via le `RecommendationsSegmentedToggle`. La page charge en une seule requête les 5 genres les plus présents dans sa bibliothèque avec 10 mangas chacun. Chaque genre forme une section avec un titre en majuscules et un carrousel horizontal de `MangaCard`. L'utilisateur peut scroller horizontalement par genre ou verticalement pour parcourir tous les genres.

### CU-003 — Rafraîchir les recommandations

L'utilisateur effectue un pull-to-refresh sur l'une ou l'autre des vues. La vue paginée repart depuis l'offset 0 (réinitialisation complète). La vue par genre relance la requête `getRecommendationsByGenre`. Le contenu est remplacé par les nouvelles données.

### CU-004 — État vide (bibliothèque insuffisante)

Si la bibliothèque de l'utilisateur est vide ou trop peu fournie, l'API renvoie une liste vide. La vue paginée affiche un message "Pas encore de recommandations pour vous." La vue par genre affiche "Pas encore de recommandations. Ajoutez des mangas à votre bibliothèque pour en obtenir."

### CU-005 — Mode hors-ligne (vue paginée uniquement)

Si l'API est injoignable lors du premier chargement, `RecommendationService` tente de lire le cache `cached_recommendations`. Si des données sont présentes, elles sont affichées. Si le cache est vide, la liste retournée est vide et la vue affiche l'état vide. La vue par genre retourne une map vide silencieusement.

### CU-006 — Aperçu sur la page d'accueil

La page d'accueil charge en parallèle (`Future.wait`) les 5 premières recommandations personnalisées via `HomePageDataLoader.loadRecommendations()`. Ces 5 items sont affichés dans une section dédiée de la home avec un bouton "Voir plus" naviguant vers `/recommendations`.

---

## Dépendances

- `RecommendationService` (singleton, `lib/features/manga/services/recommendation.service.dart`) — accès aux deux endpoints API
- `HttpService` (core) — requêtes authentifiées avec JWT
- `OfflineCacheService` (core) — cache offline pour les recommandations paginées
- `MangaCard` widget (`lib/features/manga/widgets/manga_card.dart`) — affichage des cartes manga
- `go_router` — navigation entre `/recommendations` et `/recommendations/by-genre`
- `AppSpacing`, `AppColors` (design system) — tokens de style
- `HomePageBloc` + `HomePageDataLoader` — consomment `RecommendationService` pour l'aperçu home
- `MangaService.getMangaRecommendations` — recommandations similaires dans la fiche détail (feature manga, distincte)

---

## Zones d'incertitude

> Les points suivants n'ont pas pu être déterminés par le code seul :

- La durée de vie du cache offline `cached_recommendations` n'est pas explicitement bornée dans le code : il n'y a pas d'expiration TTL visible dans `OfflineCacheService` pour cette clé. Il faudrait vérifier si une expiration globale s'applique ou si le cache est persistant jusqu'au prochain fetch réussi.
- Le comportement exact de l'API quand l'utilisateur a une bibliothèque non vide mais avec peu de genres distincts : est-ce que `topGenres=5` retourne moins de 5 genres ou toujours 5 (certains répétés) ?
- La page `/recommendations` est-elle dans la BottomNavBar ou accessible uniquement depuis la home et le toggle ? Le code de `bottom_navbar.dart` n'a pas été examiné pour confirmer.
- Le `MangaRecommendationView` DTO (dans `lib/features/manga/dto/`) est utilisé pour les recommandations similaires dans la fiche détail mais pas dans les vues `recommendations/`. Ce DTO porte un champ `inLibrary` et `readingStatus` qui ne semblent pas utilisés dans le contexte des vues dédiées. La séparation intentionnelle entre les deux DTOs mériterait confirmation.
