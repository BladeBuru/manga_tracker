# Spec Technique — manga (detail)

| Champ         | Valeur              |
|---------------|---------------------|
| Module        | manga               |
| Version       | 0.1.0               |
| Date          | 2026-06-04          |
| Source        | Rétro-ingénierie    |

---

## Architecture du module

La feature `manga (detail)` suit le pattern BLoC standard du projet avec une particularité notable : `DetailBloc` est enregistré en **factory** dans GetIt (une nouvelle instance par page). Cela garantit l'isolation totale de l'état entre deux fiches de manga ouvertes en même temps ou en succession rapide.

Le flux de chargement est :

```
Detail (wrapper)
  └─ DetailBlocView (StatefulWidget)
       └─ BlocProvider(create: DetailBloc())
            └─ _DetailBlocViewContent (BlocConsumer)
                 ├─ header (cover + genres chips)
                 ├─ LateDetailView (scrollable stateful)
                 │    ├─ SharedReadingSection
                 │    ├─ DetailInfoCard
                 │    ├─ DetailRatingSection (slot inline, si inLibrary)
                 │    ├─ noms associés (ExpansionTile)
                 │    ├─ synopsis (AnimatedContainer, traduction background)
                 │    ├─ _buildChaptersBlock (linéaire ou sectionné)
                 │    └─ CommentsSection
                 └─ _buildBottomActionBar
                      ├─ [status icon] si in library
                      ├─ DetailReadOnlineButton
                      └─ _RecommendationsIconButton
```

`DetailBlocView` crée le `BlocProvider` lui-même (pas GetIt) et dispatch `LoadMangaDetail` immédiatement à la création du BLoC. Cela garantit qu'une seule instance existe par page, avec son propre cycle de vie.

---

## Fichiers impactés

| Fichier | Rôle | Lignes |
|---------|------|--------|
| `lib/features/manga/bloc/detail_bloc.dart` | BLoC factory — orchestration complète (chargement, mutations, offline, vérification chapitres) | ~780 |
| `lib/features/manga/bloc/detail_event.dart` | Définition des 9 events | ~92 |
| `lib/features/manga/bloc/detail_state.dart` | Définition des 4 états (Initial, Loading, Loaded, ActionInProgress, Error) | ~86 |
| `lib/features/manga/views/detail.dart` | Wrapper `Detail` → `DetailBlocView` | ~25 |
| `lib/features/manga/views/detail_bloc_view.dart` | Vue principale — BlocProvider + BlocConsumer + bottom bar + modals | ~1318 |
| `lib/features/manga/views/late_detail.view.dart` | Vue scrollable — chapters, synopsis, comments, rating slot | ~817 |
| `lib/features/manga/dto/manga_detail.dto.dart` | DTO complet avec fromJson / toJson / copyWith | ~220 |
| `lib/features/manga/services/manga.service.dart` | API mangas (détail, recommandations avec retry/timeout) | ~207 |
| `lib/features/manga/services/chapter_check_service.dart` | Vérification HTTP d'existence de chapitre (HEAD + GET fallback) | ~229 |
| `lib/features/manga/services/new_chapter_service.dart` | Persistance locale (SharedPreferences) des nouveaux chapitres | ~213 |
| `lib/features/manga/widgets/detail_info_card.dart` | Matrice 3×2 fusionnée (chapitres / note / statut / année / auteur / artiste) | ~289 |
| `lib/features/manga/widgets/detail_rating_section.dart` | Section notation utilisateur 5 étoiles → note /10 + communauté | ~287 |
| `lib/features/manga/widgets/detail_genre_chips.dart` | Chips de genres | ~inconnu |
| `lib/features/manga/widgets/detail_chapter_section.dart` | Section chapitres collapsible V1 | ~inconnu |
| `lib/features/manga/widgets/detail_read_online_button.dart` | Bouton lire en ligne / ajouter lien | ~inconnu |
| `lib/features/manga/widgets/detail_recommendations_section.dart` | Section recommandations (dans le bottom sheet) | ~inconnu |
| `lib/features/manga/widgets/detail_status_selector.dart` | `DetailAddToLibraryButton` — CTA ajout bibliothèque | ~inconnu |

---

## Schéma de données — MangaDetailDto

Aucune table locale (pas de sqflite pour les données applicatives). Les données sont :

- **API REST** : `GET /mangas/:muId` → `MangaDetailDto` sérialisé JSON
- **Cache JSON** : clé `cached_manga_detail_<muId>` dans `OfflineCacheService` (24h)
- **SharedPreferences** : `new_chapters_map` et `last_checked_chapter_map` via `NewChapterService`
- **SharedPreferences** : `manga_<muId>_expanded_seasons` — état d'expansion des sections de chapitres (sauvegardé par manga)

