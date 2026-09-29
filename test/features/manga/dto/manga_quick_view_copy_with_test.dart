import 'package:flutter_test/flutter_test.dart';
import 'package:mangatracker/features/manga/dto/manga_quick_view.dto.dart';
import 'package:mangatracker/features/manga/dto/reading_status.enum.dart';

void main() {
  test('copyWith conserve le type et les genres (pastille de type)', () {
    const original = MangaQuickViewDto(
      muId: 1,
      title: 'Solo Leveling',
      year: '2018',
      rating: '8.9',
      type: 'Manhwa',
      genres: ['Action', 'Fantasy'],
    );
    final copy = original.copyWith(
      readingStatus: ReadingStatus.reading,
      newChaptersCount: 2,
    );
    expect(copy.type, 'Manhwa');
    expect(copy.genres, ['Action', 'Fantasy']);
    expect(copy.newChaptersCount, 2);
    expect(copy.readingStatus, ReadingStatus.reading);
  });

  test('newChaptersCount n\'est pas sérialisé (donnée d\'appareil)', () {
    const dto = MangaQuickViewDto(
      muId: 1,
      title: 't',
      year: '2020',
      rating: '8',
      newChaptersCount: 3,
    );
    expect(dto.toJson().containsKey('newChaptersCount'), isFalse);
    expect(MangaQuickViewDto.fromJson(dto.toJson()).newChaptersCount, 0);
  });
}
