/// Implémentation mobile (Android/iOS/Desktop) — re-exporte `dart:io`.
///
/// Sur mobile, on garde le comportement natif (SocketException levée par
/// le runtime quand pas de réseau, HttpStatus/HttpHeaders constants standards).
library;

import 'dart:io' as io;

/// Re-export de `dart:io` HttpStatus pour les codes de retour HTTP.
class HttpStatus {
  HttpStatus._();

  static const int ok = io.HttpStatus.ok; // 200
  static const int created = io.HttpStatus.created; // 201
  static const int accepted = io.HttpStatus.accepted; // 202
  static const int noContent = io.HttpStatus.noContent; // 204
  static const int badRequest = io.HttpStatus.badRequest; // 400
  static const int unauthorized = io.HttpStatus.unauthorized; // 401
  static const int forbidden = io.HttpStatus.forbidden; // 403
  static const int notFound = io.HttpStatus.notFound; // 404
  static const int conflict = io.HttpStatus.conflict; // 409
  static const int tooManyRequests = io.HttpStatus.tooManyRequests; // 429
  static const int unprocessableEntity = io.HttpStatus.unprocessableEntity; // 422
  static const int internalServerError = io.HttpStatus.internalServerError; // 500
  static const int badGateway = io.HttpStatus.badGateway; // 502
  static const int serviceUnavailable = io.HttpStatus.serviceUnavailable; // 503
  static const int gatewayTimeout = io.HttpStatus.gatewayTimeout; // 504
}

/// Re-export de `dart:io` HttpHeaders pour les noms d'entêtes standards.
class HttpHeaders {
  HttpHeaders._();

  static const String authorizationHeader = io.HttpHeaders.authorizationHeader;
  static const String contentTypeHeader = io.HttpHeaders.contentTypeHeader;
  static const String acceptHeader = io.HttpHeaders.acceptHeader;
  static const String acceptLanguageHeader = io.HttpHeaders.acceptLanguageHeader;
  static const String userAgentHeader = io.HttpHeaders.userAgentHeader;
}

/// Alias type vers `dart:io` SocketException pour la détection offline.
///
/// `catch (e) on SocketException` continue à fonctionner exactement comme avant
/// puisque c'est le même type au runtime.
typedef SocketException = io.SocketException;
