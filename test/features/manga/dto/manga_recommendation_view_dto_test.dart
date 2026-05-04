import 'package:flutter_test/flutter_test.dart';
import 'package:mangatracker/features/manga/dto/manga_recommendation_view.dto.dart';
import 'package:mangatracker/features/manga/dto/reading_status.enum.dart';

/// Tests de non-régression sur le bug rapporté :
/// `MangaRecommendationView.fromJson` plantait en `FormatException` quand
/// `muId` était null, et en `TypeError` quand `title` était null.
/// La correction (null-checks dans le diff) doit être préservée.
void main() {
  group('MangaRecommendationView.fromJson', () {
    test('parse correctement un JSON complet', () {
      final dto = MangaRecommendationView.fromJson({
        'muId': 1234,
        'title': 'Test Manga',
        'year': 2023,
        'smallCoverUrl': 'https://cdn/small.jpg',
        'mediumCoverUrl': 'https://cdn/medium.jpg',
        'rating': 7.5,
        'readingStatus': 'reading',
        'inLibrary': true,
      });

      expect(dto.muId, 1234);
      expect(dto.title, 'Test Manga');
      expect(dto.year, '2023');
      expect(dto.smallCoverUrl, 'https://cdn/small.jpg');
      expect(dto.mediumCoverUrl, 'https://cdn/medium.jpg');
      expect(dto.rating, '7.5');
      expect(dto.readingStatus, ReadingStatus.reading);
      expect(dto.inLibrary, true);
    });

    test('ne crashe pas si muId est null (régression du bug original)', () {
      // Ne doit PAS lever de FormatException
      final dto = MangaRecommendationView.fromJson({
        'muId': null,
        'title': 'Without muId',
        'year': 2020,
        'rating': 5,
      });

      expect(dto.muId, 0);
      expect(dto.title, 'Without muId');
    });

    test('ne crashe pas si title est null (régression du bug original)', () {
      // Ne doit PAS lever de TypeError
      final dto = MangaRecommendationView.fromJson({
        'muId': 1,
        'title': null,
        'year': 2020,
        'rating': 5,
      });

      expect(dto.title, '');
      expect(dto.muId, 1);
    });

    test('rating à 0 ou null → "N/A"', () {
      final zeroDto = MangaRecommendationView.fromJson({
        'muId': 1,
        'title': 'Z',
        'year': 2020,
        'rating': 0,
      });
      expect(zeroDto.rating, 'N/A');

      final nullDto = MangaRecommendationView.fromJson({
        'muId': 2,
        'title': 'N',
        'year': 2020,
        'rating': null,
      });
      expect(nullDto.rating, 'N/A');
    });

    test('readingStatus null → ReadingStatus.readLater par défaut', () {
      final dto = MangaRecommendationView.fromJson({
        'muId': 1,
        'title': 'No status',
        'year': 2020,
        'rating': 5,
        'readingStatus': null,
      });
      expect(dto.readingStatus, ReadingStatus.readLater);
    });

    test('inLibrary absent → false', () {
      final dto = MangaRecommendationView.fromJson({
        'muId': 1,
        'title': 'No inLibrary',
        'year': 2020,
        'rating': 5,
      });
      expect(dto.inLibrary, false);
    });

    test('muId numérique sous forme de string (depuis JSON) est parsé', () {
      final dto = MangaRecommendationView.fromJson({
        'muId': '5678',
        'title': 'String muId',
        'year': '2020',
        'rating': '8.0',
      });
      expect(dto.muId, 5678);
      expect(dto.year, '2020');
    });
  });
}
