# RETRO-005 — Stratégie cache stale-while-revalidate sur la HomePage

| Champ      | Valeur              |
|------------|---------------------|
| Statut     | Documenté (rétro)   |
| Date       | 2026-06-04          |
| Source     | Rétro-ingénierie    |
| Features   | home, library, manga |

> **Consolidation (2026-06-04)** : cet ADR fusionne l'ancien RETRO-014 (découvert côté `library`) qui décrivait le même pattern stale-while-revalidate. RETRO-014 a été retiré ; cet ADR est désormais l'ADR canonique de la stratégie de cache pour `HomePageBloc`, `LibraryBloc` et `DetailBloc`.

## Justification (politique ADR v2.3.0)

| Champ | Valeur |
|-------|--------|
| Catégorie | DB-STRATEGY |
| Q1 — Coût de revert > 1j ? | OUI — inverter ce pattern nécessite de modifier `HomePageBloc`, `LibraryBloc`, `DetailBloc` et `CacheHelperService` (4+ fichiers, pattern transverse) ; le risque de régression UX offline est élevé |
| Q2 — Non-déductible du code ? | OUI — `pubspec.yaml` liste `shared_preferences` mais ne révèle pas le choix d'émettre le cache *avant* le réseau (stale-first) plutôt qu'après (cache-on-error) ; c'est une intention architecturale invisible dans les configs |
| Q3 — Impact transverse (≥ 2 specs) ? | OUI — home (HomePageBloc), library (LibraryBloc) et manga/detail (DetailBloc) appliquent tous ce pattern ; specs home, library et manga impactées |
| Q4 — Casse un invariant si ignoré ? | OUI — supprimer l'émission stale ferait disparaître l'affichage instantané au démarrage et casserait l'UX offline (l'app afficherait un spinner blanc à chaque ouverture même avec un cache valide) |

> Validé contre la politique `.claude/rules/06-adr-policy.md`.

## Contexte

L'application charge ses données depuis une API REST distante. Sur mobile, la latence réseau et les conditions offline sont fréquentes. Le besoin d'afficher immédiatement des données à l'ouverture de l'app (cold start UX) a conduit à adopter une stratégie de lecture du cache avant de tenter le réseau, plutôt que d'attendre la réponse réseau ou de n'utiliser le cache qu'en cas d'échec.

## Décision identifiée

Au chargement initial (`LoadHomePage`), `HomePageBloc` :

1. Appelle `HomePageDataLoader.snapshotCache()` pour lire le cache immédiatement.
2. Si le cache contient des données, émet `HomePageLoaded(isStale: true)` — l'utilisateur voit des données instantanément.
3. Lance ensuite `Future.wait([loadPopular, loadNew, loadTrending, loadUserInfo])` en arrière-plan.
4. Remplace l'état par `HomePageLoaded(isStale: false)` avec les données fraîches.
5. En cas d'erreur réseau, émet `HomePageLoaded(isOffline: true, isStale: true)` depuis le cache ou `HomePageError(isOffline: true)` si le cache est vide.

Le même pattern est appliqué par `CacheHelperService.loadSearchResults()` (utilisé dans `HomePageDataLoader`) qui tente le réseau puis persiste en cache — mais sans bloquer sur le cache d'abord. Le comportement stale-first est donc piloté explicitement par `HomePageBloc` via `snapshotCache()`, pas par `CacheHelperService` seul.

**Application côté `library`** (`LibraryBloc._onLoadLibrary`) — même séquence : si cache présent → `LibraryLoaded(stale: true)` immédiat ; sinon `LibraryLoading()` ; puis réseau → `LibraryLoaded(stale: false)` ou, en échec réseau, `LibraryLoaded(isOffline: true, stale: true)` depuis le cache (ou `LibraryError(isOffline: true)` si cache vide). L'état porte un champ `isStale: bool` exploitable par les widgets.

## Conséquences observées

### Positives
- Affichage instantané au démarrage : pas de spinner si un cache existe (cold start UX fluide).
- Mode offline fonctionnel : l'utilisateur peut parcourir les données précédemment chargées sans connexion.
- Pas de double état "loading + données" : le passage stale → frais est transparent pour l'utilisateur (les données se mettent à jour en place).

### Négatives / Dette
- `HomePageLoaded.isStale` est présent dans l'état mais la vue ne l'utilise pas pour afficher un indicateur visuel "données en cours de rafraîchissement" — les données stale peuvent passer inaperçues.
- Les recommandations (`RecommendationService`) ne sont pas incluses dans `HomeCacheSnapshot` : elles ne bénéficient pas du stale-while-revalidate et retournent une liste vide en offline.
- L'abonnement `ConnectivityService` dans `HomePageBloc` est présent mais le listener est vide — la reconnexion automatique n'est pas câblée dans la version BLoC (uniquement dans `home_page.dart` legacy).
- Côté `library` : double émission d'état (`stale` puis `fresh`) pour un seul chargement → risque de rebuild Flutter double si les widgets internes ne sont pas `const`. De plus, `_enrichWithNewChapters` est appelé deux fois (sur le cache puis sur les données fraîches), générant des appels `NewChapterService.hasNewChapters` en double à chaque chargement.

## Recommandation

Garder. Ce pattern est la bonne décision pour une app mobile offline-first. Points à compléter :
- Câbler la reconnexion automatique dans `HomePageBlocView` (écoute `ConnectivityBloc` ou event `RefreshHomePage` au retour en ligne).
- Envisager d'inclure les recommandations dans `HomeCacheSnapshot` pour les rendre disponibles offline.
- Optionnel : afficher un indicateur visuel subtil quand `isStale == true` (ex. shimmer sur les titres de sections).
