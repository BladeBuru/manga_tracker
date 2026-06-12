# Spec Technique — library

| Champ         | Valeur              |
|---------------|---------------------|
| Module        | library             |
| Version       | 0.1.0               |
| Date          | 2026-06-04          |
| Source        | Rétro-ingénierie    |

---

## Architecture du module

Le module `library` suit le pattern BLoC standard du projet avec une couche de service offline-first. Il est structuré en cinq sous-couches :

```
LibraryBlocView (UI)
    └── LibraryBloc (State management — lazy singleton GetIt)
            ├── LibraryService (CRUD + offline dispatch)
            │       ├── HttpService (appels API authentifiés)
            │       ├── OfflineCacheService (queue OfflineAction)
            │       └── ConnectivityService (check isConnected)
            ├── CacheHelperService (stale-while-revalidate + cache persisté)
            └── NewChapterService (enrichissement badges, read-only)
```

Le module contient une deuxième vue `LibraryView` (StatefulWidget sans BLoC) qui semble être une version antérieure. Elle utilise `CacheHelperService.loadLibraryData` directement sans passer par le BLoC. La vue active dans le router est `LibraryBlocView`.

---

## Fichiers impactés

| Fichier | Rôle | Lignes |
|---------|------|--------|
| `lib/features/library/bloc/library_bloc.dart` | BLoC : gestion des événements, orchestration cache/réseau, enrichissement nouveaux chapitres | ~387 |
| `lib/features/library/bloc/library_event.dart` | 8 événements : LoadLibrary, AddManga, RemoveManga, UpdateStatus, SaveProgress, UpdateLink, DeleteLink, Refresh | ~84 |
| `lib/features/library/bloc/library_state.dart` | 4 états : Initial, Loading, Loaded (isOffline + pendingActions + isStale), Error, ActionInProgress | ~86 |
| `lib/features/library/services/library.service.dart` | CRUD bibliothèque + chapter-log API + helpers. Init async (dépendances GetIt) | ~385 |
| `lib/features/library/dto/chapter_log.dto.dart` | DTO session de lecture additive (id, chapterNumber, isSkipped, isBonus, scrollPosition, readAt) | ~45 |
| `lib/features/library/views/library_bloc_view.dart` | Vue principale BLoC — top bar + search + filtre + bascule vue | ~291 |
| `lib/features/library/views/library.view.dart` | Vue legacy StatefulWidget (FutureBuilder, sans BLoC) — coexistence avec BlocView | ~228 |
| `lib/features/library/widgets/library_filtering.dart` | Logique pure : scoring recherche, filtre downloaded, groupement par statut | ~122 |
| `lib/features/library/widgets/library_grid_view.dart` | Vue grille 3 colonnes par section (MangaCard, compactLibrary mode) | ~94 |
| `lib/features/library/widgets/library_list_view.dart` | Vue liste par section (MangaRow avec showProgressBar) + FutureBuilder pour newChaptersCount | ~145 |
| `lib/features/library/widgets/library_section.dart` | Card hairline repliable (AnimatedCrossFade 250ms) + header uppercase + badge compteur | ~217 |
| `lib/features/library/widgets/library_top_bar.dart` | Top bar V1 : titre 24px/900 + 3 boutons 36×36 (download filter, folder, list/grid toggle) | ~145 |
| `lib/features/library/widgets/library_action_banner.dart` | Bannière spinner + texte pendant une action en cours | ~54 |
| `lib/features/library/widgets/library_error_state.dart` | État d'erreur avec icône + message + bouton Réessayer | ~50 |

---

## Schéma BDD (côté client)

Pas de BDD embarquée dans le module. Le stockage utilise deux mécanismes :

