import 'dart:async';

import 'package:flutter_test/flutter_test.dart';
import 'package:mangatracker/core/network/network_compat.dart';
import 'package:mangatracker/core/services/offline_cache_service.dart';
import 'package:mangatracker/features/manga/dto/manga_quick_view.dto.dart';
import 'package:mangatracker/features/manga/dto/search_results_page.dto.dart';
import 'package:mangatracker/features/manga/services/manga.service.dart';
import 'package:mangatracker/features/search/bloc/search_bloc.dart';
import 'package:mocktail/mocktail.dart';

class MockMangaService extends Mock implements MangaService {}

class MockOfflineCacheService extends Mock implements OfflineCacheService {}

MangaQuickViewDto manga(num muId, String title) => MangaQuickViewDto(
      muId: muId,
      title: title,
      year: '2025',
      rating: '7.5',
    );

SearchResultsPageDto pageDto(
  List<MangaQuickViewDto> results, {
  int page = 1,
  int totalHits = 100,
  bool hasMore = true,
}) =>
    SearchResultsPageDto(
      results: results,
      totalHits: totalHits,
      page: page,
      perPage: SearchBloc.pageSize,
      hasMore: hasMore,
    );

void main() {
  late MockMangaService mangaService;
  late MockOfflineCacheService cacheService;
  late SearchBloc bloc;

  setUpAll(() {
    registerFallbackValue(<MangaQuickViewDto>[]);
  });

  setUp(() {
    mangaService = MockMangaService();
    cacheService = MockOfflineCacheService();
    when(() => cacheService.cacheSearchResults(any(), any()))
        .thenAnswer((_) async {});
    bloc = SearchBloc(mangaService: mangaService, cacheService: cacheService);
  });

  tearDown(() => bloc.close());

  group('SearchRequested', () {
    test('should emit loading then loaded with the first page', () async {
      final results = [manga(1, 'Naruto'), manga(2, 'Naruto (Novel)')];
      when(() => mangaService.searchForMangas('naruto',
              page: 1, limit: SearchBloc.pageSize))
          .thenAnswer((_) async => pageDto(results, totalHits: 316));

      final expectation = expectLater(
        bloc.stream,
        emitsInOrder([
          const SearchLoading('naruto'),
          isA<SearchLoaded>()
              .having((s) => s.results, 'results', results)
              .having((s) => s.totalHits, 'totalHits', 316)
              .having((s) => s.page, 'page', 1)
              .having((s) => s.hasMore, 'hasMore', true),
        ]),
      );
      bloc.add(const SearchRequested('naruto'));
      await expectation;
    });

    test('should emit initial state when the query is blank', () async {
      final expectation = expectLater(bloc.stream, emits(const SearchInitial()));
      bloc.add(const SearchRequested('   '));
      await expectation;
    });

    test('should fall back to cached results when offline', () async {
      final cached = [manga(1, 'Naruto')];
      when(() => mangaService.searchForMangas('naruto',
              page: 1, limit: SearchBloc.pageSize))
          .thenThrow(const SocketException('offline'));
      when(() => cacheService.getCachedSearchResults('naruto'))
          .thenAnswer((_) async => cached);

      final expectation = expectLater(
        bloc.stream,
        emitsInOrder([
          const SearchLoading('naruto'),
          isA<SearchLoaded>()
              .having((s) => s.results, 'results', cached)
              .having((s) => s.isOffline, 'isOffline', true)
              .having((s) => s.hasMore, 'hasMore', false),
        ]),
      );
      bloc.add(const SearchRequested('naruto'));
      await expectation;
    });

    test('should ignore stale results when the query was cleared mid-flight',
        () async {
      // Le transformer par défaut de bloc est concurrent : SearchCleared est
      // traité pendant que la requête HTTP de SearchRequested est en vol.
      final completer = Completer<SearchResultsPageDto>();
      when(() => mangaService.searchForMangas('naruto',
          page: 1, limit: SearchBloc.pageSize)).thenAnswer((_) => completer.future);

      bloc.add(const SearchRequested('naruto'));
      await bloc.stream.firstWhere((s) => s is SearchLoading);
      bloc.add(const SearchCleared());
      await bloc.stream.firstWhere((s) => s is SearchInitial);

      completer.complete(pageDto([manga(1, 'Naruto')]));
      await Future<void>.delayed(const Duration(milliseconds: 20));

      expect(bloc.state, const SearchInitial());
    });

    test('should ignore a stale response when a newer query finished first',
        () async {
      final slowCompleter = Completer<SearchResultsPageDto>();
      when(() => mangaService.searchForMangas('naruto',
              page: 1, limit: SearchBloc.pageSize))
          .thenAnswer((_) => slowCompleter.future);
      final onePiece = [manga(9, 'One Piece')];
      when(() => mangaService.searchForMangas('one piece',
              page: 1, limit: SearchBloc.pageSize))
          .thenAnswer((_) async => pageDto(onePiece));

      bloc.add(const SearchRequested('naruto'));
      await bloc.stream.firstWhere((s) => s is SearchLoading);
      bloc.add(const SearchRequested('one piece'));
      await bloc.stream.firstWhere(
          (s) => s is SearchLoaded && s.query == 'one piece');

      slowCompleter.complete(pageDto([manga(1, 'Naruto')]));
      await Future<void>.delayed(const Duration(milliseconds: 20));

      expect(
        bloc.state,
        isA<SearchLoaded>().having((s) => s.query, 'query', 'one piece'),
      );
    });

    test('should emit offline error when offline without cache', () async {
      when(() => mangaService.searchForMangas('naruto',
              page: 1, limit: SearchBloc.pageSize))
          .thenThrow(const SocketException('offline'));
      when(() => cacheService.getCachedSearchResults('naruto'))
          .thenAnswer((_) async => null);

      final expectation = expectLater(
        bloc.stream,
        emitsInOrder([
          const SearchLoading('naruto'),
          const SearchError('naruto', isOffline: true),
        ]),
      );
      bloc.add(const SearchRequested('naruto'));
      await expectation;
    });
  });

  group('SearchNextPageRequested', () {
    Future<void> seedFirstPage(List<MangaQuickViewDto> results,
        {bool hasMore = true}) async {
      when(() => mangaService.searchForMangas('shadow',
              page: 1, limit: SearchBloc.pageSize))
          .thenAnswer((_) async => pageDto(results, hasMore: hasMore));
      bloc.add(const SearchRequested('shadow'));
      await bloc.stream.firstWhere((s) => s is SearchLoaded);
    }

    test('should append the next page and dedupe by muId', () async {
      final page1 = [manga(1, 'Shadow System'), manga(2, 'Shadow')];
      // Le n°2 réapparaît en page 2 (glissement de classement MU) → dédoublonné.
      final page2 = [manga(2, 'Shadow'), manga(3, 'Planet Shadow')];
      await seedFirstPage(page1);
      when(() => mangaService.searchForMangas('shadow',
              page: 2, limit: SearchBloc.pageSize))
          .thenAnswer((_) async => pageDto(page2, page: 2, hasMore: false));

      final expectation = expectLater(
        bloc.stream,
        emitsInOrder([
          isA<SearchLoaded>()
              .having((s) => s.isLoadingMore, 'isLoadingMore', true),
          isA<SearchLoaded>()
              .having((s) => s.results.map((m) => m.muId).toList(),
                  'results muIds', [1, 2, 3])
              .having((s) => s.page, 'page', 2)
              .having((s) => s.hasMore, 'hasMore', false)
              .having((s) => s.isLoadingMore, 'isLoadingMore', false),
        ]),
      );
      bloc.add(const SearchNextPageRequested());
      await expectation;
    });

    test('should do nothing when there is no next page', () async {
      await seedFirstPage([manga(1, 'Shadow System')], hasMore: false);

      bloc.add(const SearchNextPageRequested());
      await Future<void>.delayed(const Duration(milliseconds: 20));

      verifyNever(() => mangaService.searchForMangas(any(),
          page: 2, limit: SearchBloc.pageSize));
    });

    test('should not resurrect old results if cleared while loading a page',
        () async {
      await seedFirstPage([manga(1, 'Shadow System')]);
      final completer = Completer<SearchResultsPageDto>();
      when(() => mangaService.searchForMangas('shadow',
          page: 2, limit: SearchBloc.pageSize)).thenAnswer((_) => completer.future);

      bloc.add(const SearchNextPageRequested());
      await bloc.stream
          .firstWhere((s) => s is SearchLoaded && s.isLoadingMore);
      bloc.add(const SearchCleared());
      await bloc.stream.firstWhere((s) => s is SearchInitial);

      completer.complete(
          pageDto([manga(3, 'Planet Shadow')], page: 2, hasMore: false));
      await Future<void>.delayed(const Duration(milliseconds: 20));

      expect(bloc.state, const SearchInitial());
    });

    test('should flag loadMoreFailed and keep results on failure', () async {
      final page1 = [manga(1, 'Shadow System')];
      await seedFirstPage(page1);
      when(() => mangaService.searchForMangas('shadow',
              page: 2, limit: SearchBloc.pageSize))
          .thenThrow(Exception('boom'));

      final expectation = expectLater(
        bloc.stream,
        emitsInOrder([
          isA<SearchLoaded>()
              .having((s) => s.isLoadingMore, 'isLoadingMore', true),
          isA<SearchLoaded>()
              .having((s) => s.loadMoreFailed, 'loadMoreFailed', true)
              .having((s) => s.results, 'results', page1)
              .having((s) => s.isLoadingMore, 'isLoadingMore', false),
        ]),
      );
      bloc.add(const SearchNextPageRequested());
      await expectation;
    });
  });

  group('SearchCleared', () {
    test('should reset to the initial state', () async {
      final expectation = expectLater(bloc.stream, emits(const SearchInitial()));
      bloc.add(const SearchCleared());
      await expectation;
    });
  });
}
