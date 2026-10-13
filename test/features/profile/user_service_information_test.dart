import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:mangatracker/core/network/api_exception.dart';
import 'package:mangatracker/core/network/http_service.dart';
import 'package:mangatracker/core/services/offline_cache_service.dart';
import 'package:mangatracker/features/auth/services/auth.service.dart';
import 'package:mangatracker/features/profile/dto/user_information.dto.dart';
import 'package:mangatracker/features/profile/services/user.service.dart';
import 'package:mocktail/mocktail.dart';

class _Http extends Mock implements HttpService {}

class _Cache extends Mock implements OfflineCacheService {}

class _Auth extends Mock implements AuthService {}

/// `GET /user/information` : seul un 200 est lu et mis en cache. Un 429 ou un
/// 500 devenait un utilisateur vide mis en cache 7 jours (id `null`) — la
/// détection de « moi » cassait partout.
void main() {
  late _Http http_;
  late _Cache cache;
  late UserService service;

  setUpAll(() {
    dotenv.testLoad(fileInput: 'MT_API_URL=https://api.test');
    registerFallbackValue(Uri.parse('https://api.test'));
    registerFallbackValue(const UserInformationDto(email: '', username: ''));
  });

  setUp(() {
    http_ = _Http();
    cache = _Cache();
    service = UserService(
      authService: _Auth(),
      httpService: http_,
      cacheService: cache,
    );
    when(() => cache.cacheUserInformation(any())).thenAnswer((_) async {});
    when(() => cache.isCacheExpiredFor(any(), maxHours: any(named: 'maxHours')))
        .thenAnswer((_) async => true);
  });

  void stubGet(int status, String body) {
    when(() => http_.getWithAuthTokens(any(), headers: any(named: 'headers')))
        .thenAnswer((_) async => http.Response(body, status));
  }

  test('429 sans cache → exception, rien n\'est mis en cache', () async {
    when(() => cache.getCachedUserInformation()).thenAnswer((_) async => null);
    stubGet(429, '{"statusCode":429,"message":"Too Many Requests"}');

    await expectLater(
      service.getUserInformation(),
      throwsA(isA<ApiException>()),
    );
    verifyNever(() => cache.cacheUserInformation(any()));
  });

  test('500 avec un cache expiré → le cache est servi et conservé', () async {
    const cached = UserInformationDto(id: 7, email: 'a@b.c', username: 'lea');
    when(() => cache.getCachedUserInformation()).thenAnswer((_) async => cached);
    stubGet(500, '{"statusCode":500,"message":"Internal server error"}');

    final info = await service.getUserInformation();
    expect(info.id, 7);
    verifyNever(() => cache.cacheUserInformation(any()));
  });

  test('200 → lu et mis en cache', () async {
    when(() => cache.getCachedUserInformation()).thenAnswer((_) async => null);
    stubGet(200, '{"id":7,"email":"a@b.c","username":"lea"}');

    final info = await service.getUserInformation();
    expect(info.id, 7);
    expect(info.username, 'lea');
    verify(() => cache.cacheUserInformation(any())).called(1);
  });
}
