import 'dart:convert';

import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:mangatracker/core/network/http_service.dart';
import 'package:mangatracker/core/service_locator/service_locator.dart';
import 'package:mangatracker/core/services/connectivity_service.dart';
import 'package:mangatracker/core/services/offline_cache_service.dart';
import 'package:mangatracker/features/library/services/library.service.dart';
import 'package:mangatracker/features/manga/dto/manga_quick_view.dto.dart';
import 'package:mocktail/mocktail.dart';

class MockHttpService extends Mock implements HttpService {}

class MockConnectivityService extends Mock implements ConnectivityService {}

class MockOfflineCacheService extends Mock implements OfflineCacheService {}

class FakeOfflineAction extends Fake implements OfflineAction {}

/// `LibraryService` — ajout d'un titre déjà présent et lecture du lien.
void main() {
  late MockHttpService httpService;
  late MockConnectivityService connectivity;
  late MockOfflineCacheService cache;
  late LibraryService service;

  setUpAll(() {
    dotenv.testLoad(fileInput: 'MT_API_URL=https://api.test');
    registerFallbackValue(Uri.parse('https://api.test'));
    registerFallbackValue(FakeOfflineAction());
    registerFallbackValue(<MangaQuickViewDto>[]);
  });

  setUp(() async {
    httpService = MockHttpService();
    connectivity = MockConnectivityService();
    cache = MockOfflineCacheService();

    await getIt.reset();
    getIt.registerSingleton<HttpService>(httpService);
    getIt.registerSingleton<ConnectivityService>(connectivity);
    getIt.registerSingleton<OfflineCacheService>(cache);

    when(() => connectivity.isConnected).thenReturn(true);
    when(() => cache.invalidateRecommendationsCache()).thenAnswer((_) async {});
    when(() => cache.cacheLibrary(any())).thenAnswer((_) async {});

    service = LibraryService();
    await service.init();
  });

  tearDown(() async => getIt.reset());

  void stubSave(int code, String body) {
    when(() => httpService.postWithAuthTokens(
          any(),
          headers: any(named: 'headers'),
          body: any(named: 'body'),
        )).thenAnswer((_) async => http.Response(body, code));
  }

  group('addMangaToLibrary — déjà dans la bibliothèque = succès', () {
    test('201 → ajouté', () async {
      stubSave(201, '{}');
      expect(await service.addMangaToLibrary(42), isTrue);
    });

    test('409 → déjà présent, succès', () async {
      stubSave(409, '{"message":"Manga already saved"}');
      expect(await service.addMangaToLibrary(42), isTrue);
    });

    test('400 « Manga already saved » (API antérieure) → succès', () async {
      stubSave(400, '{"statusCode":400,"message":"Manga already saved"}');
      expect(await service.addMangaToLibrary(42), isTrue);
    });

    test('un autre 400 reste un échec', () async {
      stubSave(400, '{"message":"muId must be a number"}');
      expect(await service.addMangaToLibrary(42), isFalse);
    });
  });

  group('getCustomLink — lu dans la bibliothèque', () {
    test('lit l\'entrée de bibliothèque, sans télécharger la fiche', () async {
      when(() => httpService.getWithAuthTokens(any())).thenAnswer(
        (_) async => http.Response(
          jsonEncode([
            {
              'muId': 42,
              'title': 'Solo Leveling',
              'customLink': 'https://site.example/sl/chapitre-125',
            },
          ]),
          200,
        ),
      );

      expect(await service.getCustomLink(42),
          'https://site.example/sl/chapitre-125');
      final paths = verify(() => httpService.getWithAuthTokens(captureAny()))
          .captured
          .map((u) => (u as Uri).path);
      expect(paths, ['/library/all']);
    });

    test('hors ligne → lien du cache', () async {
      when(() => httpService.getWithAuthTokens(any()))
          .thenThrow(Exception('offline'));
      when(() => cache.getCachedLibrary()).thenAnswer(
        (_) async => [
          MangaQuickViewDto(
            muId: 42,
            title: 'Solo Leveling',
            year: '2018',
            rating: '9.1',
            customLink: 'https://site.example/sl/chapitre-125',
          ),
        ],
      );

      expect(await service.getCustomLink(42),
          'https://site.example/sl/chapitre-125');
    });
  });
}
