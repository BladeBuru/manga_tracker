/// File des détections de chapitre du lecteur — **sérialisée et idempotente**,
/// pure (ni Flutter, ni GetIt, ni WebView). Testée par
/// `test/features/reader/chapter_detection_queue_test.dart`.
///
/// Invariant « une navigation = un seul enregistrement » (CLAUDE.md) : la
/// même navigation est signalée jusqu'à trois fois par la WebView
/// (`shouldOverrideUrlLoading`, `onLoadStart`, `onUpdateVisitedHistory`), et
/// le numéro lu dans la page arrive par d'autres rappels (titre, fin de
/// chargement, relectures). Sans cette file, une navigation produisait
/// plusieurs PUT, notifications et entrées de journal.
///
/// - Un seul traitement à la fois ; ce qui arrive pendant un traitement
///   attend (profondeur 1 : le plus récent gagne).
/// - Deux places d'attente distinctes, URL et page : un numéro lu dans la
///   page n'évince jamais une URL en attente (ni l'inverse). L'URL passe
///   d'abord — c'est elle qui fait foi quand elle porte un numéro.
/// - Idempotence : une URL n'est traitée qu'une fois ; un signal de page
///   l'est une fois par couple (URL, chapitre). La clé inclut le chapitre :
///   après un `pushState`, l'URL nouvelle est déjà « traitée » (sans numéro)
///   quand le titre de la page se met à jour.
library;

/// Une détection à traiter : une URL, ou un chapitre lu dans la page
/// affichée à cette URL.
class ChapterDetection {
  const ChapterDetection.url(this.uri) : pageChapter = null;
  const ChapterDetection.page(this.uri, int chapter) : pageChapter = chapter;

  final Uri uri;

  /// Numéro lu dans la page, `null` pour une détection d'URL.
  final int? pageChapter;

  bool get fromPage => pageChapter != null;

  String get key => fromPage ? '$uri#mt-page-chapter=$pageChapter' : '$uri';

  @override
  String toString() => fromPage ? 'page($uri, $pageChapter)' : 'url($uri)';
}

class ChapterDetectionQueue {
  ChapterDetectionQueue(this._apply, {void Function(Object error)? onError})
      : _onError = onError;

  final Future<void> Function(ChapterDetection detection) _apply;
  final void Function(Object error)? _onError;

  bool _processingDetection = false;
  ChapterDetection? _pendingUrl;
  ChapterDetection? _pendingPage;
  String? _lastHandledUrl;
  String? _lastHandledPage;
  Future<void> _drain = Future<void>.value();

  /// Un traitement est en cours.
  bool get isProcessing => _processingDetection;

  /// Ajoute [detection] ; le futur se termine quand elle a été traitée (ou
  /// écartée), ce qui permet d'attendre le bon chapitre avant de restaurer
  /// une position.
  Future<void> add(ChapterDetection detection) {
    if (_alreadyHandled(detection)) {
      return _processingDetection ? _drain : Future<void>.value();
    }
    if (_processingDetection) {
      if (detection.fromPage) {
        _pendingPage = detection;
      } else {
        _pendingUrl = detection;
      }
      return _drain;
    }
    return _drain = _run(detection);
  }

  bool _alreadyHandled(ChapterDetection d) =>
      d.key == (d.fromPage ? _lastHandledPage : _lastHandledUrl);

  Future<void> _run(ChapterDetection first) async {
    // Posé avant le premier `await` : les appels suivants voient la file
    // occupée et se mettent en attente.
    _processingDetection = true;
    try {
      var url = first.fromPage ? null : first;
      var page = first.fromPage ? first : null;
      while (url != null || page != null) {
        if (url != null) await _handle(url);
        if (page != null) await _handle(page);
        url = _pendingUrl;
        page = _pendingPage;
        _pendingUrl = null;
        _pendingPage = null;
      }
    } finally {
      _processingDetection = false;
    }
  }

  Future<void> _handle(ChapterDetection d) async {
    if (_alreadyHandled(d)) return;
    // Mémorisée AVANT le traitement : un doublon qui arrive pendant celui-ci
    // est écarté.
    if (d.fromPage) {
      _lastHandledPage = d.key;
    } else {
      _lastHandledUrl = d.key;
    }
    try {
      await _apply(d);
    } catch (e) {
      // Une détection en échec ne bloque pas les suivantes.
      _onError?.call(e);
    }
  }
}
