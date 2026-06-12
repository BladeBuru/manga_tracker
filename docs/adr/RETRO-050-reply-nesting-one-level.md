# RETRO-050 — Imbrication des réponses limitée à 1 niveau

| Champ      | Valeur              |
|------------|---------------------|
| Statut     | Documenté (rétro)   |
| Date       | 2026-06-04          |
| Source     | Rétro-ingénierie    |
| Features   | comments            |

## Justification (politique ADR v2.3.0)

| Champ | Valeur |
|-------|--------|
| Catégorie | DATA-MODEL |
| Q1 — Coût de revert > 1j ? | OUI — Passer à N niveaux nécessiterait un modèle de données récursif (arbre vs liste plate), une refonte du BLoC (pagination par sous-arbre), une refonte du rendu `CommentTile` (indentation récursive), et un changement de contrat API (`/replies` renverrait des arbres) ; refactoring transverse estimé à plusieurs jours. |
| Q2 — Non-déductible du code ? | OUI — `pubspec.yaml` et les configs ne révèlent pas cette contrainte. Le DTO `CommentDto.parentCommentId` (nullable `int`) ne distingue pas syntaxiquement un commentaire root d'une réponse ; la règle "1 seul niveau" n'est pas vérifiée dans le code Flutter et doit être connue pour ne pas implémenter reply-to-reply. |
| Q3 — Impact transverse (≥ 2 specs) ? | OUI — Concerne la spec `comments` (modèle de données, BLoC, endpoints `listReplies` / `reply`) et la spec `manga` (fiche détail qui consomme `CommentsSection` et doit savoir que la profondeur d'affichage est bornée à 2 niveaux visuels). |
| Q4 — Casse un invariant si ignoré ? | OUI — Un dev implémentant reply-to-reply enverrait un `parentCommentId` pointant vers une réponse (non un root), ce que l'API serveur rejette ou accepte silencieusement en produisant un fil incohérent. |

> Validé contre la politique `.claude/rules/06-adr-policy.md`.

## Contexte

Le système de commentaires supporte les réponses à des commentaires de premier niveau. Autoriser des profondeurs arbitraires complexifie le modèle de stockage, la pagination et le rendu mobile (indentation infinie sur petits écrans).

## Décision identifiée

La structure de données est plate : `CommentDto.parentCommentId` ne peut pointer que vers un commentaire root (`parentCommentId == null`). L'API expose `/mangas/comments/:id/replies` pour lister les réponses directes d'un root, et `/mangas/comments/:id/reply` pour poster une réponse. Le BLoC (`PostComment.parentCommentId`) et le service (`CommentsService.reply`) reflètent ce contrat. Il n'existe pas d'endpoint de reply-to-reply.

## Conséquences observées

### Positives
- Modèle de données simple (liste plate + champ `parentCommentId`) facile à paginer et à rendre.
- Pas d'indentation récursive sur mobile — confort de lecture sur petits écrans.
- Chargement des réponses on-demand via `listReplies` sans complexifier la pagination principale.

### Négatives / Dette
- Les discussions longues ("threads") sont impossibles — adapté à un usage commentaire casual, pas à un forum.
- `CommentsBloc` ne charge pas automatiquement les réponses (pas de `LoadReplies` event) — elles restent un appel service direct non géré dans le BLoC.

## Recommandation

Garder pour la cible mobile/web actuelle. Documenter explicitement dans `CommentsService.reply` que `commentId` doit être un root comment.
