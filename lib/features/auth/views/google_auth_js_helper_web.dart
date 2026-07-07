// ignore: avoid_web_libraries_in_flutter
import 'dart:js' as js;

/// Ouvre la popup Google OAuth via window.open() sans "noopener"
/// afin que window.opener soit disponible dans la popup pour le postMessage.
///
/// Retourne `false` si le navigateur a bloqué la popup. À appeler dans la
/// section SYNCHRONE d'un handler de tap (user activation), sinon
/// Brave/Safari bloquent systématiquement.
bool openGoogleOAuthPopup(String url) {
  final result = js.context.callMethod('openGoogleOAuthPopup', [url]);
  return result == true;
}

/// Lit le résultat Google OAuth stocké dans window.__googleAuthResult
/// (rempli par le postMessage reçu depuis la popup de callback)
Map<String, String>? readGoogleAuthResult() {
  try {
    final data = js.context['__googleAuthResult'];
    if (data == null) return null;
    final accessToken = data['accessToken']?.toString();
    final refreshToken = data['refreshToken']?.toString();
    if (accessToken == null || refreshToken == null) return null;
    js.context['__googleAuthResult'] = null;
    return {'accessToken': accessToken, 'refreshToken': refreshToken};
  } catch (_) {
    return null;
  }
}
