import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:mangatracker/core/network/http_service.dart';
import 'package:mangatracker/core/network/network_compat.dart';
import 'package:mangatracker/core/services/connectivity_service.dart';
import 'package:mangatracker/core/services/offline_cache_service.dart';
import 'package:mangatracker/features/auth/exceptions/invalid_credentials.exception.dart';
import 'package:mangatracker/features/library/services/chapter_progress.service.dart';
import 'package:mangatracker/features/library/services/chapter_progress_result.dart';
import 'package:mangatracker/features/library/services/chapter_report.service.dart';
import 'package:mangatracker/features/library/services/library.service.dart';
import 'package:mocktail/mocktail.dart';

class MockHttpService extends Mock implements HttpService {}

class MockConnectivityService extends Mock implements ConnectivityService {}

class MockOfflineCacheService extends Mock implements OfflineCacheService {}

class MockChapterReportService extends Mock implements ChapterReportService {}

class MockLibraryService extends Mock implements LibraryService {}

class FakeOfflineAction extends Fake implements OfflineAction {}

/// `ChapterProgressService.save` — chaque réponse du serveur donne une issue
/// typée, que l'écran peut expliquer (au lieu d'un « false » muet).
void main() {
  late MockHttpService httpService;
  late MockConnectivityService connectivity;
  late MockOfflineCacheService cache;
  late MockChapterReportService reports;
  late MockLibraryService library;
  late ChapterProgressService service;

  const muId = 151;

  setUpAll(() {
    dotenv.testLoad(fileInput: 'MT_API_URL=https://api.test');
    registerFallbackValue(Uri.parse('https://api.test'));
    registerFallbackValue(FakeOfflineAction());
  });

  setUp(() {
    httpService = MockHttpService();
    connectivity = MockConnectivityService();
    cache = MockOfflineCacheService();
    reports = MockChapterReportService();
    library = MockLibraryService();

    when(() => connectivity.isConnected).thenReturn(true);
    when(() => cache.invalidateRecommendationsCache()).thenAnswer((_) async {});
    when(() => cache.queueOfflineAction(any())).thenAnswer((_) async {});

    service = ChapterProgressService(
      http: httpService,
      connectivity: connectivity,
      cache: cache,
      reports: reports,
      library: library,
    );
  });

  tearDown(() => service.dispose());

  /// Rejoue [codes] dans l'ordre sur les PUT successifs (le dernier code est
  /// conservé : une boucle de nouvel essai apparaîtrait dans le compte).
  void stubPut(List<int> codes) {
    var call = 0;
    when(() => httpService.putWithAuthTokens(
          any(),
          headers: any(named: 'headers'),
          body: any(named: 'body'),
        )).thenAnswer((_) async {
      final code = codes[call < codes.length ? call : codes.length - 1];
      call++;
      return http.Response('{}', code);
    });
  }

  void stubPutThrows(Object error) {
    when(() => httpService.putWithAuthTokens(
          any(),
          headers: any(named: 'headers'),
          body: any(named: 'body'),
        )).thenThrow(error);
  }

  int putCount() => verify(() => httpService.putWithAuthTokens(
        any(),
        headers: any(named: 'headers'),
        body: any(named: 'body'),
      )).callCount;

  OfflineAction queuedAction() =>
      verify(() => cache.queueOfflineAction(captureAny())).captured.single
          as OfflineAction;

  test('200 → enregistré, diffusé, cache des recommandations vidé', () async {
    stubPut([200]);
    final changes = <ChapterProgressChange>[];
    final sub = service.changes.listen(changes.add);
    final origin = Object();

    final result = await service.save(muId, 124, origin: origin);
    await Future<void>.delayed(Duration.zero);

    expect(result, const ChapterProgressSaved());
    expect(result.isSuccess, isTrue);
    expect(changes, [
      ChapterProgressChange(muId: muId, readChapters: 124, origin: origin),
    ]);
    verify(() => cache.invalidateRecommendationsCache()).called(1);
    verifyNever(() => cache.queueOfflineAction(any()));
    await sub.cancel();
  });

  test('406 → signalement accepté → 200 : total rattrapé', () async {
    stubPut([406, 200]);
    when(() => reports.reportMoreChapters(any(), any())).thenAnswer(
      (_) async => const ChapterReportResult(
        reportedTotal: 124,
        effectiveTotalChapters: 124,
        consolidated: false,
      ),
    );

    final result =
        await service.save(muId, 124, autoReportIfAboveTotal: true);

    expect(result, const ChapterProgressAboveTotalReported());
    expect(result.isAppliedOnServer, isTrue);
    verify(() => reports.reportMoreChapters(muId, 124)).called(1);
    expect(putCount(), 2, reason: 'un seul nouvel essai, jamais de boucle');
  });

  test('406 → signalement refusé (400 bornes) : total dépassé refusé',
      () async {
    stubPut([406]);
    when(() => reports.reportMoreChapters(any(), any())).thenThrow(
      const ChapterReportException(ChapterReportFailure.invalidTotal, 400),
    );

    final result =
        await service.save(muId, 999, autoReportIfAboveTotal: true);

    expect(result, const ChapterProgressAboveTotalRefused());
    expect(result.isSuccess, isFalse);
    expect(putCount(), 1);
  });

  test('406 sans rattrapage demandé : aucun signalement', () async {
    stubPut([406]);

    final result = await service.save(muId, 999);

    expect(result, const ChapterProgressAboveTotalRefused());
    verifyNever(() => reports.reportMoreChapters(any(), any()));
  });

  test('429 → limite de requêtes (réessayable)', () async {
    stubPut([429]);

    final result = await service.save(muId, 124);

    expect(result, const ChapterProgressThrottled());
    expect(result.isRetryable, isTrue);
    verifyNever(() => cache.queueOfflineAction(any()));
  });

  test('403 → session refusée, rien en file', () async {
    stubPut([403]);

    expect(await service.save(muId, 124), const ChapterProgressSessionRejected());
    verifyNever(() => cache.queueOfflineAction(any()));
  });

  test('401 persistant (exception de HttpService) → session refusée, rien en '
      'file', () async {
    stubPutThrows(InvalidCredentialsException('Refresh rejected by server'));

    expect(await service.save(muId, 124), const ChapterProgressSessionRejected());
    verifyNever(() => cache.queueOfflineAction(any()));
  });

  test('404 → titre absent de la bibliothèque', () async {
    stubPut([404]);

    expect(await service.save(muId, 124), const ChapterProgressNotInLibrary());
    verifyNever(() => library.addMangaToLibrary(any()));
  });

  test('404 + ajout demandé → ajout puis nouvel essai', () async {
    stubPut([404, 200]);
    when(() => library.addMangaToLibrary(muId)).thenAnswer((_) async => true);

    final result =
        await service.save(muId, 124, addToLibraryIfMissing: true);

    expect(result, const ChapterProgressSaved());
    expect(putCount(), 2);
  });

  test('réseau coupé pendant la requête → en file, confirmation conservée',
      () async {
    stubPutThrows(const SocketException('offline'));

    final result =
        await service.save(muId, 124, autoReportIfAboveTotal: true);

    expect(result, const ChapterProgressOfflineQueued());
    expect(result.isSuccess, isTrue);
    final action = queuedAction();
    expect(action.type, 'saveChapterProgress');
    expect(action.readChapters, 124);
    expect(action.confirmedByUser, isTrue,
        reason: 'au rejeu, le 406 doit être rattrapé comme en ligne');
  });

  test('appareil hors ligne → en file sans requête', () async {
    when(() => connectivity.isConnected).thenReturn(false);
    final changes = <ChapterProgressChange>[];
    final sub = service.changes.listen(changes.add);

    final result = await service.save(muId, 124);
    await Future<void>.delayed(Duration.zero);

    expect(result, const ChapterProgressOfflineQueued());
    expect(changes, isEmpty, reason: 'le serveur n\'a encore rien reçu');
    verifyNever(() => httpService.putWithAuthTokens(
          any(),
          headers: any(named: 'headers'),
          body: any(named: 'body'),
        ));
    expect(queuedAction().confirmedByUser, isFalse);
    await sub.cancel();
  });

  test('signalement impossible faute de réseau → progression en file',
      () async {
    stubPut([406]);
    when(() => reports.reportMoreChapters(any(), any()))
        .thenThrow(const SocketException('offline'));

    final result =
        await service.save(muId, 124, autoReportIfAboveTotal: true);

    expect(result, const ChapterProgressOfflineQueued());
  });

  test('500 → échec avec le code HTTP', () async {
    stubPut([500]);

    final result = await service.save(muId, 124);

    expect(result, isA<ChapterProgressFailure>());
    expect((result as ChapterProgressFailure).statusCode, 500);
    expect(result.isRetryable, isTrue);
  });

  test('valeur négative refusée sans requête', () async {
    final result = await service.save(muId, -1);

    expect(result, isA<ChapterProgressFailure>());
    verifyNever(() => httpService.putWithAuthTokens(
          any(),
          headers: any(named: 'headers'),
          body: any(named: 'body'),
        ));
  });

  group('ChapterProgressResult.fromStatusCode (pur)', () {
    test('mappe chaque code', () {
      expect(ChapterProgressResult.fromStatusCode(200),
          const ChapterProgressSaved());
      expect(ChapterProgressResult.fromStatusCode(204),
          const ChapterProgressSaved());
      expect(ChapterProgressResult.fromStatusCode(406),
          const ChapterProgressAboveTotalRefused());
      expect(ChapterProgressResult.fromStatusCode(429),
          const ChapterProgressThrottled());
      expect(ChapterProgressResult.fromStatusCode(401),
          const ChapterProgressSessionRejected());
      expect(ChapterProgressResult.fromStatusCode(404),
          const ChapterProgressNotInLibrary());
      expect(ChapterProgressResult.fromStatusCode(503),
          const ChapterProgressFailure(statusCode: 503, message: 'HTTP 503'));
    });

    test('signalement refusé : throttle, hors bibliothèque, session', () {
      expect(
        ChapterProgressResult.fromReportFailure(const ChapterReportException(
            ChapterReportFailure.throttled, 429)),
        const ChapterProgressThrottled(),
      );
      expect(
        ChapterProgressResult.fromReportFailure(const ChapterReportException(
            ChapterReportFailure.notInLibrary, 404)),
        const ChapterProgressNotInLibrary(),
      );
      expect(
        ChapterProgressResult.fromReportFailure(const ChapterReportException(
            ChapterReportFailure.unknown, 403)),
        const ChapterProgressSessionRejected(),
      );
    });
  });
}
