import 'package:flutter_test/flutter_test.dart';
import 'package:mangatracker/features/library/widgets/library_filtering.dart';
import 'package:mangatracker/features/manga/dto/manga_quick_view.dto.dart';
import 'package:mangatracker/features/manga/dto/reading_status.enum.dart';

MangaQuickViewDto manga(
  int muId,
  String title, {
  ReadingStatus status = ReadingStatus.reading,
  List<String>? associated,
}) => MangaQuickViewDto(
  muId: muId,
  title: title,
  year: '2020',
  rating: '8.0',
  readingStatus: status,
  associated: associated,
);

void main() {
  final library = [
    manga(1, 'One Piece'),
    manga(2, 'Naruto', status: ReadingStatus.completed),
    manga(3, 'Boku no Hero Academia', associated: ['My Hero Academia']),
    manga(4, 'Piece of Cake', status: ReadingStatus.readLater),
  ];

  group('LibraryFiltering.apply — filtrage synchrone', () {
    test('sans recherche ni filtre : la liste est rendue telle quelle', () {
      final result = LibraryFiltering.apply(mangas: library, searchQuery: '');
      expect(identical(result, library), isTrue);
    });

    test('la recherche trie par pertinence (début de titre avant contenu)', () {
      final result = LibraryFiltering.apply(
        mangas: library,
        searchQuery: 'piece',
      );
      expect(result.map((m) => m.muId), [4, 1]);
    });

    test('un titre alternatif correspond aussi', () {
      final result = LibraryFiltering.apply(
        mangas: library,
        searchQuery: 'my hero',
      );
      expect(result.single.muId, 3);
    });

    test('filtre « téléchargés » : seuls les muId fournis restent', () {
      final result = LibraryFiltering.apply(
        mangas: library,
        searchQuery: '',
        downloadedMuIds: {2, 3},
      );
      expect(result.map((m) => m.muId), [2, 3]);
    });
  });

  group('LibraryGroupingCache — pas de recalcul sur une reconstruction', () {
    test('mêmes entrées → même instance (aucun recalcul)', () {
      final cache = LibraryGroupingCache();
      final first = cache.resolve(mangas: library, searchQuery: '');
      final second = cache.resolve(mangas: library, searchQuery: '');
      expect(identical(first, second), isTrue);
      expect(first[ReadingStatus.reading]!.map((m) => m.muId), [1, 3]);
    });

    test('une nouvelle recherche recalcule', () {
      final cache = LibraryGroupingCache();
      final all = cache.resolve(mangas: library, searchQuery: '');
      final filtered = cache.resolve(mangas: library, searchQuery: 'naruto');
      expect(identical(all, filtered), isFalse);
      expect(filtered.keys, [ReadingStatus.completed]);
    });

    test('une nouvelle liste (rechargement) recalcule', () {
      final cache = LibraryGroupingCache();
      final before = cache.resolve(mangas: library, searchQuery: '');
      final after = cache.resolve(
        mangas: [...library, manga(5, 'Bleach')],
        searchQuery: '',
      );
      expect(identical(before, after), isFalse);
      expect(after[ReadingStatus.reading]!.length, 3);
    });
  });
}