### Structure MangaDetailDto

| Champ | Type | Notes |
|-------|------|-------|
| `muId` | `num` | ID MangaUpdates |
| `title` | `String` | — |
| `description` | `String?` | HTML / Markdown — traduit background |
| `status` | `String?` | Champ brut API |
| `publicationStatus` | `String?` | Ex: "Ongoing", "Completed" |
| `year` | `String` | Année de publication |
| `smallCoverUrl` / `mediumCoverUrl` / `largeCoverUrl` | `String?` | 3 résolutions de couverture |
| `rating` | `String` | Note MU globale (ex: "8.18") ou "N/A" si 0 |
| `totalChapters` | `int` | — |
| `isCompleted` | `bool?` | — |
| `authors` | `List<AuthorDto>?` | `type` = "Author" ou "Artist" |
| `genres` | `List<String>?` | — |
| `customLink` | `String?` | URL lien personnalisé de lecture |
| `inLibrary` | `bool` | Enrichi côté client |
| `readChaptersCount` | `int?` | Enrichi côté client |
| `readingStatus` | `ReadingStatus?` | Enrichi côté client |
| `associated` | `List<String>?` | Noms alternatifs / traductions |
| `recommendations` | `List<int>?` | Liste de muIds recommandés |
| `type` | `String?` | Ex: "Manga", "Manhwa", "Manhua" |
| `seasonChapters` | `List<SeasonChapter>?` | Découpage en saisons |
| `bonusChapters` | `List<SeasonChapter>?` | Chapitres bonus |
| `userRating` | `int` | 0-10, 0 = pas de note (default: 0) |
| `communityRating` | `double?` | Moyenne locale |
| `communityRatingCount` | `int` | Nombre de votants locaux |
| `aggregatedRating` | `double?` | Note Bayesian (MU + locale) |

---

## API / Endpoints

| Méthode | Route | Description | Auth |
|---------|-------|-------------|------|
| `GET` | `/mangas/:muId` | Détail d'un manga | JWT |
| `GET` | `/mangas/recommendations/:muId` | Recommandations similaires (proxy MU) | JWT |
| `POST` | `/mangas/:muId/refresh-cover` | Rafraîchit les URLs de couverture expirées | JWT |
| `POST` | `/library` (body: `muId`) | Ajouter à la bibliothèque | JWT |
| `DELETE` | `/library/:muId` | Retirer de la bibliothèque | JWT |
| `PUT` | `/library/:muId/status` | Mettre à jour le statut de lecture | JWT |
| `PUT/POST` | `/library/:muId/progress` | Sauvegarder la progression (readChapters) | JWT |
| `PUT/POST` | `/library/:muId/custom-link` | Mettre à jour le lien personnalisé | JWT |
| `DELETE` | `/library/:muId/custom-link` | Supprimer le lien personnalisé | JWT |
| `PUT/POST` | `/library/:muId/rating` | Mettre à jour la note utilisateur | JWT |

> Les routes bibliothèque sont définies dans `LibraryService` — les chemins exacts peuvent différer, lire `lib/features/library/services/library.service.dart`.

---

## États BLoC

| État | Champs | Déclencheur |
|------|--------|-------------|
| `DetailInitial` | — | État de départ |
| `DetailLoading` | — | Pas de cache disponible au chargement |
| `DetailLoaded` | `mangaDetail`, `isOffline`, `pendingActions`, `isStale` | Chargement réussi (cache ou réseau) |
| `DetailActionInProgress` | `mangaDetail`, `action`, `isOffline` | Mutation en cours (ajout, retrait, statut) |
| `DetailError` | `message`, `isOffline`, `cachedMangaDetail?` | Erreur sans fallback cache |

---

## Events BLoC

| Event | Champs | Handler |
|-------|--------|---------|
| `LoadMangaDetail` | `muId: int` | `_onLoadMangaDetail` |
| `RefreshMangaDetail` | — | `_onRefreshMangaDetail` (re-dispatch `LoadMangaDetail`) |
| `AddToLibrary` | `muId: int` | `_onAddToLibrary` |
| `RemoveFromLibrary` | `muId: int` | `_onRemoveFromLibrary` |
| `UpdateReadingStatus` | `status: ReadingStatus` | `_onUpdateReadingStatus` |
| `SaveChapterProgress` | `muId: int`, `readChapters: int` | `_onSaveChapterProgress` |
| `UpdateCustomLink` | `customLink: String` | `_onUpdateCustomLink` |
| `DeleteCustomLink` | — | `_onDeleteCustomLink` |
| `UpdateUserRating` | `muId: int`, `rating: int` | `_onUpdateUserRating` |

