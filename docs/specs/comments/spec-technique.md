# Spec Technique — comments

| Champ         | Valeur              |
|---------------|---------------------|
| Module        | comments            |
| Version       | 0.1.0               |
| Date          | 2026-06-04          |
| Source        | Rétro-ingénierie    |

## Architecture du module

Le module est structuré selon le pattern feature-first standard du projet :

```
lib/features/comments/
├── bloc/
│   ├── comments_bloc.dart       # BLoC principal + part directive
│   ├── comments_event.dart      # Events (part of)
│   └── comments_state.dart      # States (part of)
├── services/
│   └── comments.service.dart    # Accès API REST
├── dto/
│   └── comment.dto.dart         # CommentDto + CommentsPage + CommentSort enum
└── widgets/
    ├── comments_section.dart    # Point d'entrée public — porte son BlocProvider
    ├── comment_tile.dart        # Rendu d'un commentaire individuel
    └── comment_input.dart       # Champ de saisie + bouton d'envoi
```

**Flux de données :**
1. `CommentsSection(muId)` est embarqué dans la fiche manga (`detail_bloc_view.dart`).
2. `CommentsSection.build` crée un `BlocProvider<CommentsBloc>` qui instancie `CommentsBloc(muId)` et dispatch `LoadComments()` immédiatement.
3. Le BLoC appelle `CommentsService.listForManga(muId, page, sort)` via `HttpService`.
4. Le serveur renvoie `CommentsPage { items, page, hasMore }`.
5. Le BLoC émet `CommentsLoaded` qui déclenche le rendu de `_CommentsList`.
6. Les actions utilisateur (post, edit, delete, load more, change sort) sont des Events dispatchés depuis les widgets enfants vers le BLoC via `context.read<CommentsBloc>()`.

**Particularité d'instanciation :** `CommentsBloc` n'est pas enregistré dans GetIt. Il est instancié directement par `CommentsSection` via `BlocProvider(create: (_) => CommentsBloc(muId))`. `CommentsService` est, lui, résolu via `getIt<CommentsService>()` dans le constructeur du BLoC.

## Fichiers impactés

| Fichier | Rôle | Lignes |
|---------|------|--------|
| `lib/features/comments/bloc/comments_bloc.dart` | Logique métier : load/load-more/post/edit/delete/changeSort | ~150 |
| `lib/features/comments/bloc/comments_event.dart` | 6 events : LoadComments, LoadMoreComments, PostComment, EditComment, DeleteComment, ChangeCommentSort | ~59 |
| `lib/features/comments/bloc/comments_state.dart` | 4 states : CommentsInitial, CommentsLoading, CommentsLoaded (avec copyWith), CommentsError | ~63 |
| `lib/features/comments/services/comments.service.dart` | 6 méthodes API : listForManga, listReplies, create, reply, update, delete + report | ~128 |
| `lib/features/comments/dto/comment.dto.dart` | CommentDto, CommentsPage, CommentSort enum | ~87 |
| `lib/features/comments/widgets/comments_section.dart` | BlocProvider + layout principal + header (sort chips) + liste | ~194 |
| `lib/features/comments/widgets/comment_tile.dart` | Rendu d'un item : avatar, auteur, date relative, contenu, rating chip, menu suppression | ~121 |
| `lib/features/comments/widgets/comment_input.dart` | TextField 3-2000 chars + bouton FilledButton.icon | ~92 |

## Schéma BDD

Pas de stockage local. Le module est entièrement sans cache — les données vivent exclusivement en mémoire dans le BLoC pendant la durée de vie de la page.

## API / Endpoints

| Méthode | Route | Description | Auth |
|---------|-------|-------------|------|
| GET | `/mangas/:muId/comments?page=&sort=` | Liste paginée des commentaires root d'un manga | JWT requis |
| GET | `/mangas/comments/:commentId/replies` | Réponses d'un commentaire root | JWT requis |
| POST | `/mangas/:muId/comments` | Créer un commentaire root | JWT requis |
| POST | `/mangas/comments/:commentId/reply` | Répondre à un commentaire root | JWT requis |
| PATCH | `/mangas/comments/:commentId` | Éditer contenu et/ou rating | JWT requis |
| DELETE | `/mangas/comments/:commentId` | Soft-delete côté serveur | JWT requis |
| POST | `/mangas/comments/:commentId/report` | Signaler un commentaire | JWT requis |

**Paramètres de tri :** `sort=recent` (chronologique inverse) ou `sort=top` (critère serveur non exposé).

