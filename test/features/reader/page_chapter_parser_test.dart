import 'package:flutter_test/flutter_test.dart';
import 'package:mangatracker/features/reader/utils/page_chapter_parser.dart';

void main() {
  int? parse({
    String? title,
    String? og,
    List<String> jsonLd = const [],
    String? crumb,
    String? custom,
  }) =>
      PageChapterParser.parse(PageChapterSignals(
        title: title,
        ogTitle: og,
        jsonLdChapterNames: jsonLd,
        breadcrumb: crumb,
        customText: custom,
      ));

  group('aniverse.fr (signaux relevés le 2026-10-13)', () {
    test('chapitre 1 : titre, og:title, JSON-LD et fil d\'Ariane d\'accord', () {
      expect(
        parse(
          title: 'Chainsaw Man Chapitre 1 Scan VF | Aniverse',
          og: 'Chainsaw Man Chapitre 1 Scan VF | Aniverse',
          jsonLd: ['Chapitre 1'],
          crumb: 'Chapitre 1',
        ),
        1,
      );
    });

    test('après « Chapitre suivant » (pushState) : tout dit 2', () {
      expect(
        parse(
          title: 'Chainsaw Man Chapitre 2 Scan VF | Aniverse',
          og: 'Chainsaw Man Chapitre 2 Scan VF | Aniverse',
          jsonLd: ['Chapitre 2'],
        ),
        2,
      );
    });

    test('pendant la transition : titre à jour, JSON-LD pas encore -> null',
        () {
      expect(
        parse(
          title: 'Chainsaw Man Chapitre 2 Scan VF | Aniverse',
          jsonLd: ['Chapitre 1'],
        ),
        isNull,
      );
    });

    test('page de la série (aucun numéro) -> null', () {
      expect(parse(title: 'Chainsaw Man Scan VF | Aniverse'), isNull);
    });
  });

  group('le chapitre suivant affiché sur la page n\'est jamais pris', () {
    test('« Chapitre suivant : 3 » ignoré, le 2 reste', () {
      expect(parse(title: 'Chapitre 2 | Chapitre suivant : 3'), 2);
      expect(parse(title: 'Chapitre 2 (suivant : Chapitre 3)'), 2);
    });

    test('next / previous dans plusieurs langues', () {
      expect(parse(title: 'Next chapter 3 - Chapter 2'), 2);
      expect(parse(title: 'Chapter 2 | Previous: Chapter 1'), 2);
      expect(parse(title: 'Capítulo 5 | Capítulo siguiente 6'), 5);
      expect(parse(title: 'Kapitel 7 | Nächstes Kapitel 8'), 7);
      expect(parse(title: 'Chapitre 4 | Chapitre précédent 3'), 4);
    });

    test('deux chapitres JSON-LD de premier niveau (2 et 3) -> null', () {
      expect(parse(jsonLd: ['Chapitre 2', 'Chapitre 3']), isNull);
    });

    test('un seul texte qui cite deux chapitres sans indice -> null', () {
      expect(parse(title: 'Chapitre 2 et Chapitre 3'), isNull);
    });
  });

  group('sources en désaccord -> null', () {
    test('og:title et titre différents', () {
      expect(parse(title: 'Chapitre 5', og: 'Chapitre 6'), isNull);
    });

    test('JSON-LD et titre différents', () {
      expect(parse(title: 'Chapitre 5', jsonLd: ['Chapitre 6']), isNull);
    });

    test('le fil d\'Ariane ne sert qu\'à défaut de source forte', () {
      expect(parse(crumb: 'Chapitre 7'), 7);
      expect(parse(title: 'Chapitre 5', crumb: 'Chapitre 4'), 5);
    });

    test('un sélecteur propre au site est prioritaire', () {
      expect(parse(title: 'Chapitre 8', custom: 'Chapitre 9'), 9);
    });
  });

  group('valeurs refusées', () {
    test('chapitre décimal -> null (l\'application compte des entiers)', () {
      expect(parse(title: 'One Piece Chapitre 271.5'), isNull);
      expect(parse(title: 'Ch. 12,5'), isNull);
      expect(parse(title: 'Chapitre 271', jsonLd: ['Chapitre 271.5']), isNull);
    });

    test('intervalle -> null', () {
      expect(parse(title: 'Chapitre 12-13'), isNull);
    });

    test('année ou valeur absurde -> null', () {
      expect(parse(title: 'Best Manga Chapter 2024'), isNull);
      expect(parse(title: 'Chapitre 123456'), isNull);
    });
  });

  group('formats et langues', () {
    final cases = <String, int>{
      'Chapter 12': 12,
      'Chap. 9': 9,
      'Ch.10': 10,
      'Chapitre n°11': 11,
      'Chapter #13': 13,
      'Capítulo 45': 45,
      'Capitulo 46': 46,
      'Kapitel 7': 7,
      'Episode 12 | Webtoon': 12,
      'Épisode 3': 3,
      'Ep. 4': 4,
      'One Piece Scan 1100 VF': 1100,
      '第12話': 12,
      '제12화': 12,
      'Vol.2 Ch.15': 15,
      'Chapitre 01': 1,
      'Chapitre 12–Le retour': 12,
    };
    cases.forEach((title, expected) {
      test(title, () => expect(parse(title: title), expected));
    });

    test('nombres du nom de la série ignorés', () {
      expect(parse(title: 'Mob Psycho 100 Chapitre 5'), 5);
      expect(parse(title: 'Kaiju No. 8 Chapitre 3'), 3);
      expect(
        parse(title: 'The Great Mage Returns After 4000 Years Chapter 190'),
        190,
      );
    });

    test('un mot qui commence par un mot-clé n\'est pas un chapitre', () {
      expect(parse(title: 'Chainsaw Man'), isNull);
      expect(parse(title: 'Chapter Black Chapitre 4'), 4);
      expect(parse(title: 'Recap 3 Step 4'), isNull);
    });

    test('nom JSON-LD réduit au numéro : accepté (nœud typé Chapter)', () {
      expect(parse(jsonLd: ['12']), 12);
      expect(PageChapterParser.numberIn('12'), isNull,
          reason: 'un nombre nu ailleurs ne prouve rien');
    });

    test('aucun signal -> null', () {
      expect(parse(), isNull);
    });
  });
}
