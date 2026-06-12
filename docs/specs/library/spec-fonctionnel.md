# Spec Fonctionnelle — library [DRAFT — à valider par le dev]

| Champ      | Valeur              |
|------------|---------------------|
| Module     | library             |
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

| ADR | Titre | Statut |
|-----|-------|--------|
| [RETRO-013](../../adr/RETRO-013-offline-queue-library-mutations.md) | Queue offline pour les mutations de la bibliothèque | Documenté (rétro) |
| [RETRO-005](../../adr/RETRO-005-stale-while-revalidate.md) | Stale-while-revalidate : émission du cache avant le réseau — ADR canonique transverse (home, library, manga) | Documenté (rétro) |
| [RETRO-015](../../adr/RETRO-015-chapter-log-additive-vs-progress-counter.md) | Log de lecture additif séparé du compteur de progression | Documenté (rétro) |

> *Table auto-générée par adr-linker. Ne pas éditer manuellement.*

---

## Contexte et objectif

La bibliothèque est le module central de Manga Tracker. Elle représente la liste personnelle des mangas sauvegardés par l'utilisateur, avec leur statut de lecture. Elle doit être utilisable hors connexion (lecture du cache, mutations en queue) et offrir une expérience fluide grâce au chargement stale-while-revalidate.

La bibliothèque est accessible depuis l'onglet dédié de la barre de navigation principale. Elle sert aussi de source de données aux autres features (fiche détail, lecteur, statistiques).

---

## Règles métier (déduites du code)

