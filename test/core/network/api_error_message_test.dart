import 'dart:async';

import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' show ClientException, Response;
import 'package:mangatracker/core/network/api_error_message.dart';
import 'package:mangatracker/core/network/api_exception.dart';
import 'package:mangatracker/features/auth/exceptions/invalid_credentials.exception.dart';
import 'package:mangatracker/l10n/app_localizations.dart';

void main() {
  final l10n = lookupAppLocalizations(const Locale('fr'));

  ApiException fromBody(int status, String body) =>
      ApiException.fromResponse(Response(body, status));

  group('parseNestErrorBody', () {
    test('message en chaîne', () {
      final parsed = parseNestErrorBody(
        '{"statusCode":409,"message":"Demande déjà envoyée","error":"Conflict"}',
      );
      expect(parsed.message, 'Demande déjà envoyée');
      expect(parsed.error, 'Conflict');
      expect(parsed.fromList, isFalse);
    });

    test('message en tableau (class-validator) → première entrée', () {
      final parsed = parseNestErrorBody(
        '{"statusCode":400,"message":["content too short","x"],"error":"Bad Request"}',
      );
      expect(parsed.message, 'content too short');
      expect(parsed.fromList, isTrue);
    });

    test('corps vide, HTML ou illisible → rien', () {
      expect(parseNestErrorBody('').message, isNull);
      expect(parseNestErrorBody('<html>502</html>').message, isNull);
      expect(parseNestErrorBody('[1,2]').message, isNull);
    });
  });

  group('userFacingErrorMessage', () {
    test('409 avec message rédigé → message du serveur', () {
      final e = fromBody(
        409,
        '{"statusCode":409,"message":"Une demande est déjà en attente","error":"Conflict"}',
      );
      expect(userFacingErrorMessage(e, l10n), 'Une demande est déjà en attente');
    });

    test('403 au message générique → texte de l\'app', () {
      final e = fromBody(
        403,
        '{"statusCode":403,"message":"Forbidden resource","error":"Forbidden"}',
      );
      expect(userFacingErrorMessage(e, l10n), l10n.errorForbidden);
    });

    test('429 → toujours « Trop de tentatives »', () {
      final e = fromBody(
        429,
        '{"statusCode":429,"message":"ThrottlerException: Too Many Requests"}',
      );
      expect(userFacingErrorMessage(e, l10n), l10n.errorTooManyRequests);
    });

    test('5xx → service indisponible, jamais le corps', () {
      final e = fromBody(500, '{"statusCode":500,"message":"Internal server error"}');
      expect(userFacingErrorMessage(e, l10n), l10n.errorServerUnavailable);
    });

    test('400 de validation → texte de repli de l\'écran', () {
      final e = fromBody(400, '{"statusCode":400,"message":["friendIds must be an array"]}');
      expect(
        userFacingErrorMessage(e, l10n, fallback: l10n.shareFailed),
        l10n.shareFailed,
      );
    });

    test('404 sans message → introuvable', () {
      expect(
        userFacingErrorMessage(fromBody(404, ''), l10n),
        l10n.errorNotFound,
      );
    });

    test('réseau → vérifiez votre connexion ; session refusée → reconnexion',
        () {
      expect(
        userFacingErrorMessage(ClientException('x'), l10n),
        l10n.networkError,
      );
      expect(
        userFacingErrorMessage(TimeoutException('x'), l10n),
        l10n.networkError,
      );
      expect(
        userFacingErrorMessage(InvalidCredentialsException('x'), l10n),
        l10n.errorSessionExpired,
      );
    });

    test('erreur quelconque → repli, jamais toString()', () {
      final message = userFacingErrorMessage(
        Exception('sendRequest failed: 403 {"statusCode":403}'),
        l10n,
      );
      expect(message, l10n.errorGeneric);
      expect(message, isNot(contains('Exception')));
    });

    test('toString() de ApiException ne fuit pas le corps', () {
      final e = fromBody(409, '{"message":"secret"}');
      expect(e.toString(), 'ApiException(409)');
    });
  });

  test('isHttpSuccess accepte 200, 201, 204 et refuse le reste', () {
    expect(isHttpSuccess(200), isTrue);
    expect(isHttpSuccess(201), isTrue);
    expect(isHttpSuccess(204), isTrue);
    expect(isHttpSuccess(304), isFalse);
    expect(isHttpSuccess(403), isFalse);
  });
}
