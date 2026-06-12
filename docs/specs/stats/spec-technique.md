# Spec Technique — stats

| Champ         | Valeur              |
|---------------|---------------------|
| Module        | stats               |
| Version       | 0.1.0               |
| Date          | 2026-06-04          |
| Source        | Rétro-ingénierie    |

---

## Architecture du module

Le module stats suit l'architecture feature standard BLoC du projet :

```
StatsView (StatelessWidget)
  └── BlocProvider<StatsBloc>   ← crée le BLoC et émet LoadStats au mount
        └── _StatsScaffold
              └── BlocBuilder<StatsBloc, StatsState>
                    ├── StatsLoading/StatsInitial → CircularProgressIndicator
                    ├── StatsError              → AppErrorState (retry → LoadStats)
                    └── StatsLoaded             → RefreshIndicator
                          └── _StatsContent (LayoutBuilder responsive)
                                ├── StatsOfflineBanner  (si isOffline)
                                ├── StatsHeroCard
                                ├── StatsOverviewSection
                                ├── StatsStatusSection
                                └── StatsGenresSection
```

`StatsBloc` est **instancié localement** dans `StatsView` via `BlocProvider.create` (pas enregistré dans GetIt). Chaque ouverture de la page crée une nouvelle instance — comportement identique à un factory implicite. Le BLoC injecte lui-même ses dépendances via `getIt<StatsService>()` dans son constructeur.

`StatsService` accède directement à GetIt pour résoudre `HttpService` et `StorageService`. Il n'est pas injecté via le constructeur du BLoC.

---

## Fichiers impactés

| Fichier | Rôle | Lignes |
|---------|------|--------|
| `lib/features/stats/bloc/stats_bloc.dart` | BLoC principal — gestion des events LoadStats/RefreshStats, mapping service → states | ~51 |
| `lib/features/stats/bloc/stats_event.dart` | Events : `LoadStats`, `RefreshStats` | ~17 |
| `lib/features/stats/bloc/stats_state.dart` | States : `StatsInitial`, `StatsLoading`, `StatsLoaded`, `StatsError` | ~32 |
| `lib/features/stats/services/stats.service.dart` | Fetch `/user/stats` + cache 1h + fallback stale | ~100 |
| `lib/features/stats/dto/user_stats.dto.dart` | DTO miroir de l'API — désérialisation JSON + sérialisation cache | ~76 |
| `lib/features/stats/views/stats_view.dart` | Vue principale — Scaffold + BlocBuilder + pull-to-refresh | ~148 |
| `lib/features/stats/widgets/stats_hero_card.dart` | Carte hero (ancienneté + badge total mangas) | ~112 |
| `lib/features/stats/widgets/stats_overview_section.dart` | Section chiffres clés (totalMangas, chapitres, temps, complétion, lastRead) | ~78 |
| `lib/features/stats/widgets/stats_status_section.dart` | Section répartition par statut (ordre fixe + forward-compat) | ~109 |
| `lib/features/stats/widgets/stats_genres_section.dart` | Section top genres (AppChip wrap) | ~49 |
| `lib/features/stats/widgets/stats_offline_banner.dart` | Pill discret mode hors-ligne | ~53 |
| `lib/features/stats/widgets/stats_section_row.dart` | Row label/valeur avec PastelTile (partagé entre sections overview et status) | ~72 |

---

## Schéma BDD

Pas de base de données embarquée. Le cache est stocké dans `flutter_secure_storage` (Keystore Android / Keychain iOS / WebCrypto Web) via `StorageService` :

| Clé secure storage | Contenu | TTL |
|-------------------|---------|-----|
| `cached_user_stats` | JSON sérialisé de `UserStatsDto` | 1h (contrôlé par la clé timestamp) |
| `cached_user_stats_at` | ISO 8601 timestamp de la dernière écriture | — |

---

## API / Endpoints

| Méthode | Route | Description | Auth |
|---------|-------|-------------|------|
| GET | `/user/stats` | Retourne les statistiques agrégées de l'utilisateur courant | JWT Bearer (via `HttpService.getWithAuthTokens`) |

**Réponse attendue (champs mappés dans `UserStatsDto`)** :

| Champ JSON | Type Dart | Notes |
|-----------|-----------|-------|
| `mangasByStatus` | `Map<String, int>` | Clés : `readLater`, `reading`, `caughtUp`, `completed` — garanties non-null à 0 par l'API |
| `totalChaptersRead` | `int` | Défaut 0 si absent |
| `estimatedReadingTimeMinutes` | `int` | Calculé côté API (× 4 min/chapitre). Défaut 0 |
| `topGenres` | `List<String>` | Top 5 genres. Défaut liste vide |
| `lastReadAt` | `DateTime?` | Nullable — null si biblio vide |
| `completionRate` | `double` | Valeur 0–1. Défaut 0.0 |
| `accountCreatedAt` | `DateTime` | Défaut `DateTime.now()` si parsing échoue |
| `totalMangas` | `int` | Défaut 0 |

---

