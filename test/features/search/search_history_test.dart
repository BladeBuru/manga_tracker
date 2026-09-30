import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mangatracker/core/service_locator/service_locator.dart';
import 'package:mangatracker/core/services/offline_cache_service.dart';
import 'package:mangatracker/features/manga/dto/manga_quick_view.dto.dart';
import 'package:mangatracker/features/manga/dto/search_results_page.dto.dart';
import 'package:mangatracker/features/manga/services/manga.service.dart';
import 'package:mangatracker/features/search/bloc/search_bloc.dart';
import 'package:mangatracker/features/search/services/search_history.service.dart';
import 'package:mangatracker/features/search/views/search.dart';
import 'package:mocktail/mocktail.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../home/views/home_test_harness.dart';

class MockMangaService extends Mock implements MangaService {}

class MockOfflineCacheService extends Mock implements OfflineCacheService {}

void main() {
  group('SearchHistoryService.merge — règle pure', () {
    test('le terme passe en tête, sans doublon (casse ignorée)', () {
      expect(SearchHistoryService.merge(['naruto', 'Bleach'], 'Naruto'), [
        'Naruto',
        'Bleach',
      ]);
    });

    test('les étapes de frappe (débuts du terme) disparaissent', () {
      expect(SearchHistoryService.merge(['My', 'My He', 'Bleach'], 'My Hero'), [
        'My Hero',
        'Bleach',
      ]);
    });

    test('un terme plus court ne supprime pas un terme plus long', () {
      expect(SearchHistoryService.merge(['One Piece'], 'One'), [
        'One',
        'One Piece',
      ]);
    });

    test('dix entrées au plus', () {
      final history = List.generate(10, (i) => 'titre $i');
      final merged = SearchHistoryService.merge(history, 'nouveau');
      expect(merged, hasLength(10));
      expect(merged.first, 'nouveau');
      expect(merged.contains('titre 9'), isFalse);
    });

    test('terme vide → historique inchangé', () {
      final history = ['Bleach'];
      expect(
        identical(SearchHistoryService.merge(history, '  '), history),
        isTrue,
      );
    });
  });

  group('Page Recherche — historique et genres', () {
    late MockMangaService mangaService;
    late MockOfflineCacheService cacheService;

    setUpAll(() => registerFallbackValue(<MangaQuickViewDto>[]));

    setUp(() async {
      await getIt.reset();
      SharedPreferences.setMockInitialValues({});
      mangaService = MockMangaService();
      cacheService = MockOfflineCacheService();
      when(
        () => cacheService.cacheSearchResults(any(), any()),
      ).thenAnswer((_) async {});
      when(
        () => mangaService.searchForMangas(
          any(),
          page: any(named: 'page'),
          limit: any(named: 'limit'),
        ),
      ).thenAnswer(
        (_) async => const SearchResultsPageDto(
          results: [],
          totalHits: 0,
          page: 1,
          perPage: SearchBloc.pageSize,
          hasMore: false,
        ),
      );
      getIt.registerSingleton<SearchHistoryService>(SearchHistoryService());
      getIt.registerSingleton<SearchBloc>(
        SearchBloc(mangaService: mangaService, cacheService: cacheService),
      );
    });

    tearDown(() => getIt.reset());

    Future<List<String>> storedHistory() async =>
        (await SharedPreferences.getInstance()).getStringList(
          'search_history',
        ) ??
        const [];

    testWidgets('une pause de frappe lance la recherche SANS l\'enregistrer ; '
        'la validation l\'enregistre', (tester) async {
      await tester.pumpWidget(frRouterHarness(home: const Search()));
      await tester.pump();

      await tester.enterText(find.byType(TextField), 'My');
      await tester.pump(const Duration(milliseconds: 900));
      await tester.enterText(find.byType(TextField), 'My Hero');
      await tester.pump(const Duration(milliseconds: 900));

      verify(
        () => mangaService.searchForMangas(
          'My',
          page: 1,
          limit: SearchBloc.pageSize,
        ),
      ).called(1);
      verify(
        () => mangaService.searchForMangas(
          'My Hero',
          page: 1,
          limit: SearchBloc.pageSize,
        ),
      ).called(1);
      expect(await storedHistory(), isEmpty);

      await tester.testTextInput.receiveAction(TextInputAction.search);
      await tester.pump();

      expect(await storedHistory(), ['My Hero']);
      // Déjà affichée : la validation ne relance pas une recherche identique.
      verifyNever(
        () => mangaService.searchForMangas(
          'My Hero',
          page: 1,
          limit: SearchBloc.pageSize,
        ),
      );
    });

    testWidgets('une pastille de genre ouvre la page du genre, sans rien taper '
        'dans la barre ni toucher à l\'historique', (tester) async {
      String? openedPath;
      await tester.pumpWidget(
        frRouterHarness(
          home: const Search(),
          extraRoutes: {
            '/home/section/:id': (state) {
              openedPath = state.pathParameters['id'];
              return const Text('page genre');
            },
          },
        ),
      );
      await tester.pump();

      await tester.tap(find.text('Shōnen'));
      await tester.pumpAndSettle();

      expect(openedPath, 'genre:Shounen');
      expect(find.text('page genre'), findsOneWidget);
      verifyNever(
        () => mangaService.searchForMangas(
          any(),
          page: any(named: 'page'),
          limit: any(named: 'limit'),
        ),
      );
      expect(await storedHistory(), isEmpty);
    });
  });
}
