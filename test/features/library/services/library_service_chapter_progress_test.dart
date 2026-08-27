import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:mangatracker/core/network/http_service.dart';
import 'package:mangatracker/core/service_locator/service_locator.dart';
import 'package:mangatracker/core/services/connectivity_service.dart';
import 'package:mangatracker/core/services/offline_cache_service.dart';
import 'package:mangatracker/features/library/services/chapter_report.service.dart';
import 'package:mangatracker/features/library/services/library.service.dart';
import 'package:mocktail/mocktail.dart';

class MockHttpService extends Mock implements HttpService {}

class MockConnectivityService extends Mock implements ConnectivityService {}

class MockOfflineCacheService extends Mock implements OfflineCacheService {}

class MockChapterReportService extends Mock implements ChapterReportService {}

class FakeOfflineAction extends Fake implements OfflineAction {}

/// `LibraryService.saveChapterProgress` — rattrapage du 406.
///
/// L'API cape `readChapters` au total effectif du manga et répond 406
/// au-delà. Avant ce correctif, la progression pourtant confirmée par
/// l'utilisateur était perdue en silence (`_lastCommitted` non mis à jour,
/// aucun message). Le rattrapage est **opt-in** : il ne doit jamais
/// s'armer sur une détection automatique d'URL.
void main() {
  late MockHttpService httpService;
  late MockConnectivityService connectivity;
  late MockOfflineCacheService cache;
  late MockChapterReportService chapterReport;
  late LibraryService service;

  setUpAll(() {
    // `buildApiUri` lit MT_API_URL depuis dotenv.
    dotenv.testLoad(fileInput: 'MT_API_URL=https://api.test');
    registerFallbackValue(Uri.parse('https://api.test'));
    registerFallbackValue(FakeOfflineAction());
  });

  setUp(() async {
    httpService = MockHttpService();
    connectivity = MockConnectivityService();
    cache = MockOfflineCacheService();
    chapterReport = MockChapterReportService();

    await getIt.reset();
    getIt.registerSingleton<HttpService>(httpService);
    getIt.registerSingleton<ConnectivityService>(connectivity);
    getIt.registerSingleton<OfflineCacheService>(cache);
    getIt.registerSingleton<ChapterReportService>(chapterReport);

    when(() => connectivity.isConnected).thenReturn(true);
    when(() => cache.invalidateRecommendationsCache())
        .thenAnswer((_) async {});
    when(() => cache.queueOfflineAction(any())).thenAnswer((_) async {});

    service = LibraryService();
    await service.init();
  });

  tearDown(() async => getIt.reset());

  /// Rejoue `statusCodes` dans l'ordre sur les PUT successifs ; le dernier
  /// code est conservé pour tout appel supplémentaire (ce qui ferait
  /// apparaître une éventuelle boucle de retry).
  void stubPut(List<int> statusCodes) {
    var call = 0;
    when(() => httpService.putWithAuthTokens(
          any(),
          headers: any(named: 'headers'),
          body: any(named: 'body'),
        )).thenAnswer((_) async {
      final code = statusCodes[
          call < statusCodes.length ? call : statusCodes.length - 1];
      call++;
      return http.Response('{}', code);
    });
  }

  int putCount() => verify(() => httpService.putWithAuthTokens(
        any(),
        headers: any(named: 'headers'),
        body: any(named: 'body'),
      )).callCount;

  group('saveChapterProgress — chemin nominal', () {
    test('200 → succès, aucun signalement', () async {
      stubPut([200]);

      final ok = await service.saveChapterProgress(123, 42,
          autoReportIfAboveTotal: true);

      expect(ok, isTrue);
      verifyNever(() => chapterReport.reportMoreChapters(any(), any()));
      expect(putCount(), 1);
      verify(() => cache.invalidateRecommendationsCache()).called(1);
    });
  });

  group('saveChapterProgress — 406 avec rattrapage activé', () {
    test('signale le total lu puis rejoue le PUT → progression conservée',
        () async {
      stubPut([406, 200]);
      when(() => chapterReport.reportMoreChapters(any(), any())).thenAnswer(
        (_) async => const ChapterReportResult(
          reportedTotal: 90,
          effectiveTotalChapters: 90,
          consolidated: false,
        ),
      );

      final ok = await service.saveChapterProgress(123, 90,
          autoReportIfAboveTotal: true);

      expect(ok, isTrue, reason: 'la lecture confirmée doit être sauvegardée');
      // Le total signalé est bien le nombre de chapitres lus.
      verify(() => chapterReport.reportMoreChapters(123, 90)).called(1);
      expect(putCount(), 2, reason: 'un seul rejeu, pas de boucle');
    });
  });

  group('saveChapterProgress — 406 sans rattrapage (non-régression)', () {
    test('flag désactivé → aucun signalement, échec silencieux comme avant',
        () async {
      stubPut([406]);

      final ok = await service.saveChapterProgress(123, 90);

      expect(ok, isFalse);
      verifyNever(() => chapterReport.reportMoreChapters(any(), any()));
      expect(putCount(), 1, reason: 'pas de rejeu sur le chemin navigation');
      verifyNever(() => cache.invalidateRecommendationsCache());
    });

    test('flag par défaut = désactivé', () async {
      stubPut([406]);

      await service.saveChapterProgress(123, 90);

      verifyNever(() => chapterReport.reportMoreChapters(any(), any()));
    });
  });

  group('saveChapterProgress — 406 avec signalement refusé', () {
    test('429 (throttle) → false, pas de rejeu, pas de crash', () async {
      stubPut([406, 200]);
      when(() => chapterReport.reportMoreChapters(any(), any())).thenThrow(
        const ChapterReportException(ChapterReportFailure.throttled, 429),
      );

      final ok = await service.saveChapterProgress(123, 90,
          autoReportIfAboveTotal: true);

      expect(ok, isFalse);
      verify(() => chapterReport.reportMoreChapters(123, 90)).called(1);
      expect(putCount(), 1, reason: 'aucun rejeu si le signalement échoue');
    });

    test('400 (hors bornes) → false, pas de rejeu, pas de crash', () async {
      stubPut([406, 200]);
      when(() => chapterReport.reportMoreChapters(any(), any())).thenThrow(
        const ChapterReportException(ChapterReportFailure.invalidTotal, 400),
      );

      final ok = await service.saveChapterProgress(123, 90,
          autoReportIfAboveTotal: true);

      expect(ok, isFalse);
      expect(putCount(), 1);
    });

    test('erreur réseau pendant le signalement → false, pas de crash',
        () async {
      stubPut([406, 200]);
      when(() => chapterReport.reportMoreChapters(any(), any()))
          .thenThrow(Exception('network down'));

      final ok = await service.saveChapterProgress(123, 90,
          autoReportIfAboveTotal: true);

      expect(ok, isFalse);
      expect(putCount(), 1);
    });
  });

  group('saveChapterProgress — hors ligne', () {
    test('mise en queue comme avant, aucun signalement', () async {
      when(() => connectivity.isConnected).thenReturn(false);

      final ok = await service.saveChapterProgress(123, 90,
          autoReportIfAboveTotal: true);

      expect(ok, isTrue, reason: 'action mise en queue');
      verify(() => cache.queueOfflineAction(any())).called(1);
      verifyNever(() => chapterReport.reportMoreChapters(any(), any()));
      verifyNever(() => httpService.putWithAuthTokens(
            any(),
            headers: any(named: 'headers'),
            body: any(named: 'body'),
          ));
    });
  });
}
