# Spec Fonctionnelle — stats [DRAFT — à valider par le dev]

| Champ      | Valeur              |
|------------|---------------------|
| Module     | stats               |
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

Aucun ADR RETRO n'a été créé pour cette feature. Tous les candidats ont été rejetés par la politique ADR v2.3.0 (voir rapport de rejets en fin de spec-technique.md).

---

## Contexte et objectif

Le module stats expose un tableau de bord de lecture personnel : l'utilisateur connecté peut voir en un coup d'œil son ancienneté sur la plateforme, le volume de sa bibliothèque, ses chapitres lus, son temps de lecture estimé, sa répartition par statut et ses genres préférés. La page est en lecture seule — aucune action de mutation n'est proposée à l'utilisateur sur cet écran. Les données sont calculées côté serveur (endpoint `/user/stats`) et mises en cache localement pendant 1 heure pour éviter des appels réseau répétés.

---

## Règles métier (déduites du code)

1. Toutes les valeurs numériques (totalChaptersRead, totalMangas, etc.) sont calculées côté API et retournées telles quelles par le client — aucune agrégation n'est faite dans Flutter.
2. Le cache local a une durée de vie d'exactement 1 heure. Passé ce délai, un nouveau fetch réseau est déclenché automatiquement.
3. En cas d'échec réseau, le service sert le cache même s'il est expiré (stale fallback), pour éviter un écran vide. Si aucun cache n'est disponible, une erreur explicite "hors ligne" est émise.
4. L'utilisateur peut forcer un rafraîchissement via le geste pull-to-refresh, qui invalide le cache puis re-fetche le réseau.
5. La carte hero affiche le nombre de mois depuis la date de création du compte (calcul client à partir de `accountCreatedAt` retourné par l'API).
6. Le temps de lecture estimé est calculé côté API à raison de 4 minutes par chapitre (`estimatedReadingTimeMinutes`). L'affichage client formate en minutes, heures+minutes, ou jours+heures selon la magnitude.
7. La liste des statuts est affichée dans un ordre fixe défini côté client : `reading` → `caughtUp` → `readLater` → `completed`. Les statuts inconnus (forward-compat) sont affichés en dernier.
8. Les genres préférés correspondent au top 5 retourné par l'API (champ `topGenres`) ; aucun tri supplémentaire n'est appliqué côté client.
9. Le taux de complétion (`completionRate`) est une valeur 0–1 fournie par l'API, affichée en pourcentage arrondi à l'entier.
10. Si la bibliothèque est vide (`mangasByStatus` toutes à 0), la section "Mangas par statut" affiche un état vide au lieu des rows de données.
11. La page est responsive : le padding horizontal passe de 16 px (< 600 px) à 32 px (≥ 600 px).
12. Un bandeau offline discret (pill) s'affiche quand les données proviennent du cache stale (`isOffline = true`).

---

## Cas d'usage (déduits)

### CU-001 — Consulter ses statistiques de lecture

**Acteur** : utilisateur authentifié.

**Flux principal** :
1. L'utilisateur navigue sur l'onglet "Statistiques" (BottomNav).
2. `StatsView` crée un `StatsBloc` et émet `LoadStats`.
3. Le BLoC délègue à `StatsService.getUserStats()`.
4. Si le cache est frais (< 1h) : les données sont retournées depuis `flutter_secure_storage`, état `StatsLoaded` émis.
5. Sinon : fetch réseau sur `/user/stats`, cache mis à jour, état `StatsLoaded` émis.
6. La vue affiche : carte hero (ancienneté + badge total mangas), section vue d'ensemble, section par statut, section genres.

**Variante offline — cache disponible** :
- Le fetch réseau échoue (SocketException).
- `StatsService` sert le cache stale.
- `StatsLoaded(isOffline: true)` émis.
- La vue affiche un bandeau pill "Mode hors ligne".

**Variante offline — sans cache** :
- Le fetch réseau échoue et aucun cache n'est disponible.
- `StatsError('Hors ligne et aucune statistique en cache.')` émis.
- `AppErrorState` affiché avec bouton "Réessayer".

### CU-002 — Rafraîchir manuellement les statistiques

**Acteur** : utilisateur authentifié.

**Flux principal** :
1. L'utilisateur effectue un geste pull-to-refresh sur la page.
2. L'event `RefreshStats` est émis.
3. `StatsService.invalidateCache()` supprime les clés `cached_user_stats` et `cached_user_stats_at`.
4. `StatsService.getUserStats(forceRefresh: true)` fait un fetch réseau direct.
5. Le cache est mis à jour et `StatsLoaded` est émis avec les données fraîches.

---

## Dépendances

- `StatsService` — service de données stats (cache + fetch réseau)
- `HttpService` (core) — appels réseau authentifiés
- `StorageService` (core) — persistance du cache dans `flutter_secure_storage`
- `ProfileEditSection` (feature profile/widgets) — composant visuel réutilisé pour le layout des sections
- `AppChip`, `AppEmptyState`, `AppErrorState`, `PastelTile` (core/components) — primitives design system
- Clés i18n : `statsTitle`, `statsMonthsSinceJoin`, `statsHeroBadge`, `statsSectionOverview`, `statsLibraryTotal`, `statsTotalChapters`, `statsReadingTime`, `statsCompletionRate`, `statsLastRead`, `statsSectionBreakdown`, `statsByStatusEmpty`, `statsSectionGenres`, `statsTopGenresEmpty`, `statsMinutesShort`, `statsHoursAndMinutesShort`, `statsDaysAndHoursShort`, `offlineMode`, `retry`
- Clés i18n partagées (statuts) : `statusReadLater`, `statusReading`, `statusCaughtUp`, `statusCompleted`

---

## Zones d'incertitude

> Les points suivants n'ont pas pu être déterminés par le code seul :

- **Invalidation après mutation biblio** : le commentaire dans `StatsService` indique que `invalidateCache()` devrait être appelée "après add/remove biblio, update chapter, change status". Il n'est pas visible dans le code de cette feature si cet appel est effectivement présent dans `LibraryBloc` ou `DetailBloc`. À vérifier.
- **Endpoint `/user/stats`** : le contrat exact du champ `completionRate` (complétés / total, ou autre définition) n'est pas documenté côté Flutter.
- **Calcul temps de lecture** : la valeur `estimatedReadingTimeMinutes` est fournie par l'API. La règle des 4 min/chapitre est mentionnée dans le commentaire du DTO mais pourrait changer côté API sans impact sur le client.
- **Champ `lastReadAt`** : peut être `null` si la bibliothèque est vide. La logique d'affichage remplace `null` par `—` mais la sémantique exacte (date de dernière lecture de chapitre vs date de dernière modification biblio) n'est pas précisée.
