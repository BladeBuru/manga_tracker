import 'package:flutter_test/flutter_test.dart';
import 'package:mangatracker/features/manga/dto/manga_quick_view.dto.dart';
import 'package:mangatracker/features/reader/dto/reading_position.dto.dart';

import '../../../fixtures/fixtures.dart';

/// Champs de position de `/library/all` : **optionnels**, presents en bloc ou
/// absents. Le serveur les remet a `null` de lui-meme quand le chapitre en
/// cours devient termine — le client ne reimplemente pas cette regle, il doit
/// juste survivre aux deux formes de reponse.
void main() {
  group('MangaQuickViewDto — position de lecture en cours', () {
    test('lit le bloc complet quand le serveur le renvoie', () {
      final dto = MangaQuickViewDto.fromJson(
        loadJsonFixture('library_all_with_position.json'),
      );

      expect(dto.currentChapter, 42);
      expect(dto.currentPositionPercent, 37.5);
      expect(dto.currentPositionUpdatedAt, DateTime.utc(2026, 9, 6, 10));
      expect(dto.readChapters, 41, reason: 'la progression reste distincte');
    });

    test('survit a une entree sans position (bloc absent)', () {
      final dto = MangaQuickViewDto.fromJson(
        loadJsonFixture('library_all_without_position.json'),
      );

      expect(dto.currentChapter, isNull);
      expect(dto.currentPositionPercent, isNull);
      expect(dto.currentPositionUpdatedAt, isNull);
      expect(dto.title, 'Solo Leveling');
    });

    test('un horodatage illisible ne fait pas echouer le parsing', () {
      final json = loadJsonFixture('library_all_with_position.json')
        ..['currentPositionUpdatedAt'] = 'pas une date';

      final dto = MangaQuickViewDto.fromJson(json);

      expect(dto.currentPositionUpdatedAt, isNull);
      expect(dto.currentChapter, 42);
    });

    test('le cache local conserve la position (toJson / fromJson)', () {
      final dto = MangaQuickViewDto.fromJson(
        loadJsonFixture('library_all_with_position.json'),
      );

      final restored = MangaQuickViewDto.fromJson(dto.toJson());

      expect(restored.currentChapter, 42);
      expect(restored.currentPositionPercent, 37.5);
      expect(restored.currentPositionUpdatedAt, dto.currentPositionUpdatedAt);
    });

    test('copyWith preserve la position — elle n\'est pas dans la signature',
        () {
      final dto = MangaQuickViewDto.fromJson(
        loadJsonFixture('library_all_with_position.json'),
      );

      final updated = dto.copyWith(readChapters: 42);

      expect(updated.currentChapter, 42);
      expect(updated.currentPositionPercent, 37.5);
    });
  });

  group('ReadingPositionDto — contrat de l\'endpoint dedie', () {
    test('parse la reponse 200', () {
      final dto = ReadingPositionDto.fromJson(
        loadJsonFixture('reading_position.json'),
      );

      expect(dto.chapter, 42);
      expect(dto.positionPercent, 37.5);
      expect(dto.updatedAt, DateTime.utc(2026, 9, 6, 10));
    });

    test('aller-retour JSON stable (marque-page local)', () {
      final dto = ReadingPositionDto.fromJson(
        loadJsonFixture('reading_position.json'),
      );

      expect(ReadingPositionDto.fromJson(dto.toJson()), dto);
    });

    test('un horodatage absent reste null, sans exception', () {
      final dto = ReadingPositionDto.fromJson(
        const {'chapter': 42, 'positionPercent': 10},
      );

      expect(dto.updatedAt, isNull);
      expect(dto.positionPercent, 10.0);
    });
  });
}
