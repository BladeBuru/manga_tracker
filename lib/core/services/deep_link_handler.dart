import 'dart:async';

import 'package:app_links/app_links.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

/// Handler global des deep links pour Manga Tracker.
///
/// Intercepte les URLs entrantes (App Links Android, Universal Links iOS,
/// route navigator Web) et navigue vers la bonne vue selon le path.
///
/// Routes supportées :
///  - `https://api.bladeburu.com/auth/verify?token=XXX` → [VerifyEmailView]
///  - `https://api.bladeburu.com/auth/reset-password?token=XXX` → [ResetPasswordView]
///  - `mangatracker://auth/verify?token=XXX` (scheme custom dev) → idem
///  - `mangatracker://auth/reset-password?token=XXX` (scheme custom dev) → idem
///
/// **Sécurité** : seul le `token` query param est consommé. Toute autre
/// portion de l'URL est ignorée. Le token est validé serveur-side dans
/// les vues (single-use, expire 30/60 min). Pas de risque de XSS depuis
/// l'URL — Flutter n'évalue pas les query params.
///
/// **Usage** :
/// ```dart
/// // Dans main.dart, après runApp :
/// final navKey = GlobalKey<NavigatorState>();
/// MaterialApp(navigatorKey: navKey, …);
/// DeepLinkHandler(navigatorKey: navKey).initialize();
/// ```
class DeepLinkHandler {
  final GlobalKey<NavigatorState> navigatorKey;
  final AppLinks _appLinks = AppLinks();
  StreamSubscription<Uri>? _subscription;

  DeepLinkHandler({required this.navigatorKey});

  /// Démarre l'écoute des deep links.
  /// À appeler **une fois** au boot (après `runApp`).
  ///
  /// - Récupère le lien initial (si l'app a été lancée depuis un lien)
  /// - S'abonne au stream pour les liens reçus pendant que l'app tourne
  Future<void> initialize() async {
    // Lien initial (cold start depuis le clic sur le lien email)
    try {
      final initial = await _appLinks.getInitialLink();
      if (initial != null) {
        _handle(initial);
      }
    } catch (e) {
      debugPrint('⚠️ DeepLinkHandler: getInitialLink failed: $e');
    }

    // Liens reçus pendant que l'app tourne (warm start)
    _subscription = _appLinks.uriLinkStream.listen(
      _handle,
      onError: (e) => debugPrint('⚠️ DeepLinkHandler: stream error: $e'),
    );
  }

  Future<void> dispose() async {
    await _subscription?.cancel();
    _subscription = null;
  }

  void _handle(Uri uri) {
    // Ne traiter que les URLs de notre domaine. Si le scheme n'est pas
    // `https` ou que le host est différent, on ignore (sécurité).
    // En dev local, le user peut aussi tester avec un scheme custom
    // `mangatracker://` que l'on accepte explicitement.
    // Hosts autorisés : on accepte api.bladeburu.com (host actif aujourd'hui)
    // et bladeburu.com (au cas où l'utilisateur a un site web sur le domaine
    // racine plus tard et veut y router les magic links).
    const allowedHosts = {'api.bladeburu.com', 'bladeburu.com'};
    final isOurDomain =
        uri.scheme == 'https' && allowedHosts.contains(uri.host);
    final isCustomScheme = uri.scheme == 'mangatracker';
    if (!isOurDomain && !isCustomScheme) {
      debugPrint('⚠️ DeepLinkHandler: lien hors scope ignoré (${uri.scheme}://${uri.host})');
      return;
    }

    final path = uri.path;
    final token = uri.queryParameters['token'];

    if (token == null || token.isEmpty) {
      debugPrint('⚠️ DeepLinkHandler: lien sans token, ignoré ($path)');
      return;
    }

    final navContext = navigatorKey.currentContext;
    if (navContext == null) {
      debugPrint('⚠️ DeepLinkHandler: context non disponible, lien perdu');
      return;
    }

    // Routing — go_router : push avec query param token
    final encodedToken = Uri.encodeQueryComponent(token);
    if (path.endsWith('/auth/verify')) {
      navContext.push('/auth/verify?token=$encodedToken');
    } else if (path.endsWith('/auth/reset-password')) {
      navContext.push('/auth/reset-password?token=$encodedToken');
    } else {
      debugPrint('⚠️ DeepLinkHandler: path inconnu, ignoré ($path)');
    }
  }
}
