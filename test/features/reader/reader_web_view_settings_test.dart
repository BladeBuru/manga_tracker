import 'package:flutter_inappwebview/flutter_inappwebview.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mangatracker/features/reader/services/reader_web_view_settings.dart';

/// Les réglages de la WebView du lecteur portent des invariants produit :
/// chaque valeur testée ici a une raison d'être documentée dans la classe.
void main() {
  late InAppWebViewSettings settings;

  setUp(() {
    settings = ReaderWebViewSettings.build(contentBlockers: const []);
  });

  group('protection anti-redirection', () {
    test('le garde de navigation est activé explicitement', () {
      expect(settings.useShouldOverrideUrlLoading, isTrue);
    });

    test('aucune fenêtre surgissante possible', () {
      expect(settings.supportMultipleWindows, isFalse);
      expect(settings.javaScriptCanOpenWindowsAutomatically, isFalse);
    });
  });

  group('vérifications anti-robot', () {
    test('le user-agent de la plateforme est laissé intact', () {
      expect(settings.userAgent, anyOf(isNull, isEmpty));
    });

    test("l'en-tête X-Requested-With n'est envoyé à aucune origine", () {
      expect(settings.requestedWithHeaderOriginAllowList, isNotNull);
      expect(settings.requestedWithHeaderOriginAllowList, isEmpty);
    });

    test('le cookie d\'autorisation peut persister', () {
      expect(settings.domStorageEnabled, isTrue);
      expect(settings.databaseEnabled, isTrue);
      expect(settings.thirdPartyCookiesEnabled, isTrue);
      expect(settings.cacheEnabled, isTrue);
      expect(settings.sharedCookiesEnabled, isTrue);
      expect(settings.incognito, isFalse);
    });
  });

  test('les ContentBlocker fournis sont transmis tels quels', () {
    final blocker = ContentBlocker(
      trigger: ContentBlockerTrigger(urlFilter: '.*doubleclick.*'),
      action: ContentBlockerAction(type: ContentBlockerActionType.BLOCK),
    );
    final withBlocker = ReaderWebViewSettings.build(contentBlockers: [blocker]);
    expect(withBlocker.contentBlockers, [blocker]);
  });
}