**Codes HTTP attendus :**
- `200 OK` pour GET, PATCH, DELETE, POST report
- `200 OK` ou `201 Created` pour POST create / reply
- Tout autre code lève une `Exception` générique

## Modèle de données (DTO)

```dart
class CommentDto {
  final int id;
  final String content;       // '[supprimé]' si isDeleted
  final int? rating;          // 0-10, null si absent ou supprimé
  final int authorId;
  final String authorUsername;
  final String? authorDisplayName;  // fallback: authorUsername
  final String? authorAvatarUrl;
  final int? parentCommentId; // null = root, non-null = réponse
  final bool isDeleted;
  final int replyCount;       // Nombre de réponses directes
  final DateTime createdAt;
  final DateTime updatedAt;
}

class CommentsPage {
  final List<CommentDto> items;
  final int page;
  final bool hasMore;
}

enum CommentSort { recent, top }
```

## État BLoC

```
CommentsInitial
  └─ LoadComments → CommentsLoading
       └─ succès → CommentsLoaded { items, currentPage, hasMore, isLoadingMore, sort, lastError }
       └─ erreur → CommentsError { message }

CommentsLoaded
  ├─ LoadMoreComments → CommentsLoaded.copyWith(isLoadingMore: true)
  │    └─ succès → CommentsLoaded.copyWith(items: [...old, ...new], ...)
  ├─ PostComment → CommentsLoaded.copyWith(items: [new, ...old])  [optimistic]
  ├─ EditComment → CommentsLoaded.copyWith(items: items.map(replace))
  ├─ DeleteComment → CommentsLoaded.copyWith(items: items.map(softDelete))
  └─ ChangeCommentSort → add(LoadComments(sort)) → cycle LoadComments
```

**Gestion des erreurs :** Les mutations (post/edit/delete) écrivent l'erreur dans `CommentsLoaded.lastError`. `_CommentsContent` écoute via `BlocConsumer.listenWhen` et affiche une `SnackBar` rouge. Le state `CommentsLoaded` est maintenu (pas de bascule vers `CommentsError` sur mutation).

## Patterns identifiés

- **BLoC event-driven** — pattern standard du projet, events typés avec `Equatable`.
- **Instanciation directe sans GetIt** — `CommentsBloc` n'est pas enregistré dans le service locator. Il est créé par `CommentsSection` via `BlocProvider`, ce qui garantit une instance par manga sans nécessiter `registerFactory`. Différence avec `DetailBloc` qui est dans GetIt en factory.
- **Optimistic update** — Post et delete mettent à jour la liste locale avant confirmation serveur. En cas d'erreur, aucun rollback automatique n'est implémenté (la liste reste potentiellement désynchronisée jusqu'au prochain rechargement).
- **Self-contained section** — `CommentsSection` porte son propre `BlocProvider`, ce qui permet de l'embarquer dans n'importe quelle vue sans que le parent n'ait à gérer le BLoC.
- **Pas de offline-first** — Aucun `OfflineCacheService` ni détection `SocketException`. Le module ne gère pas le mode hors-ligne (comportement non documenté en cas de perte réseau pendant une mutation).

## Décisions documentées en spec (non ADR)

- **Pas de cache local** — décision explicite dans le commentaire du service (`CommentsService`) : les commentaires sont "très volatils" et l'usage attendu est synchrone (ouverture de page = chargement frais). → `spec-technique.md` section Architecture.
- **Rating retiré de l'UI de saisie** — `CommentInput` conserve la signature `onSubmit(content, rating)` pour compatibilité avec le BLoC, mais envoie toujours `rating: null`. La note manga (`UserManga.rating`) est le point unique pour noter. → documenté dans le commentaire Dart de `comment_input.dart`.
- **Bouton "Charger plus" vs infinite scroll** — choix UX implicite : `_CommentsList` affiche un `OutlinedButton` quand `hasMore == true`. Pas de `ScrollController` ni de listener de scroll dans le widget. → `spec-technique.md` section API (pattern de pagination manuel).
- **`CommentsBloc` hors GetIt** — instancié par `BlocProvider` dans `CommentsSection`, service résolu via `getIt<CommentsService>()` à l'intérieur du constructeur. Ce mélange (BLoC hors GetIt, service via GetIt) est une variante locale du pattern project. → documenté ici.

## Tests existants

| Fichier | Ce qu'il teste | Statut |
|---------|---------------|--------|
| *(aucun)* | — | Absent — le module comments n'a pas de fichier de test dédié dans les 7 fichiers de test identifiés par retro-scanner. |
