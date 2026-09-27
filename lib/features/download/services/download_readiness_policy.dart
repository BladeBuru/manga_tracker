import 'chapter_image_source.dart';

/// Relevé d'une page, pris dans le lecteur avant un téléchargement.
class DownloadPageProbe {
  const DownloadPageProbe({
    required this.readyState,
    required this.urlChapter,
    required this.images,
  });

  /// `document.readyState` (`loading`, `interactive`, `complete`).
  final String readyState;

  /// Chapitre lu dans l'URL courante (`null` si illisible).
  final int? urlChapter;

  /// Chaque `<img>` : attributs utiles et largeur affichée (px CSS).
  final List<ProbedImage> images;

  /// Images de chapitre : adresse réelle connue, et soit affichées en grand,
  /// soit chargées en différé (les sites ne diffèrent que les pages du
  /// chapitre — logos et avatars ne comptent pas).
  int get chapterImageCount => images
      .where((image) =>
          ChapterImageSource.pick(image.attributes) != null &&
          (image.width >= DownloadReadinessPolicy.chapterImageMinWidth ||
              ChapterImageSource.hasLazyAttribute(image.attributes)))
      .length;
}

class ProbedImage {
  const ProbedImage({required this.attributes, required this.width});

  final Map<String, String> attributes;
  final int width;
}

enum DownloadReadiness {
  /// Pas encore : relever de nouveau un peu plus tard.
  wait,

  /// Télécharger maintenant.
  ready,

  /// La page n'est pas le chapitre demandé (redirection) : échec.
  wrongChapter,

  /// Délai dépassé sans aucune image de chapitre : échec.
  timedOut,
}

/// Décide QUAND une page de chapitre peut être téléchargée — pur.
///
/// Remplace un délai fixe de 2 s après `onLoadStop`, déclenché par la seule
/// présence d'un cookie `cf_clearance` — déjà là sur la page de
/// vérification « Un instant… » : le téléchargement partait avant que la
/// page ait chargé et enregistrait un chapitre vide.
class DownloadReadinessPolicy {
  const DownloadReadinessPolicy({
    this.timeout = const Duration(seconds: 25),
    this.minChapterImages = 1,
  });

  /// Au-delà, on télécharge ce qu'il y a (s'il y a au moins une image) ou
  /// on abandonne.
  final Duration timeout;

  final int minChapterImages;

  /// Largeur (px CSS) à partir de laquelle une image affichée est une page.
  static const int chapterImageMinWidth = 200;

  DownloadReadiness decide({
    required int expectedChapter,
    required DownloadPageProbe current,
    required DownloadPageProbe? previous,
    required Duration elapsed,
  }) {
    final urlChapter = current.urlChapter;
    if (urlChapter != null && urlChapter != expectedChapter) {
      return DownloadReadiness.wrongChapter;
    }
    final count = current.chapterImageCount;
    if (elapsed >= timeout) {
      return count >= minChapterImages
          ? DownloadReadiness.ready
          : DownloadReadiness.timedOut;
    }
    if (current.readyState != 'complete') return DownloadReadiness.wait;
    if (count < minChapterImages) return DownloadReadiness.wait;
    // Stable d'un relevé à l'autre : les lecteurs rendus en JavaScript
    // ajoutent leurs pages progressivement.
    if (previous == null || previous.chapterImageCount != count) {
      return DownloadReadiness.wait;
    }
    return DownloadReadiness.ready;
  }
}
