# RETRO-049 — Soft-delete : contenu remplacé côté client par un placeholder fixe

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
| Q1 — Coût de revert > 1j ? | OUI — Modifier ce comportement imposerait de changer le BLoC (`_onDelete`), le rendu `CommentTile` (style italic/couleur pour `isDeleted`), les tests associés, et le contrat implicite avec le serveur (qui renvoie `isDeleted: true` sans contenu) ; impact transverse BLoC + widget + DTO. |
| Q2 — Non-déductible du code ? | OUI — `pubspec.yaml` et les configs ne révèlent pas que la suppression est un soft-delete avec remplacement de contenu par `'[supprimé]'` plutôt qu'une suppression du item dans la liste ; l'intention architecturale (préserver la structure du fil) n'est visible que dans le BLoC. |
| Q3 — Impact transverse (≥ 2 specs) ? | OUI — Concerne la spec `comments` (comportement BLoC + rendu) et la spec `manga` (fiche détail qui embarque `CommentsSection` et présente le fil). |
| Q4 — Casse un invariant si ignoré ? | OUI — Un dev ignorant cette décision pourrait retirer l'item de la liste lors d'un delete, cassant la continuité du fil (les réponses à un commentaire supprimé perdraient leur ancrage visuel). |

> Validé contre la politique `.claude/rules/06-adr-policy.md`.

## Contexte

Les commentaires peuvent être supprimés par leur auteur. Le serveur applique un soft-delete : il conserve la ligne en base avec `isDeleted: true` et efface le contenu, afin de préserver la structure du fil (les réponses imbriquées restent rattachées à un parent existant).

Côté Flutter, le BLoC reçoit la confirmation de suppression du serveur et doit mettre à jour la liste locale immédiatement, sans recharger la page entière.

## Décision identifiée

Lors d'un `DeleteComment`, le BLoC (`_onDelete` dans `comments_bloc.dart`) ne retire pas l'item de `items` mais le remplace par un `CommentDto` avec `content: '[supprimé]'`, `isDeleted: true`, et `rating: null`. `CommentTile` affiche ce contenu en italique avec la couleur `onSurfaceVariant`.

## Conséquences observées

### Positives
- La structure du fil est préservée : les réponses à un commentaire supprimé restent visibles et rattachées.
- Le feedback utilisateur est immédiat (optimistic update) sans round-trip réseau supplémentaire.
- Le rendu `[supprimé]` est cohérent avec les conventions d'autres plateformes (Reddit, forums).

### Négatives / Dette
- Le texte `'[supprimé]'` est hardcodé dans le BLoC (`comments_bloc.dart` ligne 125), contournant le système i18n. Il devrait être externalisé en clé ARB.
- Si le serveur renvoie un contenu différent pour un commentaire supprimé, la valeur locale diverge jusqu'au prochain rechargement.

## Recommandation

Garder. Externaliser `'[supprimé]'` vers une clé ARB (`commentsDeletedContent`) pour respecter les 7 langues.
