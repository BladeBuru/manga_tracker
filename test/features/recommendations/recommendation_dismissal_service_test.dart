import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:mangatracker/core/network/http_service.dart';
import 'package:mangatracker/core/services/offline_cache_service.dart';
import 'package:mangatracker/features/recommendations/dto/dismissal_reason.dart';
import 'package:mangatracker/features/recommendations/services/recommendation_dismissal.service.dart';
import 'package:mocktail/mocktail.dart';

class MockHttpService extends Mock implements HttpService {}

class MockOfflineCacheService extends Mock implements OfflineCacheService {}

/// Tests du service de rejet « pas intéressé / déjà vu » : contrat HTTP,
/// mapping des erreurs typées, et surtout invalidation du cache local — sans
/// elle le titre écarté réapparaîtrait pendant 2 h et le geste paraîtrait
/// sans effet.
void main() {
  late MockHttpService httpService;
  late MockOfflineCacheService cacheService;
  late RecommendationDismissalService service;

  setUpAll(() {
    // `buildApiUri` lit MT_API_URL depuis dotenv.
    dotenv.testLoad(fileInput: 'MT_API_URL=https://api.test');
    registerFallbackValue(Uri.parse('https://api.test'));
  });

  setUp(() {
    httpService = MockHttpService();
    cacheService = MockOfflineCacheService();
    when(
      () => cacheService.invalidateRecommendationsCache(),
    ).thenAnswer((_) async {});
    service = RecommendationDismissalService(
      httpService: httpService,
      cacheService: cacheService,
    );
  });

  void stubPost(int statusCode, [String body = '{}']) {
    when(
      () => httpService.postWithAuthTokens(
        any(),
        headers: any(named: 'headers'),
        body: any(named: 'body'),
      ),
    ).thenAnswer((_) async => http.Response(body, statusCode));
  }

  void stubDelete(int statusCode, [String body = '']) {
    when(
      () => httpService.deleteWithAuthTokens(
        any(),
        headers: any(named: 'headers'),
        body: any(named: 'body'),
      ),
    ).thenAnswer((_) async => http.Response(body, statusCode));
  }

  group('RecommendationDismissalService.dismiss', () {
    test('POST sur /recommendations/dismissals/:muId avec la raison', () async {
      stubPost(201);

      await service.dismiss(
        12345,
        DismissalReason.seenElsewhere,
      );

      final captured = verify(
        () => httpService.postWithAuthTokens(
          captureAny(),
          headers: any(named: 'headers'),
          body: captureAny(named: 'body'),
        ),
      ).captured;
      expect((captured[0] as Uri).path, '/recommendations/dismissals/12345');
      expect(captured[1], '{"reason":"seen_elsewhere"}');
    });

    test('envoie la valeur de fil attendue par l\'API pour chaque raison', () {
      expect(DismissalReason.alreadyRead.wireValue, 'already_read');
      expect(DismissalReason.notInterested.wireValue, 'not_interested');
      expect(DismissalReason.seenElsewhere.wireValue, 'seen_elsewhere');
    });

    test('invalide le cache local des recommandations', () async {
      stubPost(201);

      await service.dismiss(12345, DismissalReason.alreadyRead);

      verify(() => cacheService.invalidateRecommendationsCache()).called(1);
    });

    test('429 → DismissalFailure.throttled, cache non invalidé', () async {
      stubPost(429, '{"message":"too many requests"}');

      await expectLater(
        service.dismiss(12345, DismissalReason.notInterested),
        throwsA(
          isA<DismissalException>().having(
            (e) => e.failure,
            'failure',
            DismissalFailure.throttled,
          ),
        ),
      );
      verifyNever(() => cacheService.invalidateRecommendationsCache());
    });

    test('404 (manga inconnu) → DismissalFailure.notFound', () async {
      stubPost(404, '{"message":"Manga 1 not found"}');

      await expectLater(
        service.dismiss(1, DismissalReason.notInterested),
        throwsA(
          isA<DismissalException>().having(
            (e) => e.failure,
            'failure',
            DismissalFailure.notFound,
          ),
        ),
      );
    });

    test('500 → DismissalFailure.unknown avec le code HTTP', () async {
      stubPost(500, 'oops');

      await expectLater(
        service.dismiss(12345, DismissalReason.alreadyRead),
        throwsA(
          isA<DismissalException>()
              .having((e) => e.failure, 'failure', DismissalFailure.unknown)
              .having((e) => e.statusCode, 'statusCode', 500),
        ),
      );
    });
  });

  group('RecommendationDismissalService.restore', () {
    test('DELETE sur /recommendations/dismissals/:muId', () async {
      stubDelete(204);

      await service.restore(12345);

      final captured = verify(
        () => httpService.deleteWithAuthTokens(
          captureAny(),
          headers: any(named: 'headers'),
          body: any(named: 'body'),
        ),
      ).captured;
      expect((captured[0] as Uri).path, '/recommendations/dismissals/12345');
    });

    test('204 → invalide le cache pour que le titre puisse revenir', () async {
      stubDelete(204);

      await service.restore(12345);

      verify(() => cacheService.invalidateRecommendationsCache()).called(1);
    });

    test('404 (rejet déjà annulé) → DismissalFailure.notFound', () async {
      stubDelete(404, '{"message":"Aucun rejet enregistré"}');

      await expectLater(
        service.restore(12345),
        throwsA(
          isA<DismissalException>().having(
            (e) => e.failure,
            'failure',
            DismissalFailure.notFound,
          ),
        ),
      );
    });
  });
}
