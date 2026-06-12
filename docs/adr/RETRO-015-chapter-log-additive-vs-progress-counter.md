# RETRO-015 — Log de lecture additif séparé du compteur de progression

| Champ      | Valeur              |
|------------|---------------------|
| Statut     | Documenté (rétro)   |
| Date       | 2026-06-04          |
| Source     | Rétro-ingénierie    |
| Features   | library             |

## Justification (politique ADR v2.3.0)

| Champ | Valeur |
|-------|--------|
| Catégorie | DATA-MODEL |
| Q1 — Coût de revert > 1j ? | OUI — fusionner les deux modèles implique un changement de schéma API (l'endpoint `PUT /library/chapter` devrait maintenant aussi insérer un log), une migration des données historiques, la modification de `LibraryService`, `ChapterLogDto`, `StatsService` (qui lit les logs pour les statistiques), et `scroll_position_service` (qui lit et écrit `scrollPosition`) |
| Q2 — Non-déductible du code ? | OUI — la coexistence de deux endpoints distincts (`PUT /library/chapter` et `POST /library/{muId}/chapter-log`) est visible dans le code, mais l'invariant clé — les replays et skips NE MODIFIENT PAS `userReadChapters` — n'est documenté nulle part dans les configs ; il est indiqué uniquement dans le commentaire du DTO et dans le docstring de `recordChapterLog` |
| Q3 — Impact transverse (≥ 2 specs) ? | OUI — impacte `library` (deux endpoints séparés, deux méthodes dans `LibraryService`), `stats` (qui consomme le journal pour calculer les statistiques de lecture), et `reader` (qui appelle `recordChapterLog` + `scrollPosition` à la fin de chaque session de lecture) |
| Q4 — Casse un invariant si ignoré ? | OUI — un dev qui appelle uniquement `recordChapterLog` pensant mettre à jour la progression ne modifiera pas `readChapters` : l'utilisateur verra un `0/X` affiché dans la bibliothèque même après avoir lu des chapitres ; à l'inverse, un dev qui appelle uniquement `saveChapterProgress` ne créera pas d'entrée de log, et les statistiques de lecture seront vierges |

> ✅ Validé contre la politique `.claude/rules/06-adr-policy.md`.

---

## Contexte

La progression de lecture d'un manga a deux dimensions distinctes :

1. **Le pointeur de progression** (`readChapters`) : un entier qui représente jusqu'où l'utilisateur est arrivé. Il est mis à jour par l'utilisateur de façon intentionnelle (ex. "j'ai lu jusqu'au chapitre 42"). C'est ce chiffre qui s'affiche dans la bibliothèque et la barre de progression.

2. **L'historique de lecture** (`chapter_log`) : un journal additif d'entrées immuables qui enregistre chaque session individuelle (avec numéro de chapitre, position de scroll, flag bonus, flag skip). Il sert aux statistiques et permet les replays (relire un chapitre ne fausse pas le pointeur).

Ces deux concepts ont été implémentés comme des chemins de données séparés (Phase 5 du projet, déduit du commentaire dans `ChapterLogDto`).

---

## Décision identifiée

Deux endpoints API distincts, deux méthodes dans `LibraryService`, et deux DTOs différents :

- `PUT /library/chapter` + `saveChapterProgress(muId, readChapters)` : écrit uniquement `userReadChapters`. Mis en queue offline. Utilisé quand l'utilisateur met à jour son avancement global.
- `POST /library/{muId}/chapter-log` + `recordChapterLog(muId, chapterNumber, ...)` : insertion additive dans le journal. Ne modifie PAS `userReadChapters`. Pas de queue offline (commentaire : "si la requête échoue, l'user perd juste une entrée historique, pas son avancement").

L'invariant est documenté dans `ChapterLogDto` :
> "Représente une session de lecture additive (replay, skip, bonus, scroll position) — n'altère PAS le compteur de progression principal `userMangaReadChapters` géré séparément."

---

## Conséquences observées

### Positives

- Les replays (relire un arc entier) et les skips (ignorer un filler) n'altèrent pas le compteur principal — l'avancement affiché reste cohérent avec la position réelle du lecteur.
- Le journal additif permet des statistiques riches (fréquence de lecture, chapitres bonus lus, chapitres ignorés) sans impacter la gestion courante de la bibliothèque.
- La perte du journal offline est acceptable (commentaire explicite) car l'invariant critique (`readChapters`) est lui protégé par la queue.

### Négatives / Dette

- Le lecteur doit appeler les deux méthodes dans le bon ordre pour une session complète : `saveChapterProgress` pour mettre à jour l'avancement, `recordChapterLog` pour enrichir le journal. L'oubli de l'un des deux est silencieux.
- `recordChapterLog` n'a pas de mécanisme offline — une session de lecture hors ligne disparaît du journal (mais pas du compteur). Ce comportement asymétrique peut surprendre.
- Il n'existe pas encore de vue dans l'app qui affiche le journal (`getChapterLog`) — la fonctionnalité est implémentée côté service mais pas exposée à l'utilisateur.

---

## Recommandation

Garder. La séparation est architecturalement correcte et protège l'invariant métier principal (progression affichée = réelle).

À documenter clairement dans le code : les callers qui mettent à jour la progression DOIVENT appeler `saveChapterProgress` (et non `recordChapterLog`) pour que le compteur soit mis à jour. Envisager une méthode façade `recordReadingSession` dans `LibraryService` qui appelle les deux en parallèle le cas échéant.
