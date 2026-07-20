import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:mangatracker/core/network/http_service.dart';
import 'package:mangatracker/core/service_locator/service_locator.dart';
import 'package:mangatracker/core/services/offline_cache_service.dart';
import 'package:mangatracker/features/manga/dto/manga_quick_view.dto.dart';
import 'package:mangatracker/features/manga/services/recommendation.service.dart';
import 'package:mocktail/mocktail.dart';

class MockHttpService extends Mock implements HttpService {}

class MockOfflineCacheService extends Mock implements OfflineCacheService {}

/// Test du garde-fou cache (fix « page Tout plafonnée à 5 ») : le cache de
/// la première page n'est servi que s'il couvre la limite demandée.
void main() {
  late MockHttpService httpService;
  late MockOfflineCacheService cacheService;
  late RecommendationService service;

  List<MangaQuickViewDto> mangas(int count) => List.generate(
        count,
        (i) => MangaQuickViewDto(
          muId: i + 1,
          title: 'Manga ${i + 1}',
          year: '2020',
          rating: '7',
        ),
      );

  setUpAll(() {
    dotenv.testLoad(fileInput: 'MT_API_URL=https://api.test');
    registerFallbackValue(Uri.parse('https://api.test'));
  });

  setUp(() async {
    await getIt.reset();
    httpService = MockHttpService();
    cacheService = MockOfflineCacheService();
    getIt.registerSingleton<HttpService>(httpService);
    getIt.registerSingleton<OfflineCacheService>(cacheService);
    service = RecommendationService();

    // Cache frais par défaut.
    when(() => cacheService.isCacheExpiredFor(any(),
        maxHours: any(named: 'maxHours'))).thenAnswer((_) async => false);
    when(() => cacheService.cacheRecommendations(any()))
        .thenAnswer((_) async {});
  });

  tearDown(() async => getIt.reset());

  group('RecommendationService — garde-fou cache première page', () {
    test('cache court (10) + limit 50 → appel réseau (le cache est ignoré)',
        () async {
      when(() => cacheService.getCachedRecommendations())
          .thenAnswer((_) async => mangas(10));
      when(() => httpService.getWithAuthTokens(any(),
          headers: any(named: 'headers'))).thenAnswer(
        (_) async => http.Response(
          '[{"muId":99,"title":"Depuis le réseau","year":"2021","rating":8}]',
          200,
        ),
      );

      final result =
          await service.getPersonalizedRecommendations(limit: 50, offset: 0);

      expect(result, hasLength(1));
      expect(result.first.title, 'Depuis le réseau');
      verify(() => httpService.getWithAuthTokens(any(),
          headers: any(named: 'headers'))).called(1);
    });

    test('cache couvrant (10) + limit 10 → servi du cache, zéro réseau',
        () async {
      when(() => cacheService.getCachedRecommendations())
          .thenAnswer((_) async => mangas(10));

      final result =
          await service.getPersonalizedRecommendations(limit: 10, offset: 0);

      expect(result, hasLength(10));
      verifyNever(() => httpService.getWithAuthTokens(any(),
          headers: any(named: 'headers')));
    });

    test('offset > 0 → jamais servi du cache même s\'il est frais', () async {
      when(() => httpService.getWithAuthTokens(any(),
          headers: any(named: 'headers'))).thenAnswer(
        (_) async => http.Response('[]', 200),
      );

      await service.getPersonalizedRecommendations(limit: 50, offset: 50);

      verifyNever(() => cacheService.getCachedRecommendations());
      verify(() => httpService.getWithAuthTokens(any(),
          headers: any(named: 'headers'))).called(1);
    });
  });
}