**Cache JSON persisté** (`shared_preferences` via `OfflineCacheService`) :
- Clé `cached_library` — liste de `MangaQuickViewDto` sérialisés en JSON. Expiration 24h gérée par `CacheHelperService`.
- Clé `offline_queue` — liste de `Map<String, dynamic>` (sérialisations d'`OfflineAction`). Persistée indéfiniment jusqu'à synchronisation.

**Préférences** (`shared_preferences`) :
- Clé `library_view_mode` (`bool`) — `false` = vue liste, `true` = vue grille.

**OfflineAction** — types supportés pour la bibliothèque :

| Type | Champs payload |
|------|----------------|
| `addManga` | `muId: int` |
| `removeManga` | `muId: int` |
| `saveChapterProgress` | `muId: int`, `readChapters: int` |
| `updateMangaStatus` | `muId: int`, `status: String` |
| `updateCustomLink` | `muId: int`, `customLink: String` |
| `deleteCustomLink` | `muId: int` |

---

## API / Endpoints

| Méthode | Route | Description | Auth | Queue offline |
|---------|-------|-------------|------|---------------|
| `GET` | `/library/all` | Récupère tous les mangas de la bibliothèque | JWT | Non (lecture) |
| `POST` | `/library/save` | Ajoute un manga (body: `{ muId }`) — retourne HTTP 201 | JWT | Oui |
| `DELETE` | `/library/delete` | Supprime un manga (body: `{ muId }`) | JWT | Oui |
| `PUT` | `/library/status` | Met à jour le statut (body: `{ muId, readingStatus }`) | JWT | Oui |
| `PUT` | `/library/chapter` | Met à jour la progression (body: `{ muId, readChapters }`) | JWT | Oui |
| `PUT` | `/library/rating` | Met à jour la note 0-10 (body: `{ muId, rating }`) | JWT | Non |
| `PUT` | `/library/custom-link` | Crée/met à jour le lien personnalisé (body: `{ muId, customLink }`) | JWT | Oui |
| `DELETE` | `/library/custom-link` | Supprime le lien personnalisé (body: `{ muId }`) | JWT | Oui |
| `POST` | `/library/{muId}/chapter-log` | Enregistre une session de lecture additive | JWT | Non |
| `PUT` | `/library/{muId}/chapter/{chapterNumber}/skip` | Toggle skip d'un chapitre | JWT | Non |
| `GET` | `/library/{muId}/chapter-log` | Historique des sessions (max 500, tri date décroissante) | JWT | Non |

**Statuts de retour observés :**
- `GET /library/all` : 200 OK (liste) ou 403 Forbidden
- `POST /library/save` : 201 Created (succès)
- `DELETE`, `PUT` : 200 OK (succès) ou 403 Forbidden

---

## MangaQuickViewDto — Modèle données

```
muId: num                    — Identifiant unique manga (MangaUpdates)
title: String                — Titre principal
year: String                 — Année de publication
smallCoverUrl: String?       — URL cover petite taille
mediumCoverUrl: String?      — URL cover taille moyenne
rating: String               — Note agrégée ou "N/A"
readingStatus: ReadingStatus? — Statut lecture (défaut: readLater si null)
readChapters: num?           — Compteur de chapitres lus
totalChapters: num?          — Total chapitres disponibles
associated: List<String>?    — Titres alternatifs (normalisés depuis {title} ou String)
hasNewChapters: bool         — Badge enrichi côté client (NewChapterService)
```

**Méthode proxy** : `coverProxyUrl({size})` construit une URL via le proxy API (`/mangas/{muId}/cover?size=...`) pour contourner les 404 MangaUpdates — zéro placeholder, cache CDN 30j.

---

## ChapterLogDto — Modèle données

```
id: int                      — Identifiant de l'entrée (serveur)
chapterNumber: num           — Numéro de chapitre (peut être décimal pour bonus)
isSkipped: bool              — Marqué comme ignoré (filler, hors-série)
isBonus: bool                — Chapitre bonus/spécial
scrollPosition: int?         — Position de scroll sauvegardée
readAt: DateTime             — Timestamp de lecture (ISO 8601)
```

---

## ReadingStatus — Enum

| Valeur enum | Valeur API | Label (FR) | Couleur |
|-------------|-----------|-----------|---------|
| `reading` | `"reading"` | En cours | success (vert) |
| `readLater` | `"readLater"` | À lire plus tard | info (bleu) |
| `caughtUp` | `"caughtUp"` | À jour | teal (#00897B) |
| `completed` | `"completed"` | Terminé | violet (#673AB7) |

---

## Patterns identifiés

- **BLoC Event-driven (lazy singleton)** : `LibraryBloc` est enregistré `registerLazySingleton` dans GetIt. Une seule instance partagée entre toutes les vues qui affichent la bibliothèque. Les données persistent entre navigations.
- **Stale-while-revalidate** : `_onLoadLibrary` émet d'abord le cache (`stale: true`) avant le chargement réseau. Voir ADR RETRO-005.
- **Offline-first avec mutation queue** : chaque méthode de mutation dans `LibraryService` a un `if (isOnline) { try API catch → queue } else { queue }`. Voir ADR RETRO-013.
- **Enrichissement asynchrone post-chargement** : `_enrichWithNewChapters` fait un `Future.wait` sur tous les mangas pour appeler `NewChapterService.hasNewChapters` — parallèle, mais non mis en cache.
- **Découpage vue/widgets** : `LibraryBlocView` délègue aux widgets `LibraryGridView`, `LibraryListView`, `LibrarySection`, `LibraryTopBar`, `LibraryFiltering`. Respect de la limite 150 lignes par widget.
- **Scoring de pertinence recherche** : hiérarchie 1000/500/100 sur le titre + 900/450/90 sur les titres alternatifs, tri décroissant par score dans `LibraryFiltering.calculateMatchScore`.
- **Responsive layout** : `LayoutBuilder` dans `LibraryBlocView` — contrainte max 1100px avec padding 32px au-delà de 1200px, padding 24px entre 600-1200px, plein écran en dessous.
- **Persistance mode vue** : `static bool? _cachedViewMode` en mémoire + `shared_preferences` pour la persistance entre sessions.

---

## Décisions techniques documentées en spec (non-ADR)

- **Rating non mis en queue** : `updateRating` retourne `false` silencieusement hors ligne. Commentaire dans le code : "pas de queue pour le rating (action non critique)". Cohérent avec l'approche MVP mais à discuter si la notation devient plus importante.
- **`getCustomLink` via MangaService** : le lien personnalisé n'est pas dans `MangaQuickViewDto` (liste) — la méthode `getCustomLink` re-appelle `MangaService.getMangaDetail` pour le récupérer. Pas de fallback offline pour cette lecture.
- **`getReadChapterByUid` retourne `-1`** : convention magic number si manga absent de la bibliothèque. Peut être confusant : `totalChapters` peut aussi être 0 pour un manga en cours de publication.
- **`LibraryView` (legacy) coexiste avec `LibraryBlocView`** : deux implémentations dans `lib/features/library/views/`. La legacy utilise `FutureBuilder` direct sans BLoC. Il est probable que le router route uniquement vers `LibraryBlocView` mais cela n'a pas été vérifié dans ce fichier.
- **Hors-série / bonus** : `ChapterLogDto.isBonus` et `chapterNumber: num` (peut être décimal) permettent de logguer des chapitres non-entiers (ex: 10.5). La logique de rendu de ces chapitres dans l'UI n'est pas dans ce module.

---

## Tests existants

| Fichier | Ce qu'il teste | Statut |
|---------|---------------|--------|
| Aucun   | —             | Absent |

Le module `library` n'a aucun test unitaire ni widget test. Les features `auth` et `manga` ont des tests partiels, mais `library` n'en a pas.
