import 'package:flutter/foundation.dart';
import 'package:flutter_inappwebview/flutter_inappwebview.dart';
import 'package:mangatracker/features/reader/services/web_view_user_agent.dart';

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

  /// Récupère le user-agent réel de la WebView et en retire les jetons qui
  /// décrivent mal le moteur (voir [WebViewUserAgent]).
  ///
  /// Renvoie `null` si le user-agent par défaut est illisible : l'appelant
  /// laisse alors la valeur de la plateforme intacte.
  static Future<String?> resolveUserAgent() async {
    try {
      final defaultUa = await InAppWebViewController.getDefaultUserAgent();
      return WebViewUserAgent.normalize(defaultUa);
    } catch (e) {
      debugPrint('⚠️ User-agent par défaut illisible, valeur inchangée: $e');
      return null;
    }
  }

  /// Applique le user-agent normalisé PUIS déclenche le chargement initial.
  ///
  /// L'URL n'est volontairement pas passée en `initialUrlRequest` : la
  /// première requête — celle qui déclenche la vérification anti-robot — doit
  /// déjà porter le bon user-agent.
  static Future<void> applyUserAgentAndLoad({
    required InAppWebViewController controller,
    required String initialUrl,
    required Future<String?> userAgent,
  }) async {
    try {
      final ua = await userAgent;
      if (ua != null) {
        await controller.setSettings(
          settings: build(
            // Volontairement vide : les `ContentBlocker` ne sont pas actifs
            // aujourd'hui (le cache est encore vide à la création de la
            // WebView). Les activer ici serait un changement de comportement
            // distinct — voir known-issues.md.
            contentBlockers: const [],
            userAgent: ua,
          ),
        );
      }
    } catch (e) {
      debugPrint('⚠️ Application du user-agent impossible: $e');
    }
    try {
      await controller.loadUrl(
        urlRequest: URLRequest(url: WebUri(initialUrl)),
      );
    } catch (e) {
      debugPrint('⚠️ Chargement initial impossible: $e');
    }
  }
}
