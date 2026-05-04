// ignore: avoid_web_libraries_in_flutter
import 'dart:js' as js;

/// Ouvre la popup Google OAuth via window.open() sans "noopener"
/// afin que window.opener soit disponible dans la popup pour le postMessage.
void openGoogleOAuthPopup(String url) {
  js.context.callMethod('openGoogleOAuthPopup', [url]);
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
