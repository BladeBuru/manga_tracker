import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:mangatracker/core/network/http_service.dart';
import 'package:mangatracker/core/services/offline_cache_service.dart';
import 'package:mangatracker/core/services/offline_queue_policy.dart';
import 'package:mangatracker/features/library/services/chapter_report.service.dart';
import 'package:mangatracker/features/library/services/offline_replay.service.dart';
import 'package:mocktail/mocktail.dart';

class MockHttpService extends Mock implements HttpService {}

class MockChapterReportService extends Mock implements ChapterReportService {}

/// Rejeu de la file hors ligne : un « déjà dans la bibliothèque » est un
/// succès, et une progression au-delà du total connu est rattrapée comme en
/// ligne — ou signalée à l'utilisateur, jamais abandonnée en silence.
void main() {
  late MockHttpService httpService;
  late MockChapterReportService reports;
  late List<OfflineAction> refused;
  late OfflineReplayService replay;

  const muId = 151;

  setUpAll(() {
    dotenv.testLoad(fileInput: 'MT_API_URL=https://api.test');
    registerFallbackValue(Uri.parse('https://api.test'));
  });

  setUp(() {
    httpService = MockHttpService();
    reports = MockChapterReportService();
    refused = [];
    replay = OfflineReplayService(
      http: httpService,
      reports: reports,
      onProgressRefused: refused.add,
    );
  });

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

  void stubPost(int code, String body) {
    when(() => httpService.postWithAuthTokens(
          any(),
          headers: any(named: 'headers'),
          body: any(named: 'body'),
        )).thenAnswer((_) async => http.Response(body, code));
  }

  OfflineAction progress({bool confirmed = false}) =>
      OfflineAction.saveChapterProgress(muId, 124, confirmedByUser: confirmed);

  group('ajout déjà présent = succès', () {
    test('409', () async {
      stubPost(409, '{"message":"Conflict"}');
      expect(await replay.replay(OfflineAction.addManga(muId)),
          ReplayDecision.done);
    });

    test('400 « Manga already saved » (API antérieure)', () async {
      stubPost(400, '{"statusCode":400,"message":"Manga already saved"}');
      expect(await replay.replay(OfflineAction.addManga(muId)),
          ReplayDecision.done);
    });

    test('un autre 400 reste un refus', () async {
      stubPost(400, '{"message":"muId must be a number"}');
      expect(await replay.replay(OfflineAction.addManga(muId)),
          ReplayDecision.drop);
    });
  });

  group('progression rejouée', () {
    test('200 → appliquée, rien à signaler', () async {
      stubPut([200]);
      expect(await replay.replay(progress()), ReplayDecision.done);
      expect(refused, isEmpty);
    });

    test('406 affirmé → signalement puis nouvel essai réussi', () async {
      stubPut([406, 200]);
      when(() => reports.reportMoreChapters(any(), any())).thenAnswer(
        (_) async => const ChapterReportResult(
          reportedTotal: 124,
          effectiveTotalChapters: 124,
          consolidated: false,
        ),
      );

      expect(await replay.replay(progress(confirmed: true)),
          ReplayDecision.done);
      verify(() => reports.reportMoreChapters(muId, 124)).called(1);
      expect(refused, isEmpty);
    });

    test('406 affirmé, signalement hors bornes → abandon SIGNALÉ', () async {
      stubPut([406]);
      when(() => reports.reportMoreChapters(any(), any())).thenThrow(
        const ChapterReportException(ChapterReportFailure.invalidTotal, 400),
      );

      expect(await replay.replay(progress(confirmed: true)),
          ReplayDecision.drop);
      expect(refused.single.readChapters, 124);
    });

    test('406 affirmé, signalement limité (429) → on retentera', () async {
      stubPut([406]);
      when(() => reports.reportMoreChapters(any(), any())).thenThrow(
        const ChapterReportException(ChapterReportFailure.throttled, 429),
      );

      expect(await replay.replay(progress(confirmed: true)),
          ReplayDecision.retryLater);
      expect(refused, isEmpty);
    });

    test('406 détecté automatiquement → pas de signalement, abandon signalé',
        () async {
      stubPut([406]);

      expect(await replay.replay(progress()), ReplayDecision.drop);
      verifyNever(() => reports.reportMoreChapters(any(), any()));
      expect(refused, hasLength(1));
    });

    test('404 → abandon signalé', () async {
      stubPut([404]);
      expect(await replay.replay(progress()), ReplayDecision.drop);
      expect(refused, hasLength(1));
    });

    test('503 → gardée pour plus tard, rien à signaler', () async {
      stubPut([503]);
      expect(await replay.replay(progress()), ReplayDecision.retryLater);
      expect(refused, isEmpty);
    });
  });

  test('la confirmation survit à la sérialisation de la file', () {
    final json = progress(confirmed: true).toJson();
    expect(OfflineAction.fromJson(json).confirmedByUser, isTrue);
    expect(
      OfflineAction.fromJson(progress().toJson()).confirmedByUser,
      isFalse,
    );
    // Entrée d'une version précédente (sans le champ).
    final legacy = Map<String, dynamic>.of(progress().toJson())
      ..remove('confirmedByUser');
    expect(OfflineAction.fromJson(legacy).confirmedByUser, isFalse);
  });
}
