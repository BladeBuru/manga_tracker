/// Nettoyage du HTML d'un chapitre téléchargé — **fonction pure**.
///
/// Extraite de `offline_reader_view_io.dart` (qui dépassait la limite de
/// 400 lignes) : aucune dépendance Flutter, donc testable directement.
/// Comportement inchangé — déplacement à l'identique.
class OfflineHtmlSanitizer {
  OfflineHtmlSanitizer._();

  /// Nettoie le HTML pour supprimer toutes les références externes (CSS, JS, fonts, scripts de pub)
  /// Utilise des remplacements de chaînes simples pour éviter les problèmes de regex
  static String sanitize(String html) {
    // Supprimer les balises <link> externes (CSS, fonts) mais garder les locales
    int startIndex = 0;
    while (true) {
      final linkStart = html.indexOf('<link', startIndex);
      if (linkStart == -1) break;

      final linkEnd = html.indexOf('>', linkStart);
      if (linkEnd == -1) break;

      final linkTag = html.substring(linkStart, linkEnd + 1);
      if (linkTag.contains('href="http') || linkTag.contains("href='http")) {
        html = html.replaceFirst(linkTag, '');
        startIndex = linkStart;
      } else {
        startIndex = linkEnd + 1;
      }
    }

    // Supprimer les balises <script> externes
    startIndex = 0;
    while (true) {
      final scriptStart = html.indexOf('<script', startIndex);
      if (scriptStart == -1) break;

      final scriptEnd = html.indexOf('</script>', scriptStart);
      if (scriptEnd == -1) break;

      final scriptTag = html.substring(scriptStart, scriptEnd + 9);
      if (scriptTag.contains('src="http') ||
          scriptTag.contains("src='http") ||
          scriptTag.contains('https://') ||
          scriptTag.contains('http://') ||
          scriptTag.contains('goomaphy') ||
          scriptTag.contains('tzegilo') ||
          scriptTag.contains('rlcdn') ||
          scriptTag.contains('ohffs')) {
        html = html.replaceFirst(scriptTag, '');
        startIndex = scriptStart;
      } else {
        startIndex = scriptEnd + 9;
      }
    }

    // Supprimer les balises <iframe> externes
    startIndex = 0;
    while (true) {
      final iframeStart = html.indexOf('<iframe', startIndex);
      if (iframeStart == -1) break;

      final iframeEnd = html.indexOf('</iframe>', iframeStart);
      if (iframeEnd == -1) break;

      final iframeTag = html.substring(iframeStart, iframeEnd + 9);
      if (iframeTag.contains('src="http') || iframeTag.contains("src='http")) {
        html = html.replaceFirst(iframeTag, '');
        startIndex = iframeStart;
      } else {
        startIndex = iframeEnd + 9;
      }
    }

    // Supprimer les @import dans les styles
    html = html.replaceAll('@import url("http', '/* blocked */');
    html = html.replaceAll("@import url('http", '/* blocked */');
    html = html.replaceAll('@import url(http', '/* blocked */');

    // S'assurer qu'il y a une meta viewport simple (comme le ReaderWebView en ligne)
    final viewportIndex = html.indexOf('<meta name="viewport"');
    if (viewportIndex == -1) {
      // Si pas de meta viewport, l'ajouter dans le <head>
      final headIndex = html.indexOf('<head>');
      if (headIndex != -1) {
        final headEnd = html.indexOf('>', headIndex);
        html =
            '${html.substring(0, headEnd + 1)}\n<meta name="viewport" content="width=device-width, initial-scale=1">${html.substring(headEnd + 1)}';
      }
    } else {
      // La meta viewport existe - la REMPLACER par une version simple
      final viewportEnd = html.indexOf('>', viewportIndex);
      if (viewportEnd != -1) {
        html =
            '${html.substring(0, viewportIndex)}<meta name="viewport" content="width=device-width, initial-scale=1">${html.substring(viewportEnd + 1)}';
      }
    }

    // S'assurer que les images et le contenu sont responsives (pas de largeur fixe)
    // Injecter du CSS pour forcer la responsivité
    final styleIndex = html.indexOf('</head>');
    if (styleIndex != -1) {
      const responsiveStyle = '''
<style>
  img {
    max-width: 100% !important;
    height: auto !important;
    width: auto !important;
  }
  body {
    max-width: 100% !important;
    width: 100% !important;
    margin: 0 !important;
    padding: 0 !important;
  }
  * {
    box-sizing: border-box;
  }
</style>
''';
      html = html.substring(0, styleIndex) + responsiveStyle + html.substring(styleIndex);
    }
    return html;
  }
}
