import 'package:flutter_inappwebview/flutter_inappwebview.dart';
import 'package:mangatracker/features/reader/utils/webview_result_parser.dart';

/// Mesures brutes d'une page de lecture, telles que la WebView les rapporte.
class ReaderViewportMetrics {
  const ReaderViewportMetrics({
    required this.scrollY,
    required this.viewportHeight,
    required this.documentHeight,
    required this.ready,
  });

  /// Défilement courant, en pixels CSS.
  final double scrollY;

  /// Hauteur visible.
  final double viewportHeight;

  /// Hauteur totale du document — elle **grandit** au fil du chargement des
  /// images d'un scan, d'où les vérifications répétées côté restauration.
  final double documentHeight;

  /// `document.readyState` exploitable : viser une position sur un document
  /// pas encore prêt revient à viser à vide.
  final bool ready;

  /// Course de défilement disponible ; `<= 0` quand la page tient à l'écran.
  double get maxScroll => documentHeight - viewportHeight;
}

/// Interroge la page de lecture — **le seul endroit** qui parle JavaScript à
/// la WebView pour connaître la position.
///
/// Séparé de `ScrollPositionService` parce que ce sont deux responsabilités :
/// **mesurer** une page, et **mémoriser** une position. Le service repassait
/// au passage au-dessus de la limite de 300 lignes.
///
/// Chaque retour est normalisé par [WebViewResultParser] : Android rend une
/// `Map`, iOS et le web une chaîne JSON, et confondre les deux rendait les
/// garde-fous inertes sur la moitié des plateformes.
class ReaderViewportProbe {
  const ReaderViewportProbe();

  static const String measureScript = """
    (function() {
      const docEl = document.scrollingElement || document.documentElement;
      const body = document.body;
      return {
        scrollY: window.scrollY || window.pageYOffset || docEl.scrollTop || 0,
        viewportHeight: window.innerHeight || docEl.clientHeight || 0,
        documentHeight: Math.max(
          body ? body.scrollHeight : 0,
          body ? body.offsetHeight : 0,
          docEl.scrollHeight || 0,
          docEl.offsetHeight || 0
        ),
        ready: document.readyState === 'complete' ||
               document.readyState === 'interactive'
      };
    })();
  """;

  static const String _imagesLoadedScript = """
    (function() {
      const images = document.querySelectorAll('img');
      if (images.length === 0) return true;
      for (let i = 0; i < images.length; i++) {
        if (!images[i].complete || images[i].naturalHeight === 0) return false;
      }
      return true;
    })();
  """;

  /// `null` si la page n'a rien rendu d'exploitable — on préfère ne rien
  /// savoir à savoir faux.
  Future<ReaderViewportMetrics?> measure(
    InAppWebViewController controller,
  ) async {
    final map = WebViewResultParser.asMap(
      await controller.evaluateJavascript(source: measureScript),
    );
    if (map == null) return null;

    final scrollY = WebViewResultParser.numberAt(map, 'scrollY');
    final viewportHeight = WebViewResultParser.numberAt(map, 'viewportHeight');
    final documentHeight = WebViewResultParser.numberAt(map, 'documentHeight');
    if (scrollY == null || viewportHeight == null || documentHeight == null) {
      return null;
    }
    return ReaderViewportMetrics(
      scrollY: scrollY,
      viewportHeight: viewportHeight,
      documentHeight: documentHeight,
      ready: WebViewResultParser.asBool(map['ready']),
    );
  }

  /// Amène la page à [offset] pixels.
  Future<void> scrollTo(
    InAppWebViewController controller,
    double offset,
  ) =>
      controller.evaluateJavascript(source: 'window.scrollTo(0, $offset);');

  /// Attend le chargement des images, 10 s au plus (les lecteurs lents
  /// dépassaient les 5 s d'origine, cf. hotfix-v0-10-1 US-4).
  Future<void> waitForImages(InAppWebViewController controller) async {
    for (var attempt = 0; attempt < 50; attempt++) {
      await Future<void>.delayed(const Duration(milliseconds: 200));
      final raw =
          await controller.evaluateJavascript(source: _imagesLoadedScript);
      if (WebViewResultParser.asBool(raw)) return;
    }
  }
}
