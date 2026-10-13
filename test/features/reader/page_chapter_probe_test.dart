import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:mangatracker/features/reader/services/page_chapter_probe.dart';
import 'package:mangatracker/features/reader/utils/page_chapter_parser.dart';

void main() {
  // Retour réel de la sonde sur aniverse.fr (relevé le 2026-10-13).
  const aniverse = {
    'url':
        'https://aniverse.fr/read/chainsaw-man/56f9e3ca-e8f5-49fc-8116-da885090eaf3',
    'title': 'Chainsaw Man Chapitre 1 Scan VF | Aniverse',
    'og': 'Chainsaw Man Chapitre 1 Scan VF | Aniverse',
    'chapters': ['Chapitre 1'],
    'crumb': 'Chapitre 1',
    'custom': '',
  };

  group('PageChapterProbe.decode', () {
    test('Map (Android) et chaîne JSON (iOS / web) donnent la même chose', () {
      for (final raw in [aniverse, jsonEncode(aniverse)]) {
        final signals = PageChapterProbe.decode(raw)!;
        expect(signals.url, aniverse['url']);
        expect(signals.jsonLdChapterNames, ['Chapitre 1']);
        expect(signals.breadcrumb, 'Chapitre 1');
        expect(signals.customText, isNull, reason: 'texte vide = absent');
        expect(PageChapterParser.parse(signals), 1);
      }
    });

    test('retour illisible -> null', () {
      expect(PageChapterProbe.decode(null), isNull);
      expect(PageChapterProbe.decode('undefined'), isNull);
      expect(PageChapterProbe.decode(42), isNull);
    });

    test('champs d\'un mauvais type tolérés', () {
      final signals = PageChapterProbe.decode({
        'title': 'Chapitre 3',
        'chapters': 'pas une liste',
        'crumb': 7,
      })!;
      expect(signals.jsonLdChapterNames, isEmpty);
      expect(signals.breadcrumb, isNull);
      expect(PageChapterParser.parse(signals), 3);
    });
  });

  group('PageChapterProbe.script', () {
    test('ne lit jamais le texte des liens ni du corps de la page', () {
      final script = PageChapterProbe.script();
      for (final forbidden in ['innerText', 'body.textContent', "'a'", 'links']) {
        expect(script, isNot(contains(forbidden)), reason: forbidden);
      }
      expect(script, isNot(contains('.position ===')),
          reason: 'position est un rang de liste, jamais un numéro');
    });

    test('le sélecteur propre au site est injecté échappé', () {
      final script = PageChapterProbe.script(titleSelector: 'h1[data-x="a"]');
      expect(script, contains(r'"h1[data-x=\"a\"]"'));
      expect(PageChapterProbe.script(), contains('var sel = null;'));
    });
  });
}
