/// Façade conditionnelle pour `ReaderWebView`.
///
/// **Mobile** : WebView complet (`flutter_inappwebview`) avec téléchargement,
///   ad-blocker, captcha detection, scroll position tracking.
/// **Web** : redirection vers le lien externe via `url_launcher` (pas de
///   webview embarqué possible côté navigateur — sécurité iframe X-Frame-Options).
library;

export 'web_view_io.dart'
    if (dart.library.html) 'web_view_web.dart';
