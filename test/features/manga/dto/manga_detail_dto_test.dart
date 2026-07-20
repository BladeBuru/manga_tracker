import 'package:flutter_test/flutter_test.dart';
import 'package:mangatracker/features/manga/dto/manga_detail.dto.dart';

/// Tests du champ `translatedDescription` (chantier traduction serveur) :
/// parse snake_case/camelCase, round-trip toJson→fromJson (cache offline),
/// et `copyWith` (bump du total via signalement sans perdre la traduction).
void main() {
  Map<String, dynamic> baseJson() => {
        'muId': 123,
        'title': 'Test Manga',
        'description': 'Original english description',
        'year': '2020',
        'rating': 7.5,
        'totalChapters': 100,
      };

  group('MangaDetailDto.translatedDescription', () {
    test('fromJson lit translated_description (snake_case API)', () {
      final dto = MangaDetailDto.fromJson({
        ...baseJson(),
        'translated_description': 'Description traduite',
      });

      expect(dto.translatedDescription, 'Description traduite');
      expect(dto.description, 'Original english description');
    });

    test('fromJson lit translatedDescription (camelCase cache)', () {
      final dto = MangaDetailDto.fromJson({
        ...baseJson(),
        'translatedDescription': 'Description traduite',
      });

      expect(dto.translatedDescription, 'Description traduite');
    });

    test('champ absent → null (langue en ou non supportée)', () {
      final dto = MangaDetailDto.fromJson(baseJson());

      expect(dto.translatedDescription, isNull);
    });

    test('round-trip toJson → fromJson préserve la traduction (cache offline)',
        () {
      final dto = MangaDetailDto.fromJson({
        ...baseJson(),
        'translated_description': 'Description traduite',
      });

      final roundTripped = MangaDetailDto.fromJson(dto.toJson());

      expect(roundTripped.translatedDescription, 'Description traduite');
      expect(roundTripped.description, dto.description);
      expect(roundTripped.totalChapters, dto.totalChapters);
    });

    test('copyWith(totalChapters:) met à jour le total sans perdre le reste',
        () {
      final dto = MangaDetailDto.fromJson({
        ...baseJson(),
        'translated_description': 'Description traduite',
      });

      final updated = dto.copyWith(totalChapters: 150);

      expect(updated.totalChapters, 150);
      expect(updated.translatedDescription, 'Description traduite');
      expect(updated.description, dto.description);
      expect(updated.title, dto.title);
    });
  });
}
