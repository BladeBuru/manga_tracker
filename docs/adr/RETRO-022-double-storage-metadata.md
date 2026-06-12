# RETRO-022 — Double stockage des métadonnées de téléchargement (SharedPreferences + fichier disque)

| Champ      | Valeur                          |
|------------|---------------------------------|
| Statut     | Documenté (rétro)               |
| Date       | 2026-06-04                      |
| Source     | Rétro-ingénierie                |
| Features   | download                        |

## Justification (politique ADR v2.3.0)

| Champ | Valeur |
|-------|--------|
| Catégorie | DB-STRATEGY |
| Q1 — Coût de revert > 1j ? | OUI — Migrer vers un stockage unique (uniquement SharedPreferences ou uniquement fichier) nécessiterait de modifier `ChapterDownloadService._saveMetadata()`, `DownloadManagerService._saveAllChapters()`, la logique de suppression dans `removeDownloadedChapter()` (qui efface les deux stores), et potentiellement le reader offline s'il lit `metadata.json` directement. Impact transverse entre deux services et une feature adjacente. |
| Q2 — Non-déductible du code ? | OUI — `pubspec.yaml` montre `shared_preferences` et `path_provider` mais ne dit pas pourquoi les métadonnées sont écrites aux deux endroits simultanément. L'intention (SharedPreferences pour accès rapide sans I/O disque, fichier pour cohérence du bundle offline) n'est déductible que par lecture du code et de cet ADR. |
| Q3 — Impact transverse (≥ 2 specs) ? | OUI — La feature `download` produit les deux stores ; la feature `reader` consomme `htmlPath` (filesystem) depuis le modèle `DownloadedChapter` récupéré via `DownloadManagerService` (SharedPreferences). Les deux specs sont contraintes par cette décision. |
| Q4 — Casse un invariant si ignoré ? | OUI — Un dev qui n'écrit que dans SharedPreferences (sans `metadata.json`) laisse le bundle disque incohérent — si les SharedPreferences sont vidées (réinstallation, effacement données app), il n'existe plus de source de vérité pour reconstruire le registre. Inversement, n'écrire que le fichier sans mettre à jour SharedPreferences fait que `isChapterDownloaded()` retourne `false` alors que le bundle est présent sur disque. |

> Validé contre la politique `.claude/rules/06-adr-policy.md`.

## Contexte

Le téléchargement d'un chapitre produit un bundle de fichiers sur le filesystem (`chapter.html` + `images/`). L'application doit pouvoir : (1) lister rapidement tous les chapitres téléchargés sans scanner le disque, (2) fournir les chemins de fichiers au lecteur offline, (3) survivre à une désynchronisation partielle (ex : fichiers présents mais registre corrompu).

## Décision identifiée

Chaque chapitre téléchargé est persisté dans **deux endroits simultanément** :

1. **SharedPreferences** (clé `downloaded_chapters`) : registre JSON de tous les `DownloadedChapter` indexé par `muId`. Mis à jour par `DownloadManagerService.addDownloadedChapter()` et nettoyé par les opérations de suppression. Utilisé pour `isChapterDownloaded()`, `getAllDownloadedChapters()`, le calcul de taille totale.

2. **Fichier `metadata.json`** dans le dossier du chapitre : copie JSON du même `DownloadedChapter`, écrit par `ChapterDownloadService._saveMetadata()` après chaque téléchargement réussi. Sert de source de vérité locale au niveau du bundle disque.

Les deux stores sont écrits séquentiellement dans `ChapterDownloadService.downloadChapter()` : `_saveMetadata()` puis `_downloadManager.addDownloadedChapter()`.

## Conséquences observées

### Positives
- `DownloadManagerService.getAllDownloadedChapters()` est O(1) en termes d'I/O disque (lecture d'une seule clé SharedPreferences), indépendamment du nombre de chapitres téléchargés.
- Le `metadata.json` sur disque permet une reconstruction future du registre si les SharedPreferences sont perdues (réinstallation, migration).

### Négatives / Dette
- Risque de désynchronisation : si `_saveMetadata()` réussit mais que `addDownloadedChapter()` échoue (ex : SharedPreferences inaccessibles), le bundle disque existe mais n'est pas référencé dans le registre.
- La suppression dans `removeDownloadedChapter()` efface le dossier disque (et donc le `metadata.json`) mais pas les SharedPreferences séparément — le code fait les deux, mais l'ordre et la gestion d'erreur partielle ne sont pas atomiques.
- Aucune procédure de re-synchronisation (scan disque → reconstruction des SharedPreferences) n'est implémentée.

## Recommandation

Garder, mais documenter le risque de désynchronisation. À terme, implémenter une fonction de "réparation du registre" qui scanne `<applicationDocumentsDirectory>/chapters/` et reconstruit les SharedPreferences depuis les `metadata.json` présents sur disque.
