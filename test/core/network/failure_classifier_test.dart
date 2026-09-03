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
    test('aucun mode d\'échec n\'interdit la lecture du cache', () {
      // Décision produit 2026-08-31 : le prédicat `allowsCachedRead` a été
      // SUPPRIMÉ, pas passé à `true`, pour qu'aucun appelant ne puisse
      // rebrancher un refus de lecture par mégarde.
      //
      // La preuve de comportement (401 → cache réellement servi) vit dans
      // les tests de BLoC, qui exercent le vrai chemin.
      expect(FailureMode.values, hasLength(4));
    });

    test('un rejet serveur invite à se reconnecter, sans dire « hors ligne »',
        () {
      // L\'appareil EST joignable : afficher le bandeau hors ligne serait
      // faux. Ce cas a son propre signal, non bloquant.
      expect(requiresReauthPrompt(FailureMode.sessionRejected), isTrue);
      expect(showsOfflineIndicator(FailureMode.sessionRejected), isFalse);
    });

    test('les autres modes n\'invitent pas à se reconnecter', () {
      expect(requiresReauthPrompt(FailureMode.network), isFalse);
      expect(requiresReauthPrompt(FailureMode.sessionExpired), isFalse);
      expect(requiresReauthPrompt(FailureMode.other), isFalse);
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
