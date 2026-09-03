import 'package:flutter_test/flutter_test.dart';
import 'package:mangatracker/features/reader/services/web_view_user_agent.dart';

void main() {
  // UA réel d'une WebView Android (Chromium 116, Android 13).
  const webViewUa =
      'Mozilla/5.0 (Linux; Android 13; Pixel 7 Build/TQ3A.230805.001; wv) '
      'AppleWebKit/537.36 (KHTML, like Gecko) Version/4.0 '
      'Chrome/116.0.5845.114 Mobile Safari/537.36';

  group('WebViewUserAgent.normalize', () {
    test('retire le marqueur « ; wv »', () {
      final ua = WebViewUserAgent.normalize(webViewUa)!;
      expect(ua, isNot(contains('wv')));
      expect(ua, contains('(Linux; Android 13; Pixel 7)'));
    });

    test('retire le vestige « Version/4.0 »', () {
      final ua = WebViewUserAgent.normalize(webViewUa)!;
      expect(ua, isNot(contains('Version/4.0')));
      expect(ua, isNot(contains('Version/')));
    });

    test('retire le Build/… de l\'appareil', () {
      final ua = WebViewUserAgent.normalize(webViewUa)!;
      expect(ua, isNot(contains('Build/')));
      expect(ua, isNot(contains('TQ3A')));
    });

    test('conserve la version réelle de Chrome et d\'Android', () {
      final ua = WebViewUserAgent.normalize(webViewUa)!;
      // Le point déontologique : on ne fabrique rien, on ne ment pas sur le
      // moteur — on retire seulement les jetons qui le décrivent mal.
      expect(ua, contains('Chrome/116.0.5845.114'));
      expect(ua, contains('Android 13'));
      expect(ua, contains('Mobile Safari/537.36'));
      expect(ua, contains('AppleWebKit/537.36 (KHTML, like Gecko)'));
    });

    test('produit un UA Chrome mobile cohérent', () {
      expect(
        WebViewUserAgent.normalize(webViewUa),
        'Mozilla/5.0 (Linux; Android 13; Pixel 7) AppleWebKit/537.36 '
        '(KHTML, like Gecko) Chrome/116.0.5845.114 Mobile Safari/537.36',
      );
    });

    test('ne laisse pas de double espace', () {
      final ua = WebViewUserAgent.normalize(webViewUa)!;
      expect(ua, isNot(contains('  ')));
    });

    test('renvoie null quand il n\'y a rien à corriger', () {
      // UA Chrome mobile authentique : aucun jeton trompeur.
      const chromeUa = 'Mozilla/5.0 (Linux; Android 10; K) AppleWebKit/537.36 '
          '(KHTML, like Gecko) Chrome/120.0.0.0 Mobile Safari/537.36';
      expect(WebViewUserAgent.normalize(chromeUa), isNull);
    });

    test('renvoie null sur une entrée vide ou absente', () {
      expect(WebViewUserAgent.normalize(null), isNull);
      expect(WebViewUserAgent.normalize(''), isNull);
      expect(WebViewUserAgent.normalize('   '), isNull);
    });

    test('renvoie null sur un UA non-Android', () {
      const desktopUa = 'Mozilla/5.0 (Macintosh; Intel Mac OS X 10_15_7) '
          'AppleWebKit/605.1.15 (KHTML, like Gecko) Version/17.0 Safari/605.1.15';
      expect(WebViewUserAgent.normalize(desktopUa), isNull);
    });

    test('gère un UA WebView sans Build/', () {
      const ua = 'Mozilla/5.0 (Linux; Android 14; wv) AppleWebKit/537.36 '
          '(KHTML, like Gecko) Version/4.0 Chrome/125.0.6422.165 Mobile Safari/537.36';
      final out = WebViewUserAgent.normalize(ua)!;
      expect(out, contains('Chrome/125.0.6422.165'));
      expect(out, isNot(contains('wv')));
      expect(out, isNot(contains('Version/4.0')));
    });
  });
}
