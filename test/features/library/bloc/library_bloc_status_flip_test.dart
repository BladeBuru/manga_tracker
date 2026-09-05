import 'dart:async';
import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:mangatracker/core/service_locator/service_locator.dart';
import 'package:mangatracker/core/services/cache_helper_service.dart';
import 'package:mangatracker/core/services/connectivity_service.dart';
import 'package:mangatracker/core/services/offline_cache_service.dart';
import 'package:mangatracker/features/library/bloc/library_bloc.dart';
import 'package:mangatracker/features/library/bloc/library_event.dart';
import 'package:mangatracker/features/library/bloc/library_state.dart';
import 'package:mangatracker/features/library/services/library.service.dart';
import 'package:mangatracker/features/manga/dto/manga_quick_view.dto.dart';
import 'package:mangatracker/features/manga/dto/reading_status.enum.dart';
import 'package:mocktail/mocktail.dart';
import 'package:shared_preferences/shared_preferences.dart';

class MockLibraryService extends Mock implements LibraryService {}

class MockCacheHelperService extends Mock implements CacheHelperService {}

class MockConnectivityService extends Mock implements ConnectivityService {}

class MockOfflineCacheService extends Mock implements OfflineCacheService {}

MangaQuickViewDto manga(int muId, ReadingStatus status, {num read = 39}) =>
    MangaQuickViewDto(
      muId: muId,
      title: 'Manga $muId',
      year: '2020',
      rating: '8.0',
      readingStatus: status,
      readChapters: read,
      totalChapters: 39,
    );

/// Bibliothèque « à jour » au 39 (mu 42) + « en cours » (mu 7).
List<MangaQuickViewDto> library() => [
      manga(42, ReadingStatus.caughtUp),
      manga(7, ReadingStatus.reading),
    ];

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late MockLibraryService libraryService;
  late MockCacheHelperService cacheHelper;
  late MockConnectivityService connectivityService;
  late MockOfflineCacheService offlineCache;
  late StreamController<bool> connectivityController;

  setUpAll(() {
    registerFallbackValue(ReadingStatus.reading);
    registerFallbackValue(<MangaQuickViewDto>[]);
  });

  /// Chapitres détectés localement (`NewChapterService`, préférences).
  void seedLocalNewChapters(Map<int, List<int>> byMuId) {
    SharedPreferences.setMockInitialValues({
      'new_chapters_map': jsonEncode(
        byMuId.map((k, v) => MapEntry(k.toString(), v)),
      ),
    });
  }

  setUp(() {
    SharedPreferences.setMockInitialValues({});
    libraryService = MockLibraryService();
    cacheHelper = MockCacheHelperService();
    connectivityService = MockConnectivityService();
    offlineCache = MockOfflineCacheService();
    connectivityController = StreamController<bool>.broadcast();

    when(() => connectivityService.connectivityStream)
        .thenAnswer((_) => connectivityController.stream);
    when(() => connectivityService.isConnected).thenReturn(true);
    when(() => connectivityService.checkConnectivity())
        .thenAnswer((_) async => true);
    when(() => cacheHelper.getOfflineQueue())
        .thenAnswer((_) async => <OfflineAction>[]);
    when(() => cacheHelper.getCachedLibrary()).thenAnswer((_) async => null);
    when(() => cacheHelper.loadLibraryData(
          networkCall: any(named: 'networkCall'),
        )).thenAnswer((invocation) async {
      final networkCall = invocation.namedArguments[#networkCall]
          as Future<List<MangaQuickViewDto>> Function();
      return networkCall();
    });
    when(() => libraryService.getUserSavedMangas())
        .thenAnswer((_) async => library());
    when(() => libraryService.updateMangaStatus(any(), any()))
        .thenAnswer((_) async => true);
    when(() => offlineCache.cacheLibrary(any())).thenAnswer((_) async {});

    getIt.registerSingleton<LibraryService>(libraryService);
    getIt.registerSingleton<CacheHelperService>(cacheHelper);
    getIt.registerSingleton<ConnectivityService>(connectivityService);
    getIt.registerSingleton<OfflineCacheService>(offlineCache);
  });

  tearDown(() async {
    await connectivityController.close();
    await getIt.reset();
  });

  Future<LibraryLoaded> load(LibraryBloc bloc) async {
    bloc.add(const LoadLibrary());
    await Future<void>.delayed(const Duration(milliseconds: 50));
    expect(bloc.state, isA<LibraryLoaded>());
    return bloc.state as LibraryLoaded;
  }

  group('LibraryBloc — bascule auto « à jour » → « en cours »', () {
    test('chapitre 40 détecté localement sur une entrée « à jour » au 39 → « en cours »',
        () async {
      seedLocalNewChapters({42: [40]});
      final bloc = LibraryBloc();
      addTearDown(bloc.close);

      final state = await load(bloc);

      final flipped = state.mangas.firstWhere((m) => m.muId == 42);
      expect(flipped.readingStatus, ReadingStatus.reading);
      expect(flipped.hasNewChapters, isTrue);
      // L'entrée « en cours » n'est pas touchée.
      expect(state.mangas.firstWhere((m) => m.muId == 7).readingStatus,
          ReadingStatus.reading);
      // Le serveur est prévenu UNE fois, pour ce manga seulement.
      verify(() => libraryService.updateMangaStatus(42, ReadingStatus.reading))
          .called(1);
      verifyNever(() => libraryService.updateMangaStatus(7, any()));
      // Le cache hors ligne reflète la bascule.
      verify(() => offlineCache.cacheLibrary(any())).called(1);
    });

    test('rechargements successifs → toujours un seul appel réseau', () async {
      seedLocalNewChapters({42: [40]});
      final bloc = LibraryBloc();
      addTearDown(bloc.close);

      await load(bloc);
      bloc.add(const RefreshLibrary());
      await Future<void>.delayed(const Duration(milliseconds: 50));

      verify(() => libraryService.updateMangaStatus(42, ReadingStatus.reading))
          .called(1);
    });

    test('aucun chapitre détecté → statuts inchangés, aucun appel réseau',
        () async {
      final bloc = LibraryBloc();
      addTearDown(bloc.close);

      final state = await load(bloc);

      expect(state.mangas.firstWhere((m) => m.muId == 42).readingStatus,
          ReadingStatus.caughtUp);
      verifyNever(() => libraryService.updateMangaStatus(any(), any()));
      verifyNever(() => offlineCache.cacheLibrary(any()));
    });

    test('chapitre détecté déjà couvert par la progression → « à jour » conservé',
        () async {
      // Drapeau périmé : 40 détecté mais l'utilisateur a déjà lu le 40.
      seedLocalNewChapters({42: [40]});
      when(() => libraryService.getUserSavedMangas()).thenAnswer(
          (_) async => [manga(42, ReadingStatus.caughtUp, read: 40)]);
      final bloc = LibraryBloc();
      addTearDown(bloc.close);

      final state = await load(bloc);

      expect(state.mangas.single.readingStatus, ReadingStatus.caughtUp);
      verifyNever(() => libraryService.updateMangaStatus(any(), any()));
    });
  });
}
