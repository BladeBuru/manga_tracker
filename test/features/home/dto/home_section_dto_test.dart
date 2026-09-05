import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:mangatracker/features/home/dto/home_section.dto.dart';
import 'package:mangatracker/features/home/dto/home_section_kind.dart';
import 'package:mangatracker/features/manga/dto/manga_quick_view.dto.dart';

import '../../../fixtures/fixtures.dart';

/// Parse du contrat `GET /mangas/home/sections` (fixture JSON) : ordre du
/// serveur conserve, `kind` inconnu ignore sans planter, champs optionnels
/// `type` / `genres` lus sur les items, et aller-retour JSON pour le cache.
void main() {
  group('HomeSectionsDto.fromJson', () {
    late HomeSectionsDto dto;

    setUp(() {
      dto = HomeSectionsDto.fromJson(loadJsonFixture('home_sections.json'));
    });

    test('conserve l\'ordre du serveur et le generatedAt', () {
      expect(dto.generatedAt, DateTime.utc(2026, 9, 5, 10));
      expect(
        dto.sections.map((s) => s.id).toList(),
        [
          'latest',
          'popular',
          'top_rated',
          'type:Manhwa',
          'type:Manhua',
          'type:Manga',
          'genre:Action',
          'year:2014',
          'community',
          'hidden_gems',
          'year:1999',
        ],
      );
    });

    test('ignore une section dont le kind est inconnu', () {
      expect(dto.sections.any((s) => s.id == 'editorial:staff-picks'), isFalse);
      expect(HomeSectionKind.tryParse('editorial_pick'), isNull);
      expect(HomeSectionKind.tryParse(null), isNull);
      expect(HomeSectionKind.tryParse(42), isNull);
    });

    test('mappe chaque kind du contrat', () {
      HomeSectionKind kindOf(String id) =>
          dto.sections.firstWhere((s) => s.id == id).kind;
      expect(kindOf('latest'), HomeSectionKind.latest);
      expect(kindOf('popular'), HomeSectionKind.popular);
      expect(kindOf('top_rated'), HomeSectionKind.topRated);
      expect(kindOf('type:Manhwa'), HomeSectionKind.type);
      expect(kindOf('genre:Action'), HomeSectionKind.genre);
      expect(kindOf('year:2014'), HomeSectionKind.year);
      expect(kindOf('community'), HomeSectionKind.community);
      expect(kindOf('hidden_gems'), HomeSectionKind.hiddenGems);
    });

    test('lit les params types (genre / type / year)', () {
      HomeSectionParams paramsOf(String id) =>
          dto.sections.firstWhere((s) => s.id == id).params;
      expect(paramsOf('type:Manhwa').type, 'Manhwa');
      expect(paramsOf('genre:Action').genre, 'Action');
      expect(paramsOf('year:2014').year, 2014);
      expect(paramsOf('latest'), HomeSectionParams.none);
    });

    test('lit type et genres optionnels sur les items', () {
      final item = dto.sections.first.items.first;
      expect(item.muId, 101);
      expect(item.title, 'Solo Leveling');
      expect(item.rating, '9.2');
      expect(item.type, 'Manhwa');
      expect(item.genres, ['Action', 'Fantasy', 'Adventure']);
    });

    test('une section sans item est conservee mais exclue de nonEmptySections',
        () {
      expect(dto.sections.any((s) => s.id == 'year:1999'), isTrue);
      expect(dto.nonEmptySections.any((s) => s.id == 'year:1999'), isFalse);
      expect(dto.isEmpty, isFalse);
    });

    test('aller-retour toJson / fromJson (cache hors ligne)', () {
      final restored =
          HomeSectionsDto.fromJson(jsonDecode(jsonEncode(dto.toJson())));
      expect(restored.generatedAt, dto.generatedAt);
      expect(restored.sections.length, dto.sections.length);
      final original = dto.sections[3];
      final copy = restored.sections[3];
      expect(copy.id, original.id);
      expect(copy.kind, original.kind);
      expect(copy.params, original.params);
      expect(copy.items.first.title, original.items.first.title);
      expect(copy.items.first.type, 'Manhwa');
      expect(copy.items.first.genres, ['Action', 'Fantasy']);
    });

    test('un item corrompu est saute sans faire tomber la section', () {
      final section = HomeSectionDto.tryFromJson({
        'id': 'latest',
        'kind': 'latest',
        'params': <String, dynamic>{},
        'items': [
          {'muId': 1, 'title': 'OK', 'year': '2020', 'rating': 8},
          {'title': 'sans muId'},
          'pas un objet',
        ],
      });
      expect(section, isNotNull);
      expect(section!.items.map((m) => m.title), ['OK']);
    });

    test('une reponse sans sections donne un DTO vide', () {
      final empty = HomeSectionsDto.fromJson(const {'generatedAt': 'invalide'});
      expect(empty.sections, isEmpty);
      expect(empty.generatedAt, isNull);
      expect(empty.isEmpty, isTrue);
    });
  });

  group('HomeSectionsPageDto', () {
    test('parse la page du contrat et calcule hasMore via total', () {
      final page =
          HomeSectionsPageDto.fromJson(loadJsonFixture('home_section_page.json'));
      expect(page.id, 'year:2014');
      expect(page.kind, HomeSectionKind.year);
      expect(page.params.year, 2014);
      expect(page.page, 1);
      expect(page.limit, 2);
      expect(page.total, 5);
      expect(page.items.map((m) => m.muId), [601, 602]);
      expect(page.items.last.genres, ['Action', 'Horror', 'Psychological']);
      expect(page.hasMore, isTrue);
    });

    test('derniere page : hasMore faux', () {
      const page = HomeSectionsPageDto(
        id: 'latest',
        kind: HomeSectionKind.latest,
        page: 3,
        limit: 2,
        total: 5,
      );
      expect(page.hasMore, isFalse);
    });

    test('sans total : une page pleine suppose une suite', () {
      final full = HomeSectionsPageDto(
        id: 'latest',
        kind: HomeSectionKind.latest,
        page: 1,
        limit: 2,
        total: 0,
        items: [
          const MangaQuickViewDto(muId: 1, title: 'A', year: '2020', rating: '8'),
          const MangaQuickViewDto(muId: 2, title: 'B', year: '2020', rating: '8'),
        ],
      );
      expect(full.hasMore, isTrue);
      const short = HomeSectionsPageDto(
        id: 'latest',
        kind: HomeSectionKind.latest,
        page: 1,
        limit: 2,
        total: 0,
        items: [MangaQuickViewDto(muId: 1, title: 'A', year: '2020', rating: '8')],
      );
      expect(short.hasMore, isFalse);
    });

    test('kind inconnu sur une page : conserve sans planter', () {
      final page = HomeSectionsPageDto.fromJson({
        'id': 'editorial:x',
        'kind': 'editorial_pick',
        'page': 1,
        'limit': 40,
        'total': 0,
        'items': [],
      });
      expect(page.kind, isNull);
      expect(page.id, 'editorial:x');
    });
  });

  group('MangaQuickViewDto type / genres', () {
    test('absents : null, et toJson reste compatible avec l\'ancien cache', () {
      final dto = MangaQuickViewDto.fromJson({
        'muId': 7,
        'title': 'Sans extras',
        'year': '2001',
        'rating': 7.5,
      });
      expect(dto.type, isNull);
      expect(dto.genres, isNull);
      final json = dto.toJson();
      expect(json['type'], isNull);
      expect(json['genres'], isNull);
      // Un cache ecrit par une version anterieure (sans ces cles) se relit.
      json.remove('type');
      json.remove('genres');
      expect(MangaQuickViewDto.fromJson(json).title, 'Sans extras');
    });

    test('type vide traite comme absent', () {
      final dto = MangaQuickViewDto.fromJson({
        'muId': 7,
        'title': 'Type vide',
        'year': '2001',
        'rating': 7.5,
        'type': '  ',
        'genres': ['Action', 12],
      });
      expect(dto.type, isNull);
      expect(dto.genres, ['Action', '12']);
    });
  });
}
