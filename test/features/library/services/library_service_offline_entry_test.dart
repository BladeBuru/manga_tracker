import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mangatracker/core/network/http_service.dart';
import 'package:mangatracker/core/network/network_compat.dart';
import 'package:mangatracker/core/service_locator/service_locator.dart';
import 'package:mangatracker/core/services/connectivity_service.dart';
import 'package:mangatracker/core/services/offline_cache_service.dart';
import 'package:mangatracker/features/auth/exceptions/invalid_credentials.exception.dart';
import 'package:mangatracker/features/auth/exceptions/session_expired.exception.dart';
import 'package:mangatracker/features/library/services/library.service.dart';
import 'package:mangatracker/features/manga/dto/manga_quick_view.dto.dart';
import 'package:mangatracker/features/manga/dto/reading_status.enum.dart';
import 'package:mangatracker/features/manga/services/manga.service.dart';
import 'package:mocktail/mocktail.dart';

class MockHttpService extends Mock implements HttpService {}

class MockOfflineCacheService extends Mock implements OfflineCacheService {}

class MockConnectivityService extends Mock implements ConnectivityService {}

class MockMangaService extends Mock implements MangaService {}

class FakeUri extends Fake implements Uri {}

/// Entrée bibliothèque telle que mise en cache : elle porte la progression.
MangaQuickViewDto entry(num muId) => MangaQuickViewDto(
      muId: muId,
      title: 'Solo Leveling',
      year: '2018',
      rating: '9.1',
      readChapters: 132,
      totalChapters: 179,
      readingStatus: ReadingStatus.reading,
    );

void main() {
  late MockHttpService http;
  late MockOfflineCacheService cache;
  late MockConnectivityService connectivity;
  late LibraryService service;

  setUpAll(() {
    registerFallbackValue(FakeUri());
    registerFallbackValue(<MangaQuickViewDto>[]);
    // Sans dotenv, buildApiUri() leve NotInitializedError AVANT l'appel HTTP :
    // le test passerait pour une mauvaise raison (repli cache sur une erreur
    // de config, pas sur l'echec reseau qu'on veut couvrir).
    dotenv.testLoad(fileInput: 'MT_API_URL=https://api.test');
  });

  setUp(() async {
    http = MockHttpService();
    cache = MockOfflineCacheService();
    connectivity = MockConnectivityService();

    when(() => cache.cacheLibrary(any())).thenAnswer((_) async {});
    when(() => connectivity.isConnected).thenReturn(false);

    getIt.registerSingleton<HttpService>(http);
    getIt.registerSingleton<OfflineCacheService>(cache);
    getIt.registerSingleton<ConnectivityService>(connectivity);
    getIt.registerSingleton<MangaService>(MockMangaService());

    service = await LibraryService().init();
  });

  tearDown(() => getIt.reset());

  group('LibraryService.getLibraryEntry — progression hors ligne', () {
    test('hors ligne → la progression est lue depuis le cache', () async {
      // Sans repli, getUserSavedMangas() partait au reseau et l'exception
      // remontait : le detail s'affichait comme si le manga n'etait pas dans
      // la bibliotheque, donc SANS « ou j'en suis ».
      when(() => http.getWithAuthTokens(any()))
          .thenThrow(const SocketException('offline'));
      when(() => cache.getCachedLibrary()).thenAnswer((_) async => [entry(42)]);

      final result = await service.getLibraryEntry(42);

      expect(result, isNotNull);
      expect(result!.readChapters, 132);
      expect(result.readingStatus, ReadingStatus.reading);
    });

    test('token expiré → la progression est lue depuis le cache', () async {
      when(() => http.getWithAuthTokens(any()))
          .thenThrow(SessionExpiredException('Both tokens expired'));
      when(() => cache.getCachedLibrary()).thenAnswer((_) async => [entry(42)]);

      final result = await service.getLibraryEntry(42);

      expect(result?.readChapters, 132);
    });

    test('manga absent du cache → null, sans lever d\'exception', () async {
      when(() => http.getWithAuthTokens(any()))
          .thenThrow(const SocketException('offline'));
      when(() => cache.getCachedLibrary()).thenAnswer((_) async => [entry(7)]);

      expect(await service.getLibraryEntry(42), isNull);
    });

    test('cache vide → null, sans lever d\'exception', () async {
      when(() => http.getWithAuthTokens(any()))
          .thenThrow(const SocketException('offline'));
      when(() => cache.getCachedLibrary()).thenAnswer((_) async => null);

      expect(await service.getLibraryEntry(42), isNull);
    });

    test('session rejetée par le serveur → l\'exception remonte', () async {
      // Frontiere de securite : pas de repli cache sur un verdict serveur.
      when(() => http.getWithAuthTokens(any()))
          .thenThrow(InvalidCredentialsException('Refresh rejected by server'));
      // Stubbe malgre tout : on veut prouver que le cache n'est PAS consulte,
      // pas faire echouer l'appel sur un mock manquant.
      when(() => cache.getCachedLibrary()).thenAnswer((_) async => [entry(42)]);

      await expectLater(service.getLibraryEntry(42),
          throwsA(isA<InvalidCredentialsException>()));
      verifyNever(() => cache.getCachedLibrary());
    });
  });
}
