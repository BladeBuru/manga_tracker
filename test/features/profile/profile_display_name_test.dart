import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart';
import 'package:mangatracker/core/network/http_service.dart';
import 'package:mangatracker/core/service_locator/service_locator.dart';
import 'package:mangatracker/core/services/offline_cache_service.dart';
import 'package:mangatracker/features/auth/services/auth.service.dart';
import 'package:mangatracker/features/profile/dto/user.dto.dart';
import 'package:mangatracker/features/profile/dto/user_information.dto.dart';
import 'package:mangatracker/features/profile/services/user.service.dart';
import 'package:mangatracker/features/profile/widgets/profile_header.dart';
import 'package:mocktail/mocktail.dart';

class MockHttpService extends Mock implements HttpService {}

class MockAuthService extends Mock implements AuthService {}

class MockOfflineCacheService extends Mock implements OfflineCacheService {}

/// Retour utilisateur 2026-09 : « le changement du nom d'utilisateur n'est
/// jamais appliqué ». Le nom à afficher était bien enregistré, mais l'app
/// montrait partout l'identifiant (non modifiable).
void main() {
  setUpAll(() {
    dotenv.testLoad(fileInput: 'MT_API_URL=https://api.test');
    registerFallbackValue(Uri());
    registerFallbackValue(
      const UserInformationDto(email: '', username: '', emailVerified: false),
    );
  });

  group('Nom affiché', () {
    test('la salutation utilise le nom à afficher, sinon l\'identifiant', () {
      expect(
        const UserDto(
          username: 'john',
          displayName: 'Jean',
          email: 'e',
        ).greetingName,
        'Jean',
      );
      expect(
        const UserDto(
          username: 'john',
          displayName: '  ',
          email: 'e',
        ).greetingName,
        'john',
      );
    });

    testWidgets('l\'en-tête du profil montre le nom et l\'identifiant', (
      tester,
    ) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: ProfileHeader(
              username: 'Jean le Lecteur',
              handle: 'john',
              email: 'john@example.com',
            ),
          ),
        ),
      );
      expect(find.text('Jean le Lecteur'), findsOneWidget);
      expect(find.text('@john'), findsOneWidget);
    });
  });

  group('UserService.updateProfile — corps envoyé', () {
    late MockHttpService http;
    late MockOfflineCacheService cache;
    Map<String, dynamic>? sentBody;

    setUp(() async {
      await getIt.reset();
      http = MockHttpService();
      cache = MockOfflineCacheService();
      sentBody = null;
      when(() => cache.cacheUserInformation(any())).thenAnswer((_) async {});
      when(
        () => http.patchWithAuthTokens(
          any(),
          headers: any(named: 'headers'),
          body: any(named: 'body'),
        ),
      ).thenAnswer((invocation) async {
        sentBody =
            jsonDecode(invocation.namedArguments[#body] as String)
                as Map<String, dynamic>;
        return Response(
          jsonEncode({
            'email': 'john@example.com',
            'username': 'john',
            'displayName': sentBody!['displayName'],
          }),
          200,
        );
      });
      getIt.registerSingleton<AuthService>(MockAuthService());
      getIt.registerSingleton<HttpService>(http);
      getIt.registerSingleton<OfflineCacheService>(cache);
    });

    tearDown(() => getIt.reset());

    test('le nouveau nom est envoyé, rogné', () async {
      final updated = await UserService().updateProfile(
        displayName: '  Jean  ',
      );
      expect(sentBody!['displayName'], 'Jean');
      expect(updated.effectiveDisplayName, 'Jean');
    });

    test('un nom vidé est envoyé à null (effacement), plus ignoré', () async {
      final updated = await UserService().updateProfile(displayName: '');
      expect(sentBody!.containsKey('displayName'), isTrue);
      expect(sentBody!['displayName'], isNull);
      expect(updated.effectiveDisplayName, 'john');
    });

    test('sans nouvel avatar, la photo n\'est pas renvoyée', () async {
      await UserService().updateProfile(displayName: 'Jean');
      expect(sentBody!.containsKey('avatarUrl'), isFalse);
    });
  });
}
