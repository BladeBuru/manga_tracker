import 'dart:async';

import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' show ClientException;
import 'package:mangatracker/core/network/failure_classifier.dart';
import 'package:mangatracker/core/network/network_compat.dart';
import 'package:mangatracker/features/auth/exceptions/invalid_credentials.exception.dart';
import 'package:mangatracker/features/auth/exceptions/invalid_token.exception.dart';
import 'package:mangatracker/features/auth/exceptions/session_expired.exception.dart';

void main() {
  group('classifyFailure', () {
    test('SocketException → network', () {
      expect(classifyFailure(const SocketException('no route')),
          FailureMode.network);
    });

    test('ClientException (web) → network', () {
      // Sur le web, package:http lève ClientException et JAMAIS
      // SocketException : sans ce cas, toute panne réseau web tombait
      // dans « other » et n'affichait pas le bandeau hors ligne.
      expect(classifyFailure(ClientException('XMLHttpRequest error')),
          FailureMode.network);
    });

    test('TimeoutException → network', () {
      expect(classifyFailure(TimeoutException('slow')), FailureMode.network);
    });

    test('SessionExpiredException → sessionExpired', () {
      expect(classifyFailure(SessionExpiredException('Both tokens expired')),
          FailureMode.sessionExpired);
    });

    test('InvalidCredentialsException → sessionRejected', () {
      expect(classifyFailure(InvalidCredentialsException('rejected')),
          FailureMode.sessionRejected);
    });

    test('InvalidTokenException → sessionRejected', () {
      expect(classifyFailure(InvalidTokenException('bad signature')),
          FailureMode.sessionRejected);
    });

    test('erreur serveur quelconque → other', () {
      expect(classifyFailure(Exception('HTTP 500')), FailureMode.other);
    });
  });

  group('frontière de sécurité', () {
    test('le cache est lisible hors ligne et sur session expirée', () {
      expect(allowsCachedRead(FailureMode.network), isTrue);
      expect(allowsCachedRead(FailureMode.sessionExpired), isTrue);
    });

    test('un rejet explicite du serveur interdit le cache', () {
      // Le serveur est joignable et a dit non : l'utilisateur peut se
      // reconnecter, il ne doit pas naviguer dans ses données en croyant
      // être authentifié.
      expect(allowsCachedRead(FailureMode.sessionRejected), isFalse);
    });

    test('le bandeau hors ligne ne s\'affiche pas sur une erreur serveur', () {
      expect(showsOfflineIndicator(FailureMode.network), isTrue);
      expect(showsOfflineIndicator(FailureMode.sessionExpired), isTrue);
      expect(showsOfflineIndicator(FailureMode.other), isFalse);
      expect(showsOfflineIndicator(FailureMode.sessionRejected), isFalse);
    });
  });

  group('toString des exceptions auth', () {
    test('expose le nom de la classe (dart2js minifie Object.toString)', () {
      // La détection historique faisait
      // `e.toString().contains('InvalidCredentialsException')` alors que la
      // classe n'avait pas de toString() — donc « Instance of '...' », minifié
      // en release web.
      expect(InvalidCredentialsException('x').toString(),
          contains('InvalidCredentialsException'));
      expect(SessionExpiredException('x').toString(),
          contains('SessionExpiredException'));
    });
  });
}
