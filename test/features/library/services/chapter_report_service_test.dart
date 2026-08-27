import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:mangatracker/core/network/http_service.dart';
import 'package:mangatracker/features/library/services/chapter_report.service.dart';
import 'package:mocktail/mocktail.dart';

class MockHttpService extends Mock implements HttpService {}

/// Tests du service « Signaler plus de chapitres » (chantier A) :
/// parse du 201 et mapping des erreurs typées 400 / 404 / 429.
void main() {
  late MockHttpService httpService;
  late ChapterReportService service;

  setUpAll(() {
    // `buildApiUri` lit MT_API_URL depuis dotenv.
    dotenv.testLoad(fileInput: 'MT_API_URL=https://api.test');
    registerFallbackValue(Uri.parse('https://api.test'));
  });

  setUp(() {
    httpService = MockHttpService();
    service = ChapterReportService(httpService: httpService);
  });

  void stubPost(int statusCode, String body) {
    when(() => httpService.postWithAuthTokens(
          any(),
          headers: any(named: 'headers'),
          body: any(named: 'body'),
        )).thenAnswer((_) async => http.Response(body, statusCode));
  }

  group('ChapterReportService.reportMoreChapters', () {
    test('201 → parse le résultat (reportedTotal, effectiveTotal, consolidated)',
        () async {
      stubPost(
        201,
        '{"reportedTotal":150,"effectiveTotalChapters":150,"consolidated":false}',
      );

      final result = await service.reportMoreChapters(123, 150);

      expect(result.reportedTotal, 150);
      expect(result.effectiveTotalChapters, 150);
      expect(result.consolidated, false);
    });

    test('POST sur /library/:muId/report-chapters avec le bon body JSON',
        () async {
      stubPost(
        201,
        '{"reportedTotal":150,"effectiveTotalChapters":152,"consolidated":true}',
      );

      final result = await service.reportMoreChapters(123, 150);

      expect(result.effectiveTotalChapters, 152);
      expect(result.consolidated, true);
      final captured = verify(() => httpService.postWithAuthTokens(
            captureAny(),
            headers: any(named: 'headers'),
            body: captureAny(named: 'body'),
          )).captured;
      expect((captured[0] as Uri).path, '/library/123/report-chapters');
      expect(captured[1], '{"reportedTotal":150}');
    });

    test('400 (bornes) → ChapterReportException.invalidTotal', () async {
      stubPost(400, '{"message":"reportedTotal out of bounds"}');

      expect(
        () => service.reportMoreChapters(123, 10),
        throwsA(isA<ChapterReportException>().having(
          (e) => e.failure,
          'failure',
          ChapterReportFailure.invalidTotal,
        )),
      );
    });

    test('404 (hors bibliothèque) → ChapterReportException.notInLibrary',
        () async {
      stubPost(404, '{"message":"manga not in library"}');

      expect(
        () => service.reportMoreChapters(123, 150),
        throwsA(isA<ChapterReportException>().having(
          (e) => e.failure,
          'failure',
          ChapterReportFailure.notInLibrary,
        )),
      );
    });

    test('429 (throttle) → ChapterReportException.throttled', () async {
      stubPost(429, '{"message":"too many requests"}');

      expect(
        () => service.reportMoreChapters(123, 150),
        throwsA(isA<ChapterReportException>().having(
          (e) => e.failure,
          'failure',
          ChapterReportFailure.throttled,
        )),
      );
    });

    test('code inattendu (500) → ChapterReportException.unknown', () async {
      stubPost(500, 'oops');

      expect(
        () => service.reportMoreChapters(123, 150),
        throwsA(isA<ChapterReportException>()
            .having((e) => e.failure, 'failure', ChapterReportFailure.unknown)
            .having((e) => e.statusCode, 'statusCode', 500)),
      );
    });
  });
}
