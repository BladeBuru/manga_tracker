/// Implémentation web — stubs purs Dart (pas de `dart:io`).
///
/// Sur web, le runtime ne lève jamais `SocketException` (c'est `ClientException`
/// du package `http` qui est levée pour les erreurs réseau). Ces stubs servent
/// uniquement à permettre la compilation des `catch (SocketException)`
/// présents dans le code partagé. En pratique, sur web ces catch ne matchent
/// jamais — c'est volontaire.
library;

/// Stub HttpStatus avec les constants HTTP standards (RFC 7231 + extensions).
class HttpStatus {
  HttpStatus._();

  static const int ok = 200;
  static const int created = 201;
  static const int accepted = 202;
  static const int noContent = 204;
  static const int badRequest = 400;
  static const int unauthorized = 401;
  static const int forbidden = 403;
  static const int notFound = 404;
  static const int conflict = 409;
  static const int tooManyRequests = 429;
  static const int unprocessableEntity = 422;
  static const int internalServerError = 500;
  static const int badGateway = 502;
  static const int serviceUnavailable = 503;
  static const int gatewayTimeout = 504;
}

/// Stub HttpHeaders avec les noms d'entêtes standards (en lowercase, conforme
/// au comportement de `dart:io` HttpHeaders).
class HttpHeaders {
  HttpHeaders._();

  static const String authorizationHeader = 'authorization';
  static const String contentTypeHeader = 'content-type';
  static const String acceptHeader = 'accept';
  static const String acceptLanguageHeader = 'accept-language';
  static const String userAgentHeader = 'user-agent';
}

/// Stub SocketException — sur web c'est `ClientException` du package `http`
/// qui est levée pour les erreurs réseau. Ce stub permet la compilation du
/// code partagé (`on SocketException catch`) sans changer la sémantique mobile.
class SocketException implements Exception {
  final String message;
  final dynamic osError;
  final InternetAddress? address;
  final int? port;

  const SocketException(
    this.message, {
    this.osError,
    this.address,
    this.port,
  });

  @override
  String toString() => 'SocketException: $message';
}

/// Stub minimal pour le constructeur SocketException qui prend une address.
class InternetAddress {
  final String address;
  const InternetAddress(this.address);
  @override
  String toString() => address;
}
