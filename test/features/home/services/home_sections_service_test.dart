import 'dart:convert';

import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:mangatracker/core/network/http_service.dart';
import 'package:mangatracker/core/storage/services/storage.service.dart';
import 'package:mangatracker/features/auth/exceptions/invalid_credentials.exception.dart';
import 'package:mangatracker/features/home/dto/home_section_kind.dart';
import 'package:mangatracker/features/home/services/home_sections.service.dart';
import 'package:mocktail/mocktail.dart';

import '../../../fixtures/fixtures.dart';

class MockHttpService extends Mock implements HttpService {}

class MockStorageService extends Mock implements StorageService {}

/// Contrat HTTP du service (URL, query, codes de retour), parse des fixtures
/// et cache hors ligne de la reponse complete.
void main() {
  late MockHttpService httpService;
  late MockStorageService storage;
  late HomeSectionsService service;

  setUpAll(() {
    dotenv.testLoad(fileInput: 'MT_API_URL=https://api.test');
    registerFallbackValue(Uri.parse('https://api.test'));
  });

  setUp(() {
    httpService = MockHttpService();
    storage = MockStorageService();
    when(() => storage.writeSecureData(any(), any())).thenAnswer((_) async {});
    service = HomeSectionsService(httpService: httpService, storage: storage);
  });

  void stubGet(int statusCode, String body) {
    when(
      () => httpService.getWithAuthTokens(any(), headers: any(named: 'headers')),
    ).thenAnswer((_) async => http.Response(body, statusCode));
  }

  Uri capturedUri() => verify(
        () => httpService.getWithAuthTokens(
          captureAny(),
          headers: any(named: 'headers'),
        ),
      ).captured.single as Uri;

  group('fetchSections', () {
    test('GET /mangas/home/sections?limit=20 et parse le contrat', () async {
      stubGet(200, loadFixture('home_sections.json'));

      final dto = await service.fetchSections();

      final uri = capturedUri();
      expect(uri.path, '/mangas/home/sections');
      expect(uri.queryParameters, {'limit': '20'});
      expect(dto.sections, hasLength(11));
      expect(dto.sections.first.kind, HomeSectionKind.latest);
      expect(dto.sections.any((s) => s.id == 'editorial:staff-picks'), isFalse,
          reason: 'kind inconnu ignore');
    });

    test('borne limit dans [5, 40]', () async {
      stubGet(200, loadFixture('home_sections.json'));
      await service.fetchSections(limit: 100);
      expect(capturedUri().queryParameters['limit'], '40');

      stubGet(200, loadFixture('home_sections.json'));
      await service.fetchSections(limit: 1);
      expect(capturedUri().queryParameters['limit'], '5');
    });

    test('met la reponse complete en cache sous cached_home_sections',
        () async {
      stubGet(200, loadFixture('home_sections.json'));

      await service.fetchSections();

      final captured = verify(
        () => storage.writeSecureData(captureAny(), captureAny()),
      ).captured;
      expect(captured[0], HomeSectionsService.cacheKey);
      expect(HomeSectionsService.cacheKey, startsWith('cached_'),
          reason: 'prefixe purge a la deconnexion');
      final envelope = jsonDecode(captured[1] as String) as Map<String, dynamic>;
      expect(envelope['cachedAt'], isA<String>());
      final data = envelope['data'] as Map<String, dynamic>;
      expect((data['sections'] as List), hasLength(11));
    });

    test('un echec d\'ecriture du cache ne fait pas echouer le fetch',
        () async {
      stubGet(200, loadFixture('home_sections.json'));
      when(() => storage.writeSecureData(any(), any()))
          .thenThrow(Exception('keystore KO'));

      final dto = await service.fetchSections();

      expect(dto.sections, isNotEmpty);
    });

    test('403 → InvalidCredentialsException (verdict serveur)', () async {
      stubGet(403, '{"message":"Forbidden"}');
      await expectLater(
        service.fetchSections(),
        throwsA(isA<InvalidCredentialsException>()),
      );
      verifyNever(() => storage.writeSecureData(any(), any()));
    });

    test('500 → Exception generique, cache intact', () async {
      stubGet(500, 'oops');
      await expectLater(service.fetchSections(), throwsA(isA<Exception>()));
      verifyNever(() => storage.writeSecureData(any(), any()));
    });

    test('corps qui n\'est pas un objet JSON → FormatException', () async {
      stubGet(200, '[]');
      await expectLater(
        service.fetchSections(),
        throwsA(isA<FormatException>()),
      );
    });
  });

  group('getCachedSections', () {
    test('relit la reponse mise en cache', () async {
      final envelope = jsonEncode({
        'cachedAt': '2026-09-05T10:05:00.000Z',
        'data': loadJsonFixture('home_sections.json'),
      });
      when(() => storage.readSecureData(HomeSectionsService.cacheKey))
          .thenAnswer((_) async => envelope);

      final cached = await service.getCachedSections();

      expect(cached, isNotNull);
      expect(cached!.sections, hasLength(11));
      expect(cached.sections[3].params.type, 'Manhwa');
    });

    test('cache absent → null', () async {
      when(() => storage.readSecureData(any())).thenAnswer((_) async => null);
      expect(await service.getCachedSections(), isNull);
    });

    test('cache corrompu → null sans lever', () async {
      when(() => storage.readSecureData(any()))
          .thenAnswer((_) async => '{pas du json');
      expect(await service.getCachedSections(), isNull);

      when(() => storage.readSecureData(any()))
          .thenAnswer((_) async => '{"cachedAt":"x","data":"pas un objet"}');
      expect(await service.getCachedSections(), isNull);
    });

    test('lecture qui leve → null sans lever', () async {
      when(() => storage.readSecureData(any())).thenThrow(Exception('KO'));
      expect(await service.getCachedSections(), isNull);
    });
  });

  group('fetchSectionPage', () {
    test('GET /mangas/home/sections/:id?page&limit, id encode', () async {
      stubGet(200, loadFixture('home_section_page.json'));

      final page = await service.fetchSectionPage('genre:Slice of Life',
          page: 2, limit: 40);

      final uri = capturedUri();
      expect(uri.path, '/mangas/home/sections/genre%3ASlice%20of%20Life');
      expect(uri.pathSegments.last, 'genre:Slice of Life');
      expect(uri.queryParameters, {'page': '2', 'limit': '40'});
      expect(page.id, 'year:2014');
      expect(page.kind, HomeSectionKind.year);
      expect(page.total, 5);
      expect(page.items, hasLength(2));
      expect(page.hasMore, isTrue);
    });

    test('page < 1 ramenee a 1, limit bornee', () async {
      stubGet(200, loadFixture('home_section_page.json'));
      await service.fetchSectionPage('latest', page: 0, limit: 500);
      expect(capturedUri().queryParameters, {'page': '1', 'limit': '40'});
    });

    test('404 → HomeSectionNotFoundException avec l\'id', () async {
      stubGet(404, '{"message":"Unknown section"}');
      await expectLater(
        service.fetchSectionPage('type:Novel'),
        throwsA(
          isA<HomeSectionNotFoundException>()
              .having((e) => e.sectionId, 'sectionId', 'type:Novel'),
        ),
      );
    });

    test('ne touche jamais au cache des sections', () async {
      stubGet(200, loadFixture('home_section_page.json'));
      await service.fetchSectionPage('latest');
      verifyNever(() => storage.writeSecureData(any(), any()));
    });
  });
}
