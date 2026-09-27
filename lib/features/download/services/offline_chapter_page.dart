import 'package:html/dom.dart';

/// Page hors ligne « images seules » d'un chapitre téléchargé — pur.
///
/// Hors ligne, le HTML complet du site s'affiche mal (feuilles de style non
/// téléchargées) et n'apporte rien : menus, commentaires, scripts et
/// publicités. On ne garde que les pages du chapitre, empilées en pleine
/// largeur sur fond sombre. Une page presque sans images (roman / novel) garde
/// son HTML complet : le texte EST le contenu.
class OfflineChapterPage {
  const OfflineChapterPage._();

  /// En dessous, la page est considérée comme textuelle (HTML complet gardé).
  static const int minImages = 3;

  /// Part minimale des images enregistrées que doit contenir le conteneur
  /// retenu comme « zone de lecture » (le logo et les avatars du site sont
  /// hors de cette zone). La moitié suffit : un chapitre court (4 pages)
  /// avec un logo et un avatar garde ainsi sa zone de lecture.
  static const double readingAreaShare = 0.5;

  /// Préfixe des images enregistrées localement (voir
  /// `ChapterDownloadService.processHtmlForOfflineReport`).
  static const String localImagePrefix = 'images/';

  /// Adresses locales des pages du chapitre, dans l'ordre de lecture —
  /// ou `null` si la page n'est pas un chapitre en images.
  static List<String>? chapterImages(Document document) {
    final saved = document
        .querySelectorAll('img')
        .where((img) =>
            (img.attributes['src'] ?? '').startsWith(localImagePrefix))
        .toList();
    if (saved.length < minImages) return null;

    // Zone de lecture : le conteneur le PLUS PRÉCIS (le plus profond) qui
    // regroupe l'essentiel des images enregistrées.
    final counts = <Element, int>{};
    final depths = <Element, int>{};
    for (final img in saved) {
      final ancestors = <Element>[];
      for (var node = img.parent; node != null; node = node.parent) {
        ancestors.add(node);
      }
      for (var i = 0; i < ancestors.length; i++) {
        final element = ancestors[i];
        counts[element] = (counts[element] ?? 0) + 1;
        depths[element] = ancestors.length - i;
      }
    }
    final needed = (saved.length * readingAreaShare).ceil();
    Element? area;
    for (final entry in counts.entries) {
      if (entry.value < needed) continue;
      if (area == null || depths[entry.key]! > depths[area]!) area = entry.key;
    }

    final pages = saved
        .where((img) => area == null || _isInside(img, area))
        .map((img) => img.attributes['src']!)
        .toList();
    return pages.length < minImages ? null : pages;
  }

  /// Page minimale : les pages du chapitre, et rien d'autre.
  static String build({
    required String title,
    required String baseHref,
    required List<String> images,
  }) {
    final buffer = StringBuffer()
      ..write('<!DOCTYPE html><html><head><meta charset="utf-8">')
      ..write('<meta name="viewport" content="width=device-width, initial-scale=1">')
      ..write('<base href="${_escape(baseHref)}">')
      ..write('<title>${_escape(title)}</title>')
      ..write('<style>html,body{margin:0;padding:0;background:#111;}'
          'img{display:block;width:100%;height:auto;margin:0 auto;}</style>')
      ..write('</head><body>');
    for (final src in images) {
      buffer.write('<img src="${_escape(src)}" alt="" loading="lazy">');
    }
    buffer.write('</body></html>');
    return buffer.toString();
  }

  static bool _isInside(Element element, Element ancestor) {
    for (var node = element.parent; node != null; node = node.parent) {
      if (identical(node, ancestor)) return true;
    }
    return false;
  }

  static String _escape(String value) => value
      .replaceAll('&', '&amp;')
      .replaceAll('"', '&quot;')
      .replaceAll('<', '&lt;')
      .replaceAll('>', '&gt;');
}
