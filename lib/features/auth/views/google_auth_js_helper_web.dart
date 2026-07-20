import 'dart:js_interop';

/// Interop `dart:js_interop` (remplace `dart:js` déprécié) avec les
/// fonctions définies dans `web/index.html`.
@JS('openGoogleOAuthPopup')
external JSAny? _openGoogleOAuthPopup(JSString url);

@JS('__googleAuthResult')
external JSAny? _googleAuthResult;

/// Ouvre la popup Google OAuth via window.open() sans "noopener"
/// afin que window.opener soit disponible dans la popup pour le postMessage.
///
/// Retourne `false` si le navigateur a bloqué la popup. À appeler dans la
/// section SYNCHRONE d'un handler de tap (user activation), sinon
/// Brave/Safari bloquent systématiquement.
bool openGoogleOAuthPopup(String url) {
  final result = _openGoogleOAuthPopup(url.toJS);
  return result.dartify() == true;
}

/// Lit le résultat Google OAuth stocké dans window.__googleAuthResult
/// (rempli par le postMessage reçu depuis la popup de callback)
Map<String, String>? readGoogleAuthResult() {
  try {
    final raw = _googleAuthResult.dartify();
    if (raw is! Map) return null;
    final accessToken = raw['accessToken']?.toString();
    final refreshToken = raw['refreshToken']?.toString();
    if (accessToken == null || refreshToken == null) return null;
    _googleAuthResult = null;
    return {'accessToken': accessToken, 'refreshToken': refreshToken};
  } catch (_) {
    return null;
  }
}
