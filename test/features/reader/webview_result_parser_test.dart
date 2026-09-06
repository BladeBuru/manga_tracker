import 'package:flutter_test/flutter_test.dart';
import 'package:mangatracker/features/reader/utils/webview_result_parser.dart';

/// Non-régression du défaut du 2026-09-06 : les garde-fous de restauration de
/// `ScrollPositionService` lisaient le retour de `evaluateJavascript` comme du
/// texte (`split('"scrollY":')`). Sur Android, le plugin rend une **Map** :
/// la condition était donc toujours fausse et la garde jamais exécutée.
/// Les deux formes doivent donner le même résultat.
void main() {
  group('asMap', () {
    test('accepte la Map rendue par Android', () {
      final map = WebViewResultParser.asMap({
        'scrollY': 1200,
        'viewportHeight': 800,
        'documentHeight': 4800,
      });

      expect(map, isNotNull);
      expect(map!['scrollY'], 1200);
    });

    test('accepte la chaîne JSON rendue par iOS / web', () {
      final map = WebViewResultParser.asMap(
        '{"scrollY":1200,"viewportHeight":800,"documentHeight":4800}',
      );

      expect(map, isNotNull);
      expect(map!['scrollY'], 1200);
    });

    test('Map et chaîne JSON donnent exactement la même lecture', () {
      const json =
          '{"scrollY":1200,"viewportHeight":800,"documentHeight":4800}';
      final fromString = WebViewResultParser.asMap(json);
      final fromMap = WebViewResultParser.asMap(<String, dynamic>{
        'scrollY': 1200,
        'viewportHeight': 800,
        'documentHeight': 4800,
      });

      for (final key in ['scrollY', 'viewportHeight', 'documentHeight']) {
        expect(
          WebViewResultParser.numberAt(fromString, key),
          WebViewResultParser.numberAt(fromMap, key),
          reason: 'clé $key',
        );
      }
    });

    test('retour illisible → null, sans exception', () {
      expect(WebViewResultParser.asMap(null), isNull);
      expect(WebViewResultParser.asMap(''), isNull);
      expect(WebViewResultParser.asMap('   '), isNull);
      expect(WebViewResultParser.asMap('undefined'), isNull);
      expect(WebViewResultParser.asMap('[1, 2, 3]'), isNull);
      expect(WebViewResultParser.asMap(42), isNull);
    });
  });

  group('numberAt / asNumber', () {
    test('tolère un nombre rendu sous forme de chaîne', () {
      final map = WebViewResultParser.asMap('{"scrollY":"1200.5"}');
      expect(WebViewResultParser.numberAt(map, 'scrollY'), 1200.5);
    });

    test('refuse NaN et Infinity plutôt que de les propager', () {
      expect(WebViewResultParser.asNumber(double.nan), isNull);
      expect(WebViewResultParser.asNumber(double.infinity), isNull);
      expect(WebViewResultParser.asNumber('pas un nombre'), isNull);
      expect(WebViewResultParser.asNumber(null), isNull);
    });

    test('clé absente ou map absente → null', () {
      expect(WebViewResultParser.numberAt(null, 'scrollY'), isNull);
      expect(WebViewResultParser.numberAt(const {}, 'scrollY'), isNull);
    });
  });

  group('asBool', () {
    test('accepte true et la chaîne "true" (ponts natifs)', () {
      expect(WebViewResultParser.asBool(true), isTrue);
      expect(WebViewResultParser.asBool('true'), isTrue);
      expect(WebViewResultParser.asBool(false), isFalse);
      expect(WebViewResultParser.asBool('false'), isFalse);
      expect(WebViewResultParser.asBool(null), isFalse);
      expect(WebViewResultParser.asBool(1), isFalse);
    });
  });
}
