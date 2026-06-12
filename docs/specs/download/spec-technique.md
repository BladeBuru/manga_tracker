# Spec Technique — download

| Champ         | Valeur              |
|---------------|---------------------|
| Module        | download            |
| Version       | 0.1.0               |
| Date          | 2026-06-04          |
| Source        | Rétro-ingénierie    |

## Architecture du module

Le module est organisé en trois couches :

**Modèle** : `DownloadedChapter` — données immuables (const), sérialisables JSON, avec statut (`DownloadStatus`), chemins fichiers et métadonnées de lecture (scroll, zoom).

**Services (platform-split)** : deux services exposés via conditional exports (`if (dart.library.html) ...`) :
- `ChapterDownloadService` — orchestre le téléchargement d'un chapitre : fetch HTTP de la page HTML, parsing DOM, téléchargement des images, réécriture des URLs, écriture disque, enregistrement dans le manager.
- `DownloadManagerService` — registre CRUD des chapitres téléchargés : lecture/écriture dans `SharedPreferences` + opérations filesystem (`dart:io`, `path_provider`).

Chaque service a une implémentation `_io.dart` (mobile) et une implémentation `_web.dart` (stub). La façade `service.dart` n'est qu'un re-export conditionnel — elle ne contient aucune logique.

**Vue** : `DownloadsPage` — `StatefulWidget` (pas de BLoC), charge les données dans `initState`, gère l'état local (`_isLoading`, `_downloadedChapters`, `_mangaTitles`, `_totalSize`). Responsive via `LayoutBuilder` (mobile / tablet / desktop ≥ 1200px).

Les services ne sont pas enregistrés dans GetIt : `ChapterDownloadService` et `DownloadManagerService` sont instanciés directement par leurs consommateurs (`ChapterDownloadService` instancie `DownloadManagerService` en interne ; `DownloadsPage` l'instancie directement). Seuls `MangaService` et `Notifier` sont récupérés via GetIt dans la page.

## Fichiers impactés

| Fichier | Rôle | Lignes |
|---------|------|--------|
| `lib/features/download/models/downloaded_chapter.model.dart` | Modèle + enum `DownloadStatus` | ~109 |
| `lib/features/download/services/chapter_download_service.dart` | Façade conditionnelle (re-export) | ~9 |
| `lib/features/download/services/chapter_download_service_io.dart` | Impl mobile : fetch HTML + images + réécriture DOM | ~339 |
| `lib/features/download/services/chapter_download_service_web.dart` | Stub web : UnsupportedError / no-op | ~34 |
| `lib/features/download/services/download_manager_service.dart` | Façade conditionnelle (re-export) | ~14 |
| `lib/features/download/services/download_manager_service_io.dart` | Impl mobile : CRUD SharedPreferences + File/Directory | ~331 |
| `lib/features/download/services/download_manager_service_web.dart` | Stub web : no-op, retourne valeurs vides | ~43 |
| `lib/features/download/views/downloads_page.dart` | Vue liste téléchargements + actions | ~308 |

## Schéma BDD (si applicable)

Pas de base de données relationnelle. Double persistance :

**SharedPreferences** (clé `downloaded_chapters`) :
```json
{
  "<muId_int>": [
    {
      "muId": 123,
      "chapterNumber": 42,
      "downloadDate": "2026-01-15T10:30:00.000",
      "imageCount": 0,
      "imagePaths": [],
      "htmlPath": "/data/user/0/.../chapters/Naruto/42/chapter.html",
      "status": "completed",
      "errorMessage": null,
      "scrollPosition": null,
      "zoomLevel": null
    }
  ]
}
```

**Filesystem** (sous `<applicationDocumentsDirectory>/chapters/`) :
```
chapters/
  <manga_title_sanitized>/
    <chapter_number>/
      chapter.html        ← HTML complet avec URLs réécrites en chemins relatifs
      metadata.json       ← sérialisation JSON de DownloadedChapter
      images/
        image_0.jpg
        image_1.png
        ...
```

Les noms de fichiers images sont déduits du segment final de l'URL d'origine. Si l'URL ne produit pas d'extension, le fichier est nommé `image_<index>.jpg`.

## API / Endpoints (si applicable)

Pas d'endpoint API applicatif consommé par ce module. Les URLs de chapitres sont des URLs de sites tiers (sites de scan). La requête HTTP est faite directement par `ChapterDownloadService` avec injection de cookies et headers simulant un navigateur.

`MangaService.getMangaDetail(muId)` est appelé dans `DownloadsPage` uniquement pour résoudre les titres d'affichage.

## Patterns identifiés

- **Conditional exports** pour le platform-split : `export 'impl_io.dart' if (dart.library.html) 'impl_web.dart'` — identique à la feature `reader` (webview) et `manga` (webview). Décision partagée documentée en RETRO-017.
- **StatefulWidget sans BLoC** : `DownloadsPage` gère son état localement. Cohérent avec les autres pages "utilitaires" du projet (search, recommendations).
- **Double persistance (SharedPreferences + fichier)** : les métadonnées sont écrites dans `SharedPreferences` pour les lectures rapides (listes, checks `isChapterDownloaded`) et dans un `metadata.json` sur disque pour la cohérence au niveau du filesystem.
- **Fallback rétrocompatibilité dans la suppression** : `removeDownloadedChapter` tente de supprimer les dossiers avec le titre du manga, puis avec `muId.toString()` (ancien schéma), puis scanne tout le répertoire de base. Indique un changement de schéma de nommage en cours de vie du projet.
- **Callback de progression** : `onProgress(double)` de 0.0 à 1.0 — 0.5 alloué au fetch HTML, 0.5 aux images.

## Décisions techniques documentées en spec (hors ADR)

**File d'attente et concurrence** : il n'existe pas de file d'attente dans le code. Plusieurs téléchargements simultanés sont techniquement possibles sans garde-fou. Les statuts `DownloadStatus.downloading` et `DownloadStatus.paused` sont définis mais non utilisés.

**Cookies anti-bot** : `_downloadHtmlPage` lit `SharedPreferences` sous la clé `cookies_<domain>` et les injecte dans les headers HTTP. Cette clé est écrite par le WebView de la feature reader (convention implicite entre modules, non formalisée). Une erreur 403 en l'absence de cookies produit un log mais ne lève pas d'exception — le téléchargement échoue silencieusement avec `htmlPath == null`, ce qui remonte en `Exception` dans `downloadChapter`.

**imageCount toujours à 0** : le modèle `DownloadedChapter` est créé avec `imageCount: 0` avant le traitement des images et n'est pas mis à jour après. Ce champ n'est pas affiché dans l'UI actuelle.

**`<base href="file://<chapterPath>/">` dans le HTML** : une balise `<base>` est injectée dans le `<head>` pour que les ressources CSS/JS restantes du site source soient résolues en local. Les ressources non téléchargées (scripts, polices) ne seront pas disponibles hors-ligne.

## Tests existants

| Fichier | Ce qu'il teste | Statut |
|---------|---------------|--------|
| _(aucun)_ | Aucun test unitaire ou widget test pour cette feature | Absent |

La feature `download` n'a aucun test. Les chemins critiques non couverts incluent : la logique de réécriture des URLs dans `processHtmlForOffline`, la sérialisation/désérialisation de `DownloadedChapter`, et la gestion des erreurs HTTP dans `_downloadHtmlPage`.
