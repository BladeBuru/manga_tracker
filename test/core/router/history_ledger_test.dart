import 'package:flutter_test/flutter_test.dart';
import 'package:mangatracker/core/router/web_history/history_ledger.dart';

Map<String, Object?> _state(String location, [List<String> pushed = const []]) => {
      'location': location,
      'state': {'codec': 'custom', 'encoded': null},
      'imperativeMatches': [
        for (final p in pushed)
          {
            'location': p,
            'state': {'codec': 'custom', 'encoded': null},
            'pageKey': 'key-$p',
          },
      ],
    };

void main() {
  test("l'empreinte ne dépend pas de l'ordre des clés ni du type des nombres",
      () {
    expect(
      historyFingerprint({'a': 1, 'b': [2, {'d': 3, 'c': 4}]}),
      historyFingerprint({'b': [2.0, {'c': 4, 'd': 3}], 'a': 1.0}),
    );
  });

  group('popDepth', () {
    test('page empilée retirée = retour', () {
      expect(popDepth(_state('/home', ['/a']), _state('/home', ['/a', '/b'])), 1);
      expect(popDepth(_state('/home'), _state('/home', ['/a', '/b'])), 2);
    });

    test('nouvelle page ou autre onglet : pas un retour', () {
      expect(popDepth(_state('/home', ['/a', '/b']), _state('/home', ['/a'])), 0);
      expect(popDepth(_state('/library'), _state('/home')), 0);
      expect(popDepth(_state('/home', ['/c']), _state('/home', ['/a', '/b'])), 0);
    });

    test('sous-page déclarative : /home/section/x → /home', () {
      expect(popDepth(_state('/home'), _state('/home/section/x')), 1);
      expect(popDepth(_state('/home'), _state('/homeless')), 0);
    });
  });

  group('stepsBackTo', () {
    test("retrouve l'entrée précédente identique", () {
      final ledger = HistoryLedger()
        ..record(3, 'home')
        ..record(4, 'a')
        ..record(5, 'b');
      expect(ledger.stepsBackTo(5, 'a', maxSteps: 1), 1);
      expect(ledger.stepsBackTo(5, 'home', maxSteps: 2), 2);
    });

    test("n'invente jamais un retour vers une entrée inconnue", () {
      final ledger = HistoryLedger()..record(5, 'b');
      expect(ledger.stepsBackTo(5, 'a', maxSteps: 1), isNull);
      ledger.record(4, 'autre');
      expect(ledger.stepsBackTo(5, 'a', maxSteps: 1), isNull);
    });

    test('une nouvelle entrée efface ce qui était en avant', () {
      final ledger = HistoryLedger()
        ..record(1, 'a')
        ..record(2, 'b')
        ..truncateAfter(1);
      expect(ledger.at(2), isNull);
      expect(ledger.at(1), 'a');
    });
  });
}
