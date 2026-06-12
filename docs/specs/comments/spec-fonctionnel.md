# Spec Fonctionnelle — comments [DRAFT — à valider par le dev]

| Champ      | Valeur              |
|------------|---------------------|
| Module     | comments            |
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

## ADRs

| ADR | Titre | Statut |
|-----|-------|--------|
| [RETRO-049](../../adr/RETRO-049-soft-delete-comment-content-replaced.md) | Soft-delete : contenu remplacé côté client par un placeholder fixe | Documenté (rétro) |
| [RETRO-050](../../adr/RETRO-050-reply-nesting-one-level.md) | Imbrication des réponses limitée à 1 niveau | Documenté (rétro) |

> *Table auto-générée par adr-linker. Ne pas éditer manuellement.*

---

## Contexte et objectif

Le module `comments` permet aux utilisateurs authentifiés de laisser des commentaires textuels sur une fiche manga. Il est intégré en bas de la fiche détail manga (`CommentsSection`) et vise à créer un espace d'échange communautaire autour d'un titre. Les commentaires sont chargés à la demande, paginés, et peuvent recevoir des réponses directes (1 niveau d'imbrication).

## Règles métier (déduites du code)

1. Seul un utilisateur authentifié peut poster, éditer ou supprimer un commentaire (tous les appels passent par `HttpService.postWithAuthTokens` / `patchWithAuthTokens` / `deleteWithAuthTokens`).
2. Un commentaire doit contenir entre 3 et 2 000 caractères. La validation est appliquée côté Flutter avant soumission (`CommentInput._isValid`), et également côté serveur (mentionné dans le commentaire Dart du widget).
3. La notation (rating 0-10) est optionnelle sur un commentaire (`int? rating`). Le sélecteur de rating a été intentionnellement retiré de l'UI de saisie pour éviter la duplication avec la note personnelle du manga (`UserManga.rating`). Le champ reste supporté par le DTO et le service pour compatibilité.
4. Les commentaires sont affichés selon deux tris exclusifs : `recent` (chronologique inverse) et `top` (par score — critère serveur non précisé dans le code Flutter).
5. La liste est chargée par pages. Le chargement de la page suivante est déclenché explicitement par l'utilisateur via un bouton "Charger plus" (pas d'infinite scroll automatique).
6. Les réponses sont imbriquées sur 1 niveau maximum. Un commentaire root peut avoir des réponses (`parentCommentId == null` pour un root ; `parentCommentId` pointe vers un root pour une réponse). Il n'existe pas de réponse à une réponse.
7. La suppression est un soft-delete : le contenu devient `'[supprimé]'`, `isDeleted` passe à `true`, la note est effacée (`rating: null`). Le commentaire reste visible dans le fil pour préserver la structure des réponses.
8. L'édition d'un commentaire (`EditComment`) met à jour le contenu et/ou la note et reflète immédiatement la modification dans la liste locale (optimistic update).
9. Un commentaire peut être signalé (`CommentsService.report`) — la fonctionnalité n'est pas encore exposée dans l'UI (aucun widget ne déclenche cet appel service).
10. Le nom affiché d'un auteur est `authorDisplayName` avec fallback sur `authorUsername` (helper `CommentDto.displayName`).
11. Les dates sont affichées de façon relative (il y a X minutes/heures/jours) pendant la semaine, puis en format localisé `yMd` au-delà de 7 jours.

## Cas d'usage (déduits)

### CU-001 — Charger les commentaires d'un manga
L'utilisateur ouvre la fiche d'un manga. `CommentsSection` monte un `CommentsBloc(muId)` et dispatch immédiatement `LoadComments(sort: recent)`. L'écran affiche un `CircularProgressIndicator` pendant le chargement, puis la liste des commentaires de la première page.

### CU-002 — Changer le tri
L'utilisateur tape sur le chip "Top" dans l'en-tête. `ChangeCommentSort(top)` est dispatché, ce qui redéclenche `LoadComments(sort: top)` depuis la page 1 et recharge toute la liste.

### CU-003 — Charger plus de commentaires
Quand `hasMore == true`, un bouton "Charger plus" apparaît en bas de liste. L'utilisateur le presse, `LoadMoreComments` est dispatché, les nouveaux items sont appendés à la liste existante. Pendant ce chargement, un `CircularProgressIndicator` remplace le bouton.

