import 'dart:async';

import 'package:flutter/material.dart';
import 'package:webview_flutter/webview_flutter.dart';
import 'package:webview_flutter_android/webview_flutter_android.dart';

import 'package:mangatracker/features/reader/services/cloudflare_challenge.dart';
import 'package:mangatracker/features/reader/services/reader_diagnostics.dart';
import 'package:mangatracker/features/reader/widgets/challenge_handoff_banner.dart';

/// Vérification anti-robot confiée à une WebView **sans aucun ajout**.
///
/// ## Pourquoi (mesuré sur appareil le 2026-09-27)
///
/// Dans la WebView du lecteur, Cloudflare VALIDE le défi et pose un
/// `cf_clearance` neuf… puis le REFUSE à la requête suivante (403
/// `cf-mitigated: challenge` 60 ms après l'avoir émis) : son script a classé
/// l'environnement comme un robot. Cet environnement, ce sont les scripts et
/// le pont JavaScript que flutter_inappwebview injecte dans toutes les
/// frames (`window.flutter_inappwebview`, `window.print` remplacée…) et ce
/// que le lecteur ajoute à la page. Écartés par des essais A/B : garde
/// anti-redirection, user-agent, en-tête `X-Requested-With`, bloqueur de
/// publicités, réseau.
///
/// La même page, dans cette WebView brute (paquet webview_flutter, même
/// moteur, même magasin de cookies), passe du premier coup — et le
/// `cf_clearance` qu'elle obtient est ensuite accepté par le lecteur.
///
/// ## Règles
///
/// - ❌ N'ajouter AUCUN script, `runJavaScript`, canal JavaScript ni
///   `onNavigationRequest` : c'est précisément ce qui fait échouer la
///   vérification (`onNavigationRequest` annule et relance chaque navigation
///   sur Android — non validé sur appareil).
/// - ❌ Aucune résolution automatisée : c'est l'utilisateur qui fait le défi.
/// - La réussite se lit dans le magasin de cookies (nouveau `cf_clearance`),
///   sans rien exécuter dans la page.
class ChallengeHandoffView extends StatefulWidget {
  const ChallengeHandoffView({
    super.key,
    required this.url,
    required this.clearanceBefore,
    required this.readClearance,
    required this.onPassed,
    required this.onOpenInBrowser,
  });

  /// Page qui a servi le défi dans le lecteur.
  final Uri url;

  /// `cf_clearance` relevé avant la délégation (`null` si absent).
  final String? clearanceBefore;

  /// Relit le `cf_clearance` courant de [url] (valeur jamais journalisée).
  final Future<String?> Function() readClearance;

  /// Défi validé : le lecteur peut recharger la page.
  final VoidCallback onPassed;

  final VoidCallback onOpenInBrowser;

  @override
  State<ChallengeHandoffView> createState() => _ChallengeHandoffViewState();
}

class _ChallengeHandoffViewState extends State<ChallengeHandoffView> {
  static const _pollInterval = Duration(milliseconds: 700);

  late final WebViewController _controller;
  Timer? _poll;
  bool _passed = false;
  bool _checking = false;

  @override
  void initState() {
    super.initState();
    _controller = WebViewController()
      ..setJavaScriptMode(JavaScriptMode.unrestricted)
      ..setNavigationDelegate(NavigationDelegate(
        onPageStarted: _onPageStarted,
        onHttpError: (error) => ReaderDiagnostics.log('handoff.http', {
          'status': error.response?.statusCode,
          'url': error.request?.uri,
        }),
      ));
    final platform = _controller.platform;
    if (platform is AndroidWebViewController) {
      if (ReaderDiagnostics.enabled) {
        AndroidWebViewController.enableDebugging(true);
      }
      // Le widget Cloudflare est un iframe tiers : comme la WebView du
      // lecteur (`thirdPartyCookiesEnabled: true`), accepter ses cookies.
      final cookies = WebViewCookieManager().platform;
      if (cookies is AndroidWebViewCookieManager) {
        unawaited(cookies.setAcceptThirdPartyCookies(platform, true));
      }
    }
    ReaderDiagnostics.log('handoff.open', {'url': widget.url});
    unawaited(_controller.loadRequest(widget.url));
    _poll = Timer.periodic(_pollInterval, (_) => _checkClearance());
  }

  /// Protection anti-redirection minimale, sans intercepter les navigations :
  /// une page d'un autre site qui s'ouvrirait malgré tout est aussitôt
  /// quittée pour revenir à la vérification.
  void _onPageStarted(String url) {
    ReaderDiagnostics.log('handoff.page', {'url': url});
    final host = Uri.tryParse(url)?.host ?? '';
    final origin = widget.url.host;
    if (host.isEmpty || host == origin || host.endsWith('.$origin')) return;
    unawaited(_controller.loadRequest(widget.url));
  }

  Future<void> _checkClearance() async {
    if (_passed || _checking) return;
    _checking = true;
    try {
      final now = await widget.readClearance();
      if (!mounted || _passed) return;
      if (CloudflareChallenge.isClearanceRenewed(
        before: widget.clearanceBefore,
        after: now,
      )) {
        _passed = true;
        _poll?.cancel();
        ReaderDiagnostics.log('handoff.passed', {'url': widget.url});
        _unload();
        widget.onPassed();
      }
    } finally {
      _checking = false;
    }
  }

  /// Vide la WebView de vérification.
  ///
  /// Retirer la vue de l'écran ne détruit pas aussitôt la WebView Android :
  /// mesuré sur appareil, elle restait chargée (détachée) avec la page du
  /// chapitre — publicités et scripts compris — qui continuait de tourner
  /// en arrière-plan, en plus du lecteur. Le défi réussi, elle n'a plus rien
  /// à afficher.
  void _unload() {
    unawaited(_controller
        .loadRequest(Uri.parse('about:blank'))
        .then((_) {}, onError: (Object _) {}));
  }

  @override
  void dispose() {
    _poll?.cancel();
    if (!_passed) _unload();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return ColoredBox(
      color: Theme.of(context).colorScheme.surface,
      child: Column(
        children: [
          ChallengeHandoffBanner(onOpenInBrowser: widget.onOpenInBrowser),
          Expanded(child: WebViewWidget(controller: _controller)),
        ],
      ),
    );
  }
}