1. Un manga de la bibliothèque possède exactement un statut de lecture parmi quatre valeurs : `reading` (En cours), `readLater` (À lire plus tard), `caughtUp` (À jour), `completed` (Terminé).
2. Le statut par défaut à l'ajout est `readLater` (déduit de `ReadingStatusExtension.fromValue` qui retourne `ReadingStatus.readLater` si la valeur est null).
3. La progression de lecture (`readChapters`) est un compteur distinct du journal de lecture additif (`ChapterLogDto`). Mettre à jour la progression via `saveChapterProgress` n'écrit PAS d'entrée de log, et inversement — les deux sont des endpoints séparés.
4. Toute mutation de la bibliothèque (ajout, suppression, changement de statut, progression, lien personnalisé) est exécutée immédiatement si en ligne, ou mise en queue `OfflineAction` si hors ligne. La mutation est considérée réussie côté UI même en mode queue (retour `true`).
5. La notation personnelle (`rating`, 0-10) est la seule mutation NON mise en queue hors ligne : si l'utilisateur est hors ligne, la note est silencieusement abandonnée.
6. Un manga peut avoir un lien de lecture personnalisé (`customLink`). Ce lien est créé, mis à jour ou supprimé depuis la bibliothèque. En mode hors ligne, les changements de lien sont mis en queue.
7. Le badge "nouveau chapitre" est calculé côté client via `NewChapterService` lors du chargement de la bibliothèque. Il enrichit les données de chaque manga sans toucher au cache persisté.
8. La bibliothèque est groupée par statut de lecture. Les quatre groupes sont toujours présents et repliables indépendamment.
9. La vue (liste ou grille) est persistée dans `shared_preferences` (clé `library_view_mode`) entre les sessions.
10. Un filtre "mangas téléchargés uniquement" masque les mangas sans chapitre téléchargé localement. Ce filtre est en mémoire uniquement.
11. La recherche dans la bibliothèque est locale (pas d'appel API). Elle fonctionne sur le titre principal et les titres alternatifs (`associated`). Le scoring favorise les correspondances exactes (1000), en début de titre (500), puis partielles (100). Pour les titres alternatifs, les mêmes paliers sont appliqués avec un coefficient légèrement inférieur.
12. Le nombre d'actions en attente de synchronisation (`pendingActions`) est affiché dans la bannière offline.

---

## Cas d'usage (déduits)

### CU-001 — Chargement initial de la bibliothèque

**Acteur :** Utilisateur authentifié.

**Flux principal :**
1. L'utilisateur ouvre l'onglet bibliothèque.
2. Si un cache existe, la bibliothèque s'affiche immédiatement (données `stale`).
3. Une requête réseau est lancée en parallèle vers `GET /library/all`.
4. À la réception, la bibliothèque est mise à jour avec les données fraîches. Les badges "nouveau chapitre" sont enrichis.

**Flux alternatif — hors ligne :**
- La requête réseau échoue. Si un cache existe, il est affiché avec indicateur hors ligne + compteur de mutations en attente. Sinon, un écran d'erreur est affiché avec bouton "Réessayer".

### CU-002 — Ajout d'un manga à la bibliothèque

**Acteur :** Utilisateur authentifié (depuis la fiche détail).

**Flux principal :**
1. L'utilisateur déclenche l'ajout (`AddMangaToLibrary`).
2. Le BLoC affiche `LibraryActionInProgress` avec message "Ajout en cours...".
3. `POST /library/save` est appelé. En cas de succès, `LoadLibrary` est déclenché.

**Flux alternatif — hors ligne :**
- L'action est ajoutée à la queue `OfflineAction.addManga`. L'UI retourne comme si le succès était immédiat. La synchro se fera à la reconnexion.

### CU-003 — Suppression d'un manga de la bibliothèque

**Acteur :** Utilisateur authentifié.

**Flux principal :**
1. `RemoveMangaFromLibrary` déclenche `DELETE /library/delete`.
2. En cas de succès, rechargement de la bibliothèque.

**Flux alternatif — hors ligne :** identique à CU-002, action `removeManga` en queue.

### CU-004 — Mise à jour du statut de lecture

**Acteur :** Utilisateur authentifié.

**Flux principal :**
1. `UpdateMangaStatus` déclenche `PUT /library/status` avec `{ muId, readingStatus }`.
2. En cas de succès, rechargement.

**Flux alternatif — hors ligne :** action `updateMangaStatus` en queue.

### CU-005 — Sauvegarde de la progression de lecture (compteur)

**Acteur :** Utilisateur authentifié (depuis le lecteur ou la fiche détail).

**Flux principal :**
1. `SaveChapterProgress` déclenche `PUT /library/chapter` avec `{ muId, readChapters }`.
2. En cas de succès, rechargement.

**Flux alternatif — hors ligne :** action `saveChapterProgress` en queue.

### CU-006 — Enregistrement d'une session de lecture (journal additif)

**Acteur :** Utilisateur authentifié (depuis le lecteur).

**Flux principal :**
1. `recordChapterLog` est appelé directement sur `LibraryService` (pas via BLoC).
2. `POST /library/{muId}/chapter-log` est appelé. Retourne un `ChapterLogDto`.
3. Aucun rechargement de la bibliothèque n'est déclenché.

**Note :** Pas de queue offline pour cette opération (commentaire explicite dans le code).

### CU-007 — Toggle skip d'un chapitre

**Acteur :** Utilisateur authentifié.

**Flux principal :**
1. `toggleChapterSkip` est appelé directement sur `LibraryService`.
2. `PUT /library/{muId}/chapter/{chapterNumber}/skip` avec `{ skipped }`.

### CU-008 — Gestion du lien de lecture personnalisé

**Acteur :** Utilisateur authentifié.

**Flux principal :**
1. Mise à jour : `UpdateCustomLink` → `PUT /library/custom-link`.
2. Suppression : `DeleteCustomLink` → `DELETE /library/custom-link`.
3. Lecture : `getCustomLink` appelle `MangaService.getMangaDetail` (pas de cache local dédié).

**Flux alternatif — hors ligne :** actions `updateCustomLink` / `deleteCustomLink` en queue. `getCustomLink` retourne `null` hors ligne.

### CU-009 — Recherche et filtrage dans la bibliothèque

**Acteur :** Utilisateur authentifié.

**Flux principal :**
1. L'utilisateur saisit du texte dans la barre de recherche.
2. `LibraryFiltering.filter` est appliqué localement : scoring sur titre principal + titres alternatifs, tri par pertinence décroissante.
3. Le bouton "mangas téléchargés" filtre en plus par `DownloadManagerService.getAllDownloadedChapters`.

### CU-010 — Basculement vue liste / vue grille

**Acteur :** Utilisateur authentifié.

**Flux principal :**
1. L'utilisateur tape l'icône de bascule dans `LibraryTopBar`.
2. La préférence est persistée en `shared_preferences` (`library_view_mode`).
3. La vue bascule entre `LibraryListView` (MangaRow + barre de progression) et `LibraryGridView` (MangaCard 3 colonnes).

---

## Dépendances

- `LibraryService` — CRUD bibliothèque (appels API + dispatch OfflineAction)
- `CacheHelperService` — cache persisté (clé `cached_library`), méthode `loadLibraryData`
- `OfflineCacheService` — queue d'actions offline + lecture/écriture cache JSON
- `SyncService` — rejoue la queue à la reconnexion (écoute `connectivityStream`)
- `ConnectivityService` — état connexion (stream + check ponctuel)
- `NewChapterService` — enrichissement badge nouveaux chapitres (read-only, côté client)
- `DownloadManagerService` — liste des chapitres téléchargés (pour filtre downloaded-only)
- `MangaService` — utilisé par `getCustomLink` pour récupérer `mangaDetail.customLink`
- `HttpService` — appels API authentifiés (JWT auto-refresh)
- `shared_preferences` — persistance du mode de vue (`library_view_mode`)

---

## Zones d'incertitude

> Les points suivants n'ont pas pu être déterminés par le code seul :

- La vue `LibraryView` (sans BLoC) coexiste avec `LibraryBlocView` (avec BLoC). Laquelle est réellement utilisée dans le router ? Le router affiche-t-il les deux selon le contexte ou l'une a-t-elle remplacé l'autre ?
- La règle métier exacte derrière la décision de ne PAS mettre en queue la notation hors ligne (commentaire dit "action non critique") — est-ce une décision produit validée ou un choix temporaire MVP ?
- `getReadChapterByUid` retourne `-1` si le manga n'est pas en bibliothèque. Est-ce un invariant testé par les callers, ou un magic number à documenter ?
- La liste `associated` dans `MangaQuickViewDto` contient les titres alternatifs. Sa structure côté API (objet `{title}` ou chaîne directe) est normalisée dans `fromJson` mais l'origine exacte (MangaUpdates) n'est pas documentée dans le code Flutter.
- La valeur `childAspectRatio: 0.52` de la grille est hardcodée. Est-ce une valeur validée sur tous les formats d'écran ?
