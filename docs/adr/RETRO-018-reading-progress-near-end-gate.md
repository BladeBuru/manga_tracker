# RETRO-018 — Validation de la progression de lecture conditionnée à la fin du chapitre (seuil 15%)

| Champ      | Valeur                                          |
|------------|-------------------------------------------------|
| Statut     | Documenté (rétro)                               |
| Date       | 2026-06-04                                      |
| Source     | Rétro-ingénierie                                |
| Features   | reader, library                                 |

## Justification (politique ADR v2.3.0)

| Champ | Valeur |
|-------|--------|
| Catégorie | DATA-MODEL |
| Q1 — Coût de revert > 1j ? | OUI — La règle est implémentée en plusieurs points distincts : `_onWillPop` dans `web_view_io.dart`, `dispose` + `onPopInvoked` dans `offline_reader_view_io.dart`, et `ReadingProgressHelper.isNearEndOfChapter` (partagé). La retirer ou la modifier implique de toucher les deux lecteurs (en ligne et hors-ligne) et de décider d'une alternative cohérente impactant les données de bibliothèque. Refactoring transverse reader + library. |
| Q2 — Non-déductible du code ? | OUI — Le seuil de 15% est un invariant métier (définition de "avoir lu un chapitre") qui n'est visible dans aucun fichier de configuration. Un nouveau dev lisant `LibraryService.saveChapterProgress()` ne pourrait pas déduire que cet appel ne doit être effectué que depuis `ReadingProgressHelper.isNearEndOfChapter`. |
| Q3 — Impact transverse (≥ 2 specs) ? | OUI — Affecte directement la spec `reader` (quand sauvegarder) ET la spec `library` (cohérence des données : un chapitre marqué comme "lu" implique que l'utilisateur était à ≥85% de sa progression). |
| Q4 — Casse un invariant si ignoré ? | OUI — Un développeur ajoutant un nouveau mode de lecture (ex. lecteur image, mode plein écran) qui appelle `LibraryService.saveChapterProgress()` inconditionnellement à la fermeture marquerait les chapitres comme lus dès que l'utilisateur ouvre la première page, corrompant silencieusement l'historique de lecture en bibliothèque. |

> Validé contre la politique `.claude/rules/06-adr-policy.md`.

---

## Contexte

La bibliothèque utilisateur enregistre la progression de lecture (dernier chapitre lu) via `LibraryService.saveChapterProgress(muId, chapter)`. Si cette sauvegarde est déclenchée trop tôt (dès l'ouverture du chapitre, ou à n'importe quel moment de navigation), les données de bibliothèque ne refléteraient pas la lecture réelle de l'utilisateur : les chapitres seraient marqués comme lus même partiellement consultés, faussant les statistiques, les badges "nouveau chapitre", et la recommandation de lecture.

## Décision identifiée

Un chapitre n'est enregistré comme "lu" (`saveChapterProgress`) que si l'utilisateur se trouve dans les **15 derniers pourcents** du contenu scrollable au moment du déclencheur (fermeture du lecteur ou passage au chapitre suivant).

Le calcul est effectué par `ReadingProgressHelper.isNearEndOfChapter(controller)` :
```
percentageFromEnd = (distanceFromEnd / totalDocumentHeight) × 100
isNearEnd = percentageFromEnd <= 15
```

Points d'application dans le code :
1. **Fermeture du lecteur en ligne** (`web_view_io.dart`, `_onWillPop`) — un dialogue de confirmation est affiché si `isNearEnd == true`. Si l'utilisateur confirme, `_commitIfNeeded(chapter)` est appelé.
2. **Passage naturel au chapitre suivant** (`web_view_io.dart`, `_handleDetected` → `ChapterChangeType.nextChapter`) — commit automatique du chapitre précédent SANS vérification `isNearEnd` (le passage à la page suivante est lui-même la preuve de fin de chapitre).
3. **Fermeture du lecteur hors-ligne** (`offline_reader_view_io.dart`, `onPopInvoked` + `dispose`) — `_saveChapterProgress()` appelle `isNearEndOfChapter` avant tout commit.

Cas où le commit est déclenché **sans** vérification `isNearEnd` :
- Passage naturel au chapitre suivant (le changement de page est la confirmation implicite).
- Saut de chapitres : dialogue de confirmation explicite proposé à l'utilisateur.

## Conséquences observées

### Positives
- La bibliothèque reflète fidèlement les chapitres réellement lus (pas de faux positifs).
- Les statistiques de lecture sont cohérentes avec la consommation réelle.
- L'utilisateur n'a pas à interagir pour marquer manuellement chaque chapitre — la détection est automatique.

### Négatives / Dette
- Le seuil de 15% est arbitraire et non configurable par l'utilisateur. Un chapitre dense en texte peut nécessiter plus de temps pour atteindre ce seuil.
- Le passage naturel au chapitre suivant contourne la vérification `isNearEnd` — un utilisateur qui navigue directement vers la fin d'un chapitre via un lien interne du site pourrait voir le chapitre marqué sans l'avoir lu.
- Le code duplique la logique de progression en deux endroits (`web_view_io.dart` et `offline_reader_view_io.dart`) — un seul endroit centralisant cette règle (via un service dédié ou un mixin) réduirait le risque de divergence.
- Dans `dispose()` de `OfflineReaderView`, `_saveChapterProgress()` est appelé sans `await` possible (dispose ne peut pas être async), ce qui rend la sauvegarde non garantie en cas de kill process brutal.

## Recommandation

Garder cette règle — l'invariant est correct métier. Refactoriser à terme en extrayant la logique de commit (vérification `isNearEnd` + appel `saveChapterProgress`) dans un service ou mixin partagé `ReadingSessionService` pour éviter la duplication entre `web_view_io.dart` et `offline_reader_view_io.dart`.