---

## Patterns identifiés

- **Factory BLoC** : `DetailBloc` instancié via `BlocProvider.create` dans `DetailBlocView`, pas via GetIt. Chaque navigation vers une fiche manga crée une nouvelle instance indépendante.
- **Stale-while-revalidate** : cache émis en état `stale: true` avant la réponse réseau, puis remplacé par les données fraîches.
- **Enrichissement côté client** : les données bibliothèque (`inLibrary`, `readingStatus`, `readChaptersCount`, `customLink`) ne viennent pas de l'API détail mais sont fusionnées via `LibraryService`. Le DTO final est reconstruit à chaque chargement.
- **Update optimiste avec rollback** : `UpdateUserRating` met à jour le DTO en mémoire avant l'appel API ; rollback si l'API retourne `false`.
- **Timer non-bloquant** : la vérification de nouveaux chapitres utilise un `Timer` 3s pour ne pas bloquer le chargement initial. Le timer est annulé si le muId change avant expiration.
- **StreamSubscription connectivité** : `_connectivitySubscription` écoute les changements réseau mais n'émet plus d'état directement — l'état offline est désormais déduit des erreurs réseau lors des appels.
- **Responsive layout** : la vue est contrainte à `maxWidth: 900px` sur les écrans larges via `LayoutBuilder`.
- **Slot d'injection** : `LateDetailView` accepte un `inlineRatingSlot` optionnel — pattern slot/injection pour éviter le couplage direct avec `DetailRatingSection`.

---

## Décisions documentées (candidats rejetés pour ADR)

### Délai 3 secondes pour la vérification des chapitres

Choix d'implémentation local : attendre 3 secondes après le chargement pour lancer `_checkForNewChapters` afin de ne pas retarder l'affichage initial. Documenté en commentaire dans le code (`detail_bloc.dart` ligne ~107). Ce délai est une heuristique locale (AP-3), pas une décision architecturale.

### Stratégie HEAD + GET fallback pour `ChapterCheckService`

`ChapterCheckService` tente d'abord une requête HTTP `HEAD` (plus légère) sur l'URL du chapitre externe. Si HEAD retourne 405 (non supporté) ou échoue, il tente un `GET` avec inspection du contenu (heuristique de détection de page principale via mots-clés + comptage de liens chapitres). Timeouts : HEAD = 5s, GET = 8s. Cette heuristique est un détail d'implémentation (AP-3) à documenter en commentaire dans `chapter_check_service.dart`.

### Notation 5 étoiles → plage 0-10

Chaque étoile correspond à 2 points. L'API attend une valeur entière 0-10. Le mapping étoile→valeur est un choix de présentation local (AP-6), pas un invariant structurant.

### Cache SharedPreferences pour l'état d'expansion des sections

L'état ouvert/fermé des sections de chapitres par manga (`manga_<muId>_expanded_seasons`) est persisté dans SharedPreferences. C'est un détail de persistance UX local (AP-7), pas un invariant BDD.

### Custom link sans offline

Les mutations `UpdateCustomLink` et `DeleteCustomLink` ne passent pas par la queue offline. Contrairement aux mutations bibliothèque qui sont toutes queued en offline, le custom link échoue explicitement hors ligne. Ce comportement asymétrique est une décision locale non documentée — à clarifier avec le dev.

### `_enrichWithLibraryInfo` : lecture bibliothèque après chaque chargement

À chaque chargement (cache ou réseau), le BLoC appelle deux fois `LibraryService` (statut + chapitres lus) pour enrichir le DTO. Ces appels ne sont pas mis en parallèle (`Future.wait`). Optimisation possible mais pas une décision architecturale.

---

## Tests existants

| Fichier | Ce qu'il teste | Statut |
|---------|---------------|--------|
| `test/features/manga/` (répertoire) | Potentiellement présent (mentionné dans `02-stack.md`) | À vérifier |
| `DetailBloc` | Non couvert explicitement dans les tests listés | Absent (probable) |
| `MangaDetailDto.fromJson` | Non couvert explicitement | Absent (probable) |
| `ChapterCheckService` | Non couvert | Absent |
| `NewChapterService` | Non couvert | Absent |

> `02-stack.md` mentionne `test/features/manga/` mais le contenu exact n'a pas été lu. À vérifier.
