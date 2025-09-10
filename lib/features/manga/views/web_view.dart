import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:flutter_inappwebview/flutter_inappwebview.dart';
import 'package:mangatracker/core/service_locator/service_locator.dart';
import 'package:mangatracker/core/notifier/notifier.dart';
import 'package:mangatracker/features/library/services/library.service.dart';
import '../../reader/utils/chapter_link_resolver.dart';

class ReaderWebView extends StatefulWidget {
  final int muId;
  final int initialLastRead;      // ex. 119
  final String initialUrl;        // ex. URL du 120 si résoluble, sinon baseLink
  final String baseUserLink;      // le lien saisi par l’utilisateur (référence)

  const ReaderWebView({
    super.key,
    required this.muId,
    required this.initialLastRead,
    required this.initialUrl,
    required this.baseUserLink,
  });

  @override
  State<ReaderWebView> createState() => _ReaderWebViewState();
}

class _ReaderWebViewState extends State<ReaderWebView> {
  final _notifier = getIt<Notifier>();
  final _library = getIt<LibraryService>();

  InAppWebViewController? _controller;

  // État lecteur
  late int _lastCommitted;      // dernier chapitre confirmé en base
  int? _currentChapter;         // chapitre actuellement affiché (détecté)
  late String _originHost;      // domaine d'origine (pour filtrer)
  final Set<String> _denyHosts = {
    'google-analytics.com',
    'www.google-analytics.com',
    'googlesyndication.com',
    'pagead2.googlesyndication.com',
    'doubleclick.net',
    'adservice.google.com',
    'taboola.com',
    'outbrain.com',
    'criteo.com',
    'scorecardresearch.com',
  };

  // Ad-blocker minimal (appliqué via contentBlockers CSS + blocage de domaines connus)
  List<ContentBlocker> get _blockers => [
    ContentBlocker(
      trigger:  ContentBlockerTrigger(urlFilter: r".*(doubleclick\.net|googlesyndication\.com|adservice\.google\..*|google-analytics\.com|taboola\.com|outbrain\.com|criteo\.com|scorecardresearch\.com).*"),
      action:  ContentBlockerAction(type: ContentBlockerActionType.BLOCK),
    ),
    ContentBlocker(
      trigger:  ContentBlockerTrigger(urlFilter: r".*"),
      action:  ContentBlockerAction(
        type: ContentBlockerActionType.CSS_DISPLAY_NONE,
        selector: ".ad, .ads, #ads, [id^='ad-'], [class*='ad-'], iframe[src*='ads']",
      ),
    ),
  ];

  @override
  void initState() {
    super.initState();
    _lastCommitted = widget.initialLastRead;
    _originHost = Uri.parse(widget.initialUrl).host;
  }

  Future<void> _commitIfNeeded(int chapter) async {
    if (chapter <= _lastCommitted) return;
    final ok = await _library.saveChapterProgress(widget.muId, chapter);
    if (ok) {
      _lastCommitted = chapter;
      _notifier.info("Chapitre $chapter enregistré");
    }
  }

  Future<void> _updateNextLinkFrom(String currentUrl, {int? currentChapter}) async {
    final next = ChapterLinkResolver.buildNextUrl(currentUrl, currentChapter: currentChapter)
        ?? ChapterLinkResolver.buildNextUrl(widget.baseUserLink, currentChapter: currentChapter);
    if (next != null) {
      await _library.updateCustomLink(widget.muId, next);
    }
  }

