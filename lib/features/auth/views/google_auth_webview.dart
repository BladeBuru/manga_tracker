import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_inappwebview/flutter_inappwebview.dart';

import 'google_auth_js_helper_stub.dart'
    if (dart.library.html) 'google_auth_js_helper_web.dart';

/// Résultat du flux Google OAuth
class GoogleAuthResult {
  final String accessToken;
  final String refreshToken;

  const GoogleAuthResult({
    required this.accessToken,
    required this.refreshToken,
  });
}

/// WebView plein écran qui gère le flux Google OAuth.
///
/// - Sur **mobile** : InAppWebView avec interception du redirect `mangatracker://`
/// - Sur **web**    : popup navigateur + postMessage → polling Dart
class GoogleAuthWebView extends StatefulWidget {
  final String oauthUrl;

  /// Web : vrai si la popup a déjà été ouverte par l'appelant DANS le geste
  /// utilisateur (obligatoire pour passer les bloqueurs de popups —
  /// l'ouvrir ici, dans initState, arrive après le tap et se fait bloquer).
  final bool popupAlreadyOpened;

  const GoogleAuthWebView({
    super.key,
    required this.oauthUrl,
    this.popupAlreadyOpened = false,
  });

  @override
  State<GoogleAuthWebView> createState() => _GoogleAuthWebViewState();
}

class _GoogleAuthWebViewState extends State<GoogleAuthWebView> {
  bool _isLoading = true;
  Timer? _pollTimer;

  @override
  void initState() {
    super.initState();
    if (kIsWeb) _launchWebOAuth();
  }

  @override
  void dispose() {
    _pollTimer?.cancel();
    super.dispose();
  }

  /// Web : ouvre une popup via window.open() (sans noopener) et poll le résultat
  Future<void> _launchWebOAuth() async {
    // window.open() sans "noopener" → window.opener disponible dans la popup.
    // Si l'appelant l'a déjà ouverte dans le geste utilisateur (cas nominal),
    // ne pas rouvrir : ici on est hors geste → les bloqueurs refuseraient.
    if (!widget.popupAlreadyOpened) {
      openGoogleOAuthPopup(widget.oauthUrl);
    }

    // Polling toutes les 500ms pour détecter les tokens postMessage
    _pollTimer = Timer.periodic(const Duration(milliseconds: 500), (_) {
      final result = readGoogleAuthResult();
      if (result != null) {
        _pollTimer?.cancel();
        if (mounted) {
          Navigator.of(context).pop(
            GoogleAuthResult(
              accessToken: result['accessToken']!,
              refreshToken: result['refreshToken']!,
            ),
          );
        }
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    if (kIsWeb) {
      return Scaffold(
        appBar: AppBar(
          title: const Text('Connexion avec Google'),
          leading: IconButton(
            icon: const Icon(Icons.close),
            onPressed: () {
              _pollTimer?.cancel();
              Navigator.of(context).pop(null);
            },
          ),
        ),
        body: const Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              CircularProgressIndicator(),
              SizedBox(height: 24),
              Text(
                'Connectez-vous dans la fenêtre Google\nqui vient de s\'ouvrir.',
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 16),
              ),
              SizedBox(height: 8),
              Text(
                'Cette page se fermera automatiquement.',
                style: TextStyle(color: Colors.grey),
              ),
            ],
          ),
        ),
      );
    }

    // Mobile : InAppWebView avec interception du deep link
    return Scaffold(
      appBar: AppBar(
        title: const Text('Connexion avec Google'),
        leading: IconButton(
          icon: const Icon(Icons.close),
          tooltip: 'Annuler',
          onPressed: () => Navigator.of(context).pop(null),
        ),
      ),
      body: Stack(
        children: [
          InAppWebView(
            initialUrlRequest: URLRequest(url: WebUri(widget.oauthUrl)),
            initialSettings: InAppWebViewSettings(
              useShouldOverrideUrlLoading: true,
              clearCache: true,
            ),
            onWebViewCreated: (controller) async {
              // Ajoute un suffixe Flutter au user-agent existant
              // (Google bloque les user-agents entièrement personnalisés)
              final ua = await controller.evaluateJavascript(
                source: 'navigator.userAgent',
              );
              await controller.setSettings(
                settings: InAppWebViewSettings(
                  userAgent: '$ua FlutterMobile/1.0',
                ),
              );
            },
            onLoadStart: (_, __) {
              if (mounted) setState(() => _isLoading = true);
            },
            onLoadStop: (_, __) {
              if (mounted) setState(() => _isLoading = false);
            },
            shouldOverrideUrlLoading: (controller, navigationAction) async {
              final uri = navigationAction.request.url;
              if (uri == null) return NavigationActionPolicy.ALLOW;

              if (uri.scheme == 'mangatracker' && uri.host == 'auth') {
                final accessToken = uri.queryParameters['accessToken'];
                final refreshToken = uri.queryParameters['refreshToken'];
                if (accessToken != null && refreshToken != null && context.mounted) {
                  Navigator.of(context).pop(
                    GoogleAuthResult(
                      accessToken: accessToken,
                      refreshToken: refreshToken,
                    ),
                  );
                  return NavigationActionPolicy.CANCEL;
                }
              }
              return NavigationActionPolicy.ALLOW;
            },
          ),
          if (_isLoading) const Center(child: CircularProgressIndicator()),
        ],
      ),
    );
  }
}
