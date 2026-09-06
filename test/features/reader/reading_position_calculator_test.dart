import 'package:flutter_test/flutter_test.dart';
import 'package:mangatracker/features/reader/utils/reading_position_calculator.dart';

/// Le calcul du pourcentage de lecture est ce qui voyage jusqu'au serveur puis
/// jusqu'à l'autre appareil : une erreur ici se traduit par « je rouvre mon
/// manga et il est au mauvais endroit ». D'où une classe pure, et ces tests.
void main() {
  group('percentFromScroll', () {
    test('0 % en haut de page, 100 % tout en bas', () {
      expect(
        ReadingPositionCalculator.percentFromScroll(
          scrollY: 0,
          viewportHeight: 800,
          documentHeight: 4800,
        ),
        0,
      );
      expect(
        ReadingPositionCalculator.percentFromScroll(
          scrollY: 4000, // maxScroll = 4800 - 800
          viewportHeight: 800,
          documentHeight: 4800,
        ),
        100,
      );
    });

    test('milieu de la course de défilement = 50 %', () {
      expect(
        ReadingPositionCalculator.percentFromScroll(
          scrollY: 2000,
          viewportHeight: 800,
          documentHeight: 4800,
        ),
        50,
      );
    });

    test('une page plus courte que l\'écran n\'a pas de position', () {
      // Régression possible : rendre 100 % ici ferait croire à une fin de
      // chapitre sur une page encore en cours de chargement.
      expect(
        ReadingPositionCalculator.percentFromScroll(
          scrollY: 0,
          viewportHeight: 800,
          documentHeight: 800,
        ),
        isNull,
      );
      expect(
        ReadingPositionCalculator.percentFromScroll(
          scrollY: 0,
          viewportHeight: 800,
          documentHeight: 400,
        ),
        isNull,
      );
    });

    test('mesure absente ou absurde → null, jamais une valeur inventée', () {
      for (final scenario in <Map<String, num?>>[
        {'scrollY': null, 'viewportHeight': 800, 'documentHeight': 4800},
        {'scrollY': 100, 'viewportHeight': null, 'documentHeight': 4800},
        {'scrollY': 100, 'viewportHeight': 800, 'documentHeight': null},
        {'scrollY': 100, 'viewportHeight': 800, 'documentHeight': 0},
        {'scrollY': double.nan, 'viewportHeight': 800, 'documentHeight': 4800},
        {
          'scrollY': double.infinity,
          'viewportHeight': 800,
          'documentHeight': 4800,
        },
      ]) {
        expect(
          ReadingPositionCalculator.percentFromScroll(
            scrollY: scenario['scrollY'],
            viewportHeight: scenario['viewportHeight'],
            documentHeight: scenario['documentHeight'],
          ),
          isNull,
          reason: 'scénario $scenario',
        );
      }
    });

    test('un défilement au-delà du document est borné à 100 (rebond iOS)', () {
      expect(
        ReadingPositionCalculator.percentFromScroll(
          scrollY: 9000,
          viewportHeight: 800,
          documentHeight: 4800,
        ),
        100,
      );
      expect(
        ReadingPositionCalculator.percentFromScroll(
          scrollY: -120,
          viewportHeight: 800,
          documentHeight: 4800,
        ),
        0,
      );
    });
  });

  group('scrollOffsetFromPercent', () {
    test('transpose une position d\'un écran à l\'autre', () {
      // 50 % mesurés sur un téléphone (4 800 px de haut) doivent retomber au
      // milieu de la même page rendue sur une tablette (12 000 px).
      final phone = ReadingPositionCalculator.percentFromScroll(
        scrollY: 2000,
        viewportHeight: 800,
        documentHeight: 4800,
      );
      expect(phone, 50);

      final tablet = ReadingPositionCalculator.scrollOffsetFromPercent(
        percent: phone,
        viewportHeight: 1200,
        documentHeight: 12000,
      );
      expect(tablet, (12000 - 1200) / 2);
    });

    test('aller-retour pourcentage → pixels → pourcentage stable', () {
      const viewport = 900.0;
      const document = 7300.0;
      for (final scrollY in [0.0, 137.0, 2500.0, 6400.0]) {
        final percent = ReadingPositionCalculator.percentFromScroll(
          scrollY: scrollY,
          viewportHeight: viewport,
          documentHeight: document,
        );
        final offset = ReadingPositionCalculator.scrollOffsetFromPercent(
          percent: percent,
          viewportHeight: viewport,
          documentHeight: document,
        );
        expect(offset, closeTo(scrollY, 0.001), reason: 'scrollY = $scrollY');
      }
    });

    test('document non défilable ou pourcentage absurde → null', () {
      expect(
        ReadingPositionCalculator.scrollOffsetFromPercent(
          percent: 50,
          viewportHeight: 800,
          documentHeight: 800,
        ),
        isNull,
      );
      expect(
        ReadingPositionCalculator.scrollOffsetFromPercent(
          percent: null,
          viewportHeight: 800,
          documentHeight: 4800,
        ),
        isNull,
      );
      expect(
        ReadingPositionCalculator.scrollOffsetFromPercent(
          percent: double.nan,
          viewportHeight: 800,
          documentHeight: 4800,
        ),
        isNull,
      );
    });
  });

  group('round', () {
    test('arrondit au centième — le serveur n\'a que faire du reste', () {
      expect(ReadingPositionCalculator.round(37.499999), 37.5);
      expect(ReadingPositionCalculator.round(0.004), 0);
      expect(ReadingPositionCalculator.round(99.999), 100);
    });

    test('reste dans les bornes acceptées par le contrat (0..100)', () {
      expect(ReadingPositionCalculator.round(-4), 0);
      expect(ReadingPositionCalculator.round(140), 100);
    });
  });
}
