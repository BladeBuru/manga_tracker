# Spec Fonctionnelle — download [DRAFT — à valider par le dev]

| Champ      | Valeur              |
|------------|---------------------|
| Module     | download            |
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
| [RETRO-017](../../adr/RETRO-017-platform-split-conditional-exports.md) | Platform-split via conditional exports Dart (io/web) — ADR canonique transverse (reader, download, manga) | Documenté (rétro) |
| [RETRO-022](../../adr/RETRO-022-double-storage-metadata.md) | Double stockage des métadonnées de téléchargement (SharedPreferences + fichier disque) | Documenté (rétro) |
| [RETRO-023](../../adr/RETRO-023-html-complet-images-locales.md) | Stratégie offline : HTML complet avec réécriture des URLs d'images en chemins locaux | Documenté (rétro) |

> *Table auto-générée par adr-linker. Ne pas éditer manuellement.*

---

## Contexte et objectif

Le module `download` permet à l'utilisateur de télécharger des chapitres de manga pour les lire sans connexion internet. Le téléchargement consiste à récupérer la page HTML complète d'un chapitre (telle qu'affichée sur le site source), à en extraire et télécharger toutes les images, puis à réécrire les URLs dans le HTML pour pointer vers les fichiers locaux. Le résultat est un bundle autonome lisible hors-ligne via le lecteur offline de la feature `reader`.

La feature est **mobile-only** (Android/iOS) : sur le web Flutter, tous les points d'entrée déclenchent une `UnsupportedError` ou retournent des valeurs vides, et l'UI masque les boutons de téléchargement via `kIsWeb`.

## Règles métier (déduites du code)

1. Un chapitre téléchargé est identifié par le couple `(muId, chapterNumber)`. Si le même couple est retéléchargé, l'entrée existante est remplacée (pas de doublons).
2. Les fichiers sont stockés dans `<applicationDocumentsDirectory>/chapters/<manga_title_sanitized>/<chapter_number>/`. Le titre du manga est utilisé comme nom de dossier (caractères spéciaux remplacés par `_`).
3. Le téléchargement produit au minimum un fichier `chapter.html` contenant le HTML entier de la page, avec les URLs d'images réécrites en chemins relatifs locaux (`images/<filename>`).
4. Les images sont téléchargées dans un sous-dossier `images/`. Seules les images répondant avec HTTP 200 sont sauvegardées — les images en erreur (403 inclus) sont ignorées silencieusement et leurs URLs originales sont conservées dans le HTML.
5. Les cookies de session WebView du domaine source (stockés dans `SharedPreferences` sous la clé `cookies_<domain>`) sont injectés dans la requête HTTP du téléchargement pour contourner les protections anti-bot. Si aucun cookie n'est disponible, le téléchargement est tenté sans cookie.
6. Un fichier `metadata.json` est écrit dans le dossier du chapitre. Les métadonnées du chapitre sont également persistées dans `SharedPreferences` (clé `downloaded_chapters`) pour un accès rapide sans lecture disque.
7. La suppression d'un chapitre efface à la fois l'entrée `SharedPreferences` et le dossier disque correspondant. La suppression cherche également dans les anciens chemins (muId.toString() comme nom de dossier) pour assurer la rétrocompatibilité.
8. La progression du téléchargement est communiquée au call site via un callback `onProgress` (double de 0.0 à 1.0) : 0 à 0.5 pour le HTML, 0.5 à 1.0 pour les images.
9. Sur le web, `DownloadManagerService` retourne toujours des valeurs vides (no-op) sans lever d'erreur. `ChapterDownloadService.downloadChapter()` lève `UnsupportedError` sur le web — les call sites doivent garder avec `kIsWeb`.

## Cas d'usage (déduits)

### CU-001 — Télécharger un chapitre depuis la fiche manga
L'utilisateur, sur mobile, déclenche le téléchargement d'un chapitre depuis la fiche détail du manga. `ChapterDownloadService.downloadChapter()` est appelé avec le `muId`, le numéro de chapitre, l'URL de la page et le titre du manga. Le service crée le dossier, télécharge le HTML (avec les cookies WebView si disponibles), traite les images, écrit `chapter.html` + `metadata.json`, puis enregistre le chapitre dans `DownloadManagerService`.

### CU-002 — Consulter la liste des téléchargements
L'utilisateur ouvre la page "Téléchargements" depuis le profil. `DownloadsPage` charge tous les chapitres via `DownloadManagerService.getAllDownloadedChapters()`, regroupe par manga, affiche la taille totale et les titres des mangas (récupérés via `MangaService`). L'affichage est responsive (mobile / tablette / desktop).

### CU-003 — Lire un chapitre téléchargé
Depuis `DownloadsPage`, l'utilisateur tape sur un chapitre ou clique sur l'icône "lire". La navigation go_router envoie vers `/manga/<muId>/read-offline?chapter=<chapterNumber>` avec les extras `OfflineReaderExtras`.

### CU-004 — Supprimer un chapitre ou tous les chapitres d'un manga
L'utilisateur supprime un chapitre individuel ou tous les chapitres d'un manga depuis `DownloadsPage`. Une confirmation est demandée. Le service efface les fichiers disque et met à jour les `SharedPreferences`.

### CU-005 — Supprimer tous les téléchargements
L'utilisateur supprime l'ensemble des téléchargements via l'icône poubelle de l'AppBar de `DownloadsPage`. Le dossier de base `chapters/` est supprimé récursivement et le registre `SharedPreferences` est vidé.

## Dépendances

- `lib/features/reader/` — `OfflineReaderExtras`, route `/manga/:muId/read-offline` (consomme le `htmlPath` produit par cette feature)
- `lib/features/manga/services/manga.service.dart` — `getMangaDetail()` pour résoudre les titres dans `DownloadsPage`
- `lib/core/service_locator/` — GetIt pour `MangaService` et `Notifier`
- `lib/core/notifier/` — Notifications de succès après suppression
- `lib/core/router/app_router.dart` — Route offline reader + `OfflineReaderExtras`
- `package:path_provider` — `getApplicationDocumentsDirectory()` pour le chemin de base
- `package:shared_preferences` — Persistance du registre et des cookies WebView
- `package:http` — Téléchargement HTTP des pages et images
- `package:html` (html_parser) — Parsing et manipulation du DOM HTML

## Zones d'incertitude

> Les points suivants n'ont pas pu être déterminés par le code seul :
- Le champ `imageCount` du modèle `DownloadedChapter` est initialisé à `0` et n'est jamais mis à jour après le téléchargement des images. Est-ce voulu (non affiché) ou un oubli ?
- `DownloadStatus.paused` et `DownloadStatus.downloading` sont définis dans l'enum mais jamais utilisés dans les flux actuels. Une file d'attente ou une mise en pause était-elle prévue ?
- La page `DownloadsPage` instancie `DownloadManagerService` directement (`final _downloadManager = DownloadManagerService()`) sans passer par GetIt. Est-ce intentionnel (service léger) ou une omission d'enregistrement ?
- La gestion des cookies (`cookies_<domain>` dans SharedPreferences) suppose que le `WebViewService` (feature `reader`) écrit ces cookies. La coordination entre les deux features n'est pas documentée.
- L'absence de limitation de la concurrence des téléchargements (pas de sémaphore, pas de file d'attente) : peut-on déclencher plusieurs téléchargements simultanés sans dégradation ?