## Patterns identifiés

- **BLoC lecture seule** : `StatsBloc` ne contient aucun event de mutation. Le seul event de mutation possible (`RefreshStats`) est une invalidation de cache + re-fetch, pas une mutation de données utilisateur.
- **Cache stale-while-never-revalidate** (variante) : contrairement à `HomePageBloc` et `LibraryBloc` qui émettent d'abord le cache stale puis le réseau en parallèle, `StatsBloc` attend le réseau (ou le cache s'il est frais) avant d'émettre `StatsLoaded`. Le stale n'est servi qu'en cas d'erreur réseau — il ne fait pas de double émission.
- **BLoC instancié localement (non enregistré dans GetIt)** : `StatsBloc` est créé dans `StatsView.build()` via `BlocProvider.create`. Son enregistrement dans `service_locator.dart` n'est pas nécessaire et non présent.
- **Dépendances résolues en dur via getIt** : `StatsBloc` et `StatsService` appellent `getIt<...>()` directement dans leur corps — pas d'injection par constructeur. Ce pattern diffère des BLoCs seniors du projet (`LibraryBloc`, `HomePageBloc`) qui reçoivent leurs services via constructeur. Cela rend le BLoC difficile à tester unitairement sans GetIt configuré.
- **Forward-compat sur les statuts** : `StatsStatusSection` affiche les statuts connus dans l'ordre fixe et itère en dernier sur les entrées inconnues de `mangasByStatus`, permettant à l'API d'ajouter de nouveaux statuts sans plantage client.
- **Partage de composant cross-feature** : `StatsOverviewSection` et `StatsStatusSection` importent `ProfileEditSection` depuis `lib/features/profile/widgets/profile_edit_sections.dart` pour le layout des sections — couplage cross-feature assumé pour la cohérence visuelle.
- **Formatage du temps de lecture** : la logique de formatage (minutes → heures+minutes → jours+heures) est implémentée dans `StatsOverviewSection._formatMinutes()`, privé au widget. Les seuils sont 60 min et 24 h.
- **Calcul du nombre de mois** : `StatsHeroCard._monthsSinceJoin` calcule la différence en mois entre `accountCreatedAt` et `DateTime.now()`, avec correction si le jour courant est antérieur au jour de création dans le mois.

---

## Tests existants

| Fichier | Ce qu'il teste | Statut |
|---------|---------------|--------|
| — | Aucun test n'existe pour la feature stats | Absent |

La feature stats n'est pas couverte par les tests automatisés. Les candidats naturels seraient un test unitaire de `StatsService` (mock HttpService + StorageService) et un test du BLoC (mock StatsService).

---

## Décisions techniques documentées (candidats ADR rejetés)

Les décisions suivantes ont été identifiées et rejetées par la politique ADR v2.3.0. Elles sont documentées ici.

### Cache 1h via flutter_secure_storage

`StatsService` stocke le JSON sérialisé de `UserStatsDto` dans `flutter_secure_storage` avec un timestamp séparé. Le TTL est de 1 heure. Ce choix diffère des autres services du projet qui utilisent `OfflineCacheService` / `CacheHelperService` pour la persistance JSON. La raison probable est la sensibilité des données de profil (via `flutter_secure_storage` plutôt que `shared_preferences`).

Rejet ADR : AP-2 (configuration d'un mécanisme de cache confiné à un seul service).

### Calcul des statistiques côté serveur uniquement

Le DTO ne contient aucune méthode de calcul : toutes les valeurs agrégées (`completionRate`, `estimatedReadingTimeMinutes`, `totalChaptersRead`, etc.) sont calculées par l'API et retournées prêtes à l'affichage. Le commentaire du DTO indique explicitement « pas de logique d'agrégation côté Flutter pour garantir la cohérence offline (cache 1h) ».

Rejet ADR : Q3 = NON — la décision est confinée au module stats, elle ne contraint pas d'autres specs.

### BLoC lecture seule sans émission stale-then-network

Contrairement aux BLoCs `HomePageBloc` et `LibraryBloc` qui émettent d'abord l'état stale (chargement optimiste) avant de fetcher le réseau, `StatsBloc` émet `StatsLoading` puis attend la réponse complète avant d'émettre `StatsLoaded`. Le cache n'est servi de manière proactive que lorsqu'il est frais (< 1h) — il bypasse le loading entièrement. En cas d'erreur réseau, le stale est servi silencieusement (sans flag `isOffline = true` explicite dans le fallback actuel du service).

Rejet ADR : Q3 = NON — impact confiné au module stats.

### Invalidation manuelle du cache après mutations bibliothèque

`StatsService.invalidateCache()` est documenté comme devant être appelé après les actions qui affectent les stats (add/remove biblio, update chapter, change status). Ce mécanisme d'invalidation est transverse (concerne `LibraryBloc`, `DetailBloc`) mais constitue une heuristique d'implémentation (quand et comment invalider) — pas un invariant métier ou de sécurité.

Rejet ADR : AP-3 (heuristique d'implémentation).