### CU-004 — Poster un commentaire
L'utilisateur saisit un texte (3-2000 chars) dans `CommentInput` et appuie sur le bouton d'envoi. `PostComment(content, rating: null)` est dispatché. Le nouveau commentaire est inséré en tête de liste immédiatement (`optimistic update`). En cas d'erreur, une `SnackBar` rouge affiche le message.

### CU-005 — Répondre à un commentaire
L'utilisateur initie une réponse à un commentaire root. `PostComment(content, parentCommentId: <rootId>)` est dispatché, ce qui appelle `CommentsService.reply`. La réponse est insérée en tête de la liste principale (même liste, pas de sous-liste dédiée dans l'état actuel).

### CU-006 — Éditer un commentaire
L'utilisateur modifie le contenu d'un de ses commentaires via un mécanisme UI non explicité dans le code source disponible (aucun widget ne déclenche `EditComment` — voir zones d'incertitude). Le BLoC reçoit `EditComment`, appelle `CommentsService.update` (PATCH), et remplace l'item dans la liste locale.

### CU-007 — Supprimer un commentaire
L'utilisateur appuie sur l'icône "..." du `CommentTile` et sélectionne "Supprimer". `DeleteComment(id)` est dispatché. Le commentaire est remplacé localement par un placeholder `[supprimé]` (soft-delete). En cas d'erreur serveur, une `SnackBar` rouge apparaît.

### CU-008 — Retry après erreur
Si le chargement initial échoue, `CommentsError` est affiché avec un bouton Retry (composant `AppErrorState`). L'utilisateur peut relancer `LoadComments`.

## Dépendances

- `CommentsService` — accès API REST commentaires, injecté via GetIt
- `HttpService` — transport HTTP authentifié (JWT auto-refresh)
- `AppCard`, `AppChip`, `AppAvatar`, `AppErrorState` — composants du design system (`lib/core/components/`)
- `AppSpacing`, `AppRadius` — tokens de thème (`lib/core/theme/`)
- `AppLocalizations` — i18n (clés : `commentsTitle`, `commentsEmpty`, `commentsPost`, `commentsDelete`, `commentsLoadMore`, `commentsSortRecent`, `commentsSortTop`, `commentsInputHint`, `commentsReplyCount`, `retry`, `timeJustNow`, `timeMinutesAgo`, `timeHoursAgo`, `timeDaysAgo`)
- `DetailBloc` / `detail_bloc_view.dart` — parent qui embarque `CommentsSection` dans la fiche manga

## Zones d'incertitude

> Les points suivants n'ont pas pu être déterminés par le code seul :

- **Déclencheur UI de l'édition** : le BLoC expose `EditComment` et `CommentsService.update` est implémenté, mais aucun widget dans `comment_tile.dart` ni `comments_section.dart` ne declenche cet event. L'édition est-elle accessible via un autre menu, une vue dédiée, ou en attente d'implémentation UI ?
- **Déclencheur UI du signalement** : `CommentsService.report` est implémenté mais aucun widget ne l'appelle. Feature prévue ou abandonnée ?
- **Affichage des réponses** : `CommentTile` affiche `replyCount` en texte cliquable (`color: scheme.primary`) mais aucun `onTap` n'est déclaré sur ce texte. Le chargement des réponses via `listReplies` n'est pas intégré au BLoC. L'expansion des réponses est-elle prévue dans une prochaine itération ?
- **Restriction de suppression** : le `PopupMenuButton` "Supprimer" apparaît si `onDelete != null`, mais `CommentsSection` passe `onDelete` pour tous les commentaires sans vérifier si l'utilisateur courant est l'auteur. La restriction d'autorisation est-elle uniquement côté serveur (403) ?
- **Critère de tri "top"** : la valeur `'top'` est envoyée comme paramètre `sort` à l'API. Le critère de calcul (upvotes, notes, réponses ?) n'est pas visible dans le code Flutter.
- **Comportement du rating dans le DTO** : `CommentDto.rating` est `int?` (0-10 selon discovery.md) mais `CommentTile` affiche `${comment.rating}/10`. La plage 0-5 mentionnée dans les instructions d'orchestration vs 0-10 dans le code — laquelle est canonique ?
