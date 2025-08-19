import 'package:flutter/material.dart';
import 'package:flutter_inappwebview/flutter_inappwebview.dart';

class ReaderWebView extends StatefulWidget {
  final String url;
  final void Function(int chapter, String url)? onChapterDetected;
  final bool adBlockEnabled;

  const ReaderWebView({
    super.key,
    required this.url,
    this.onChapterDetected,
    this.adBlockEnabled = true,
  });

  @override
  State<ReaderWebView> createState() => _ReaderWebViewState();
}

class _ReaderWebViewState extends State<ReaderWebView> {
  final _chapterRegex = RegExp(
    r'(?:^|[\/\-\_])(?:c|chap(?:ter)?)\D?(\d+)(?:\D|$)',
    caseSensitive: false,
  );

  int? _currentChapter;

  final List<ContentBlocker> _blockers = [
    ContentBlocker(
      trigger: ContentBlockerTrigger(
        urlFilter: r".*(doubleclick\.net|googlesyndication\.com|adservice\.google\..*|google-analytics\.com|taboola\.com|outbrain\.com|criteo\.com|scorecardresearch\.com).*",
        resourceType: [
          ContentBlockerTriggerResourceType.SCRIPT,
          ContentBlockerTriggerResourceType.IMAGE,
          ContentBlockerTriggerResourceType.STYLE_SHEET,
          ContentBlockerTriggerResourceType.FONT,
          ContentBlockerTriggerResourceType.MEDIA,
          ContentBlockerTriggerResourceType.DOCUMENT,
        ],
      ),
      action: ContentBlockerAction(type: ContentBlockerActionType.BLOCK),
    ),
    ContentBlocker(
      trigger: ContentBlockerTrigger(urlFilter: r".*"),
      action: ContentBlockerAction(
        type: ContentBlockerActionType.CSS_DISPLAY_NONE,
        selector: ".ad, .ads, #ads, [id^='ad-'], [class*='ad-'], iframe[src*='ads']",
      ),
    ),
  ];

  void _maybeDetectChapter(Uri uri) {
    final m = _chapterRegex.firstMatch(uri.toString());
    if (m != null) {
      final ch = int.tryParse(m.group(1)!);
      if (ch != null && ch != _currentChapter) {
        _currentChapter = ch;
        widget.onChapterDetected?.call(ch, uri.toString());
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Lire en ligne')),
      body: InAppWebView(
        initialUrlRequest: URLRequest(url: WebUri(widget.url)),
        initialSettings:  InAppWebViewSettings(
          javaScriptEnabled: true,
          mediaPlaybackRequiresUserGesture: true,
          contentBlockers: widget.adBlockEnabled ? _blockers : const [],
        ),
        // 1) Quand une nouvelle page commence à charger
        onLoadStart: (controller, url) {
          if (url != null) _maybeDetectChapter(url);
        },
        // 2) Quand l'historique est mis à jour (inclut pushState / SPA)
        onUpdateVisitedHistory: (controller, url, androidIsReload) {
          if (url != null) _maybeDetectChapter(url);
        },
        // 3) Optionnel : intercepter la navigation avant de la laisser passer
        shouldOverrideUrlLoading: (controller, action) async {
          final u = action.request.url;
          if (u != null) _maybeDetectChapter(u);
          return NavigationActionPolicy.ALLOW;
        },
      ),
    );
  }
}
