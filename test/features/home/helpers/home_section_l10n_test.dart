import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mangatracker/core/components/pastel_tile.dart';
import 'package:mangatracker/features/home/dto/home_section.dto.dart';
import 'package:mangatracker/features/home/dto/home_section_kind.dart';
import 'package:mangatracker/features/home/helpers/home_section_l10n.dart';
import 'package:mangatracker/l10n/app_localizations.dart';

/// Le serveur n'envoie pas de titre : verrouille la deduction kind + params
/// dans les 7 langues (une cle par kind), la table des genres traduits et
/// les replis sur la valeur brute.
void main() {
  Future<AppLocalizations> load(String code) =>
      AppLocalizations.delegate.load(Locale(code));

  group('HomeSectionL10n.title (fr)', () {
    late AppLocalizations fr;

    setUpAll(() async => fr = await load('fr'));

    String titleOf(HomeSectionKind kind,
            {HomeSectionParams params = HomeSectionParams.none}) =>
        HomeSectionL10n.title(fr, kind: kind, params: params, fallback: 'id');

    test('titres des kinds sans parametre', () {
      expect(titleOf(HomeSectionKind.latest), 'Dernières sorties');
      expect(titleOf(HomeSectionKind.popular), 'Ce qui marche le mieux');
      expect(titleOf(HomeSectionKind.topRated), 'Les mieux notés');
      expect(titleOf(HomeSectionKind.community), 'Le choix de la communauté');
      expect(titleOf(HomeSectionKind.hiddenGems), 'Pépites cachées');
    });

    test('type : Manga / Manhwa / Manhua traduits, autre type brut', () {
      expect(
        titleOf(HomeSectionKind.type,
            params: const HomeSectionParams(type: 'Manhwa')),
        'Manhwa',
      );
      expect(
        titleOf(HomeSectionKind.type,
            params: const HomeSectionParams(type: 'manga')),
        'Manga',
      );
      expect(
        titleOf(HomeSectionKind.type,
            params: const HomeSectionParams(type: 'Novel')),
        'Novel',
      );
    });

    test('genre : placeholder + genre traduit, ou brut si inconnu', () {
      expect(
        titleOf(HomeSectionKind.genre,
            params: const HomeSectionParams(genre: 'Action')),
        'Genre : Action',
      );
      expect(
        titleOf(HomeSectionKind.genre,
            params: const HomeSectionParams(genre: 'Slice of Life')),
        'Genre : Tranche de vie',
      );
      expect(
        titleOf(HomeSectionKind.genre,
            params: const HomeSectionParams(genre: 'Yuri')),
        'Genre : Yuri',
      );
    });

    test('year : placeholder sans separateur de milliers', () {
      expect(
        titleOf(HomeSectionKind.year,
            params: const HomeSectionParams(year: 2014)),
        'Les sorties de 2014',
      );
    });

    test('parametre manquant ou kind inconnu → identifiant brut', () {
      expect(titleOf(HomeSectionKind.genre), 'id');
      expect(titleOf(HomeSectionKind.type), 'id');
      expect(titleOf(HomeSectionKind.year), 'id');
      expect(
        HomeSectionL10n.title(fr, kind: null, fallback: 'editorial:x'),
        'editorial:x',
      );
    });

    test('titleOf lit kind + params + id d\'une section parsee', () {
      const section = HomeSectionDto(
        id: 'year:1999',
        kind: HomeSectionKind.year,
        params: HomeSectionParams(year: 1999),
      );
      expect(HomeSectionL10n.titleOf(fr, section), 'Les sorties de 1999');
    });
  });

  group('HomeSectionL10n.genre', () {
    test('table des 15 genres frequents (fr), insensible a la casse', () async {
      final fr = await load('fr');
      expect(HomeSectionL10n.knownGenres, hasLength(15));
      expect(HomeSectionL10n.genre(fr, 'Romance'), 'Romance');
      expect(HomeSectionL10n.genre(fr, 'Drama'), 'Drame');
      expect(HomeSectionL10n.genre(fr, 'Fantasy'), 'Fantasy');
      expect(HomeSectionL10n.genre(fr, 'Comedy'), 'Comédie');
      expect(HomeSectionL10n.genre(fr, 'Slice of Life'), 'Tranche de vie');
      expect(HomeSectionL10n.genre(fr, 'ACTION'), 'Action');
      expect(HomeSectionL10n.genre(fr, 'School Life'), 'Vie scolaire');
      expect(HomeSectionL10n.genre(fr, 'Supernatural'), 'Surnaturel');
      expect(HomeSectionL10n.genre(fr, 'Adventure'), 'Aventure');
      expect(HomeSectionL10n.genre(fr, 'Historical'), 'Historique');
      expect(HomeSectionL10n.genre(fr, 'Mystery'), 'Mystère');
      expect(HomeSectionL10n.genre(fr, 'Psychological'), 'Psychologique');
      expect(HomeSectionL10n.genre(fr, 'Sci-fi'), 'Science-fiction');
      expect(HomeSectionL10n.genre(fr, 'Sci-Fi'), 'Science-fiction');
      expect(HomeSectionL10n.genre(fr, 'Horror'), 'Horreur');
      expect(HomeSectionL10n.genre(fr, 'Martial Arts'), 'Arts martiaux');
      expect(HomeSectionL10n.genre(fr, 'martial_arts'), 'Arts martiaux');
    });

    test('genre inconnu → nom brut', () async {
      final fr = await load('fr');
      expect(HomeSectionL10n.genre(fr, 'Yaoi'), 'Yaoi');
    });

    test('chaque langue traduit tous les kinds sans retomber sur le fr',
        () async {
      // Les ARB non-fr sont souvent partiels : on verifie ici que les cles
      // de cette feature existent bien dans les 7 langues.
      for (final code in ['en', 'de', 'ja', 'ko', 'pt', 'es']) {
        final l10n = await load(code);
        expect(l10n.homeSectionLatest, isNot('Dernières sorties'),
            reason: 'homeSectionLatest manquant en $code');
        expect(l10n.homeSectionHiddenGems, isNot('Pépites cachées'),
            reason: 'homeSectionHiddenGems manquant en $code');
        expect(l10n.genreSliceOfLife, isNot('Tranche de vie'),
            reason: 'genreSliceOfLife manquant en $code');
        expect(l10n.homeSectionYear('2014'), contains('2014'));
        expect(l10n.homeSectionGenre('X'), contains('X'));
      }
    });
  });

  group('HomeSectionL10n.icon / tileColor', () {
    test('une icone outlined par kind, repli sur auto_stories', () {
      for (final kind in HomeSectionKind.values) {
        expect(HomeSectionL10n.icon(kind), isA<IconData>());
      }
      expect(HomeSectionL10n.icon(null), Icons.auto_stories_outlined);
      expect(HomeSectionL10n.icon(HomeSectionKind.hiddenGems),
          Icons.diamond_outlined);
      expect(HomeSectionL10n.tileColor(HomeSectionKind.popular),
          PastelTileColor.red);
    });
  });
}