  void _handleDetected(Uri uri) {
    // Filtrage domaines : on ne réagit pas aux pubs/trackers
    final host = uri.host;
    if (_denyHosts.contains(host)) return;
    // On reste sur le même provider (ou sous-domaines)
    if (!_sameProvider(host, _originHost)) return;

    final newCh = ChapterLinkResolver.extractChapter(uri.toString());
    if (newCh == null) return;

    if (_currentChapter == null) {
      _currentChapter = newCh; // premier chap détecté
      _updateNextLinkFrom(uri.toString(), currentChapter: newCh);
      return;
    }

    if (newCh == _currentChapter! + 1) {
      // Passage naturel au suivant => on valide le précédent
      final prev = _currentChapter!;
      _currentChapter = newCh;
      _commitIfNeeded(prev);
      _updateNextLinkFrom(uri.toString(), currentChapter: newCh);
      return;
    }

    if (newCh > _currentChapter! + 1) {
      // Saut de chapitres => on propose de valider le précédent
      _promptJumpConfirm(prev: _currentChapter!, next: newCh).then((yes) {
        _currentChapter = newCh;
        if (yes == true) _commitIfNeeded(newCh - 1); // on valide au moins le précédent
        _updateNextLinkFrom(uri.toString(), currentChapter: newCh);
      });
      return;
    }

    if (newCh < _currentChapter!) {
      // Retour en arrière => pas de commit
      _currentChapter = newCh;
      return;
    }
  }

  bool _sameProvider(String a, String b) {
    String root(String h) {
      final parts = h.split('.');
      return parts.length >= 2 ? '${parts[parts.length-2]}.${parts.last}' : h;
    }
    return root(a) == root(b);
  }

  Future<bool?> _promptJumpConfirm({required int prev, required int next}) {
    return showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text("Saut de chapitres"),
        content: Text("Vous passez du chapitre $prev au $next.\nMarquer $prev comme lu ?"),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text("Non")),
          ElevatedButton(onPressed: () => Navigator.pop(ctx, true), child: const Text("Oui")),
        ],
      ),
    );
  }

  Future<bool> _onWillPop() async {
    // Si on est sur le chap C et que le dernier validé est < C,
    // on demande si l'utilisateur a fini le chapitre C.
    final c = _currentChapter;
    if (c != null && _lastCommitted < c) {
      final yes = await showDialog<bool>(
        context: context,
        builder: (ctx) => AlertDialog(
          title: const Text("Valider la lecture"),
          content: Text("Avez-vous fini le chapitre $c ?"),
          actions: [
            TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text("Non")),
            ElevatedButton(onPressed: () => Navigator.pop(ctx, true), child: const Text("Oui, valider")),
          ],
        ),
      );
      if (yes == true) {
        await _commitIfNeeded(c);
        final currentUrl = await _controller?.getUrl();
        await _updateNextLinkFrom(
          (currentUrl?.toString() ?? widget.baseUserLink),
          currentChapter: c,
        );
      }
    }
    return true; // quitter la page
  }


  @override
  Widget build(BuildContext context) {
    return WillPopScope(
      onWillPop: _onWillPop,
      child: Scaffold(
        appBar: AppBar(title: const Text('Lire en ligne')),
        body: InAppWebView(
          initialUrlRequest: URLRequest(url: WebUri(widget.initialUrl)),
          initialSettings: InAppWebViewSettings(
            javaScriptEnabled: true,
            mediaPlaybackRequiresUserGesture: true,
            contentBlockers: _blockers,
          ),
          onWebViewCreated: (c) => _controller = c,

          // 1) Nouvelle navigation principale
          shouldOverrideUrlLoading: (controller, action) async {
            if (action.isForMainFrame && action.request.url != null) {
              _handleDetected(action.request.url!);
            }
            // Ad-block Android (interception basique côté requêtes)
            final url = action.request.url?.toString() ?? '';
            if (_denyHosts.any((h) => url.contains(h))) {
              return NavigationActionPolicy.CANCEL;
            }
            return NavigationActionPolicy.ALLOW;
          },

          // 2) Début de chargement
          onLoadStart: (controller, url) {
            if (url != null) _handleDetected(url);
          },

          // 3) SPA / pushState
          onUpdateVisitedHistory: (controller, url, _) {
            if (url != null) _handleDetected(url);
          },

          // 4) Android: blocage réseau supplémentaire (images/scripts pubs)
          androidShouldInterceptRequest: (controller, req) async {
            final u = req.url.toString();
            if (_denyHosts.any((h) => u.contains(h))) {
              return WebResourceResponse(
                contentType: 'text/plain',
                data: Uint8List(0),
                statusCode: 403,
                reasonPhrase: 'Blocked',
              );
            }
            return null;
          },
        ),
      ),
    );
  }
}
