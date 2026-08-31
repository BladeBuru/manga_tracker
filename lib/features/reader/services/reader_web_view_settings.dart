import 'package:flutter_inappwebview/flutter_inappwebview.dart';

/// Fabrique les réglages de la WebView du lecteur.
///
/// Extrait de `web_view_io.dart` pour ne pas alourdir la vue et pour rendre
/// explicites les réglages dont dépend l'aboutissement d'une vérification
/// anti-robot (persistance des cookies et du stockage).
class ReaderWebViewSettings {
  const ReaderWebViewSettings._();

  static InAppWebViewSettings build({
    required List<ContentBlocker> contentBlockers,
    String? userAgent,
  }) {
    return InAppWebViewSettings(
      javaScriptEnabled: true,
      mediaPlaybackRequiresUserGesture: true,
      contentBlockers: contentBlockers,
      allowsInlineMediaPlayback: true,
      iframeAllow: 'camera; microphone',
      iframeAllowFullscreen: true,

      // User-agent normalisé (voir WebViewUserAgent). La chaîne vide est la
      // valeur « laisser la valeur par défaut de la plateforme ».
      userAgent: userAgent ?? '',

      // --- Persistance du cookie d'autorisation ------------------------
      // Ces quatre réglages valent déjà `true` par défaut dans
      // flutter_inappwebview 6.x ; ils sont rendus explicites parce que le
      // cookie `cf_clearance` posé par une vérification réussie doit
      // survivre aux rechargements et aux navigations internes. Les
      // repasser à `false` ferait reboucler la vérification à chaque page.
      domStorageEnabled: true,
      databaseEnabled: true,
      thirdPartyCookiesEnabled: true,
      cacheEnabled: true,

      // iOS : par défaut `false`. Sans le magasin de cookies partagé, le
      // cookie d'autorisation ne survit pas d'une WebView à l'autre.
      sharedCookiesEnabled: true,

      // Explicites par sécurité : en navigation privée, le cookie
      // d'autorisation serait jeté à la fermeture et la vérification
      // recommencerait à chaque ouverture du lecteur.
      incognito: false,
      clearCache: false,
    );
  }
}
