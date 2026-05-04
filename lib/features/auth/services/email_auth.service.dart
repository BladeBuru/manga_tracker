import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:mangatracker/core/network/http_service.dart';
import 'package:mangatracker/core/network/uri_builder.dart';
import 'package:mangatracker/core/service_locator/service_locator.dart';

/// Réponse contenant les tokens JWT après vérification email ou reset
/// password (auto-login).
class EmailAuthTokens {
  final String accessToken;
  final String refreshToken;

  const EmailAuthTokens({
    required this.accessToken,
    required this.refreshToken,
  });

  factory EmailAuthTokens.fromJson(Map<String, dynamic> json) {
    return EmailAuthTokens(
      accessToken: json['accessToken'] as String,
      refreshToken: json['refreshToken'] as String? ?? '',
    );
  }
}

/// Erreur retournée par l'API pour un token invalide ou expiré.
class InvalidEmailTokenException implements Exception {
  final String message;
  const InvalidEmailTokenException([this.message = 'Token invalide ou expiré']);
  @override
  String toString() => message;
}

/// Service client pour les flows email-driven : vérification d'email
/// et reset password.
///
/// Pas d'`import 'dart:io'` (compatible Web). Tous les codes HTTP sont en
/// dur (le widget affiche un message générique en cas d'échec).
class EmailAuthService {
  static const _httpOk = 200;
  static const _httpBadRequest = 400;
  static const _httpUnauthorized = 401;
  static const _httpForbidden = 403;
  static const _httpTooManyRequests = 429;

  static const _jsonHeaders = {'Content-Type': 'application/json'};

  HttpService get _httpService => getIt<HttpService>();

  Future<EmailAuthService> init() async => this;

  /// Demande l'envoi d'un mail de vérification (utilisateur connecté).
  /// Pas d'erreur en cas d'email déjà vérifié — l'API ignore silencieusement.
  ///
  /// Throttle côté serveur : 3 req/min. En cas de 429, retourne `false`.
  Future<bool> resendVerificationEmail() async {
    final url = buildApiUri('/auth/email/send-verification');
    try {
      final response = await _httpService.postWithAuthTokens(url);
      if (response.statusCode == _httpOk) return true;
      if (response.statusCode == _httpTooManyRequests) {
        debugPrint('⚠️ EmailAuthService.resendVerification: rate limited');
        return false;
      }
      return false;
    } catch (e) {
      debugPrint('⚠️ EmailAuthService.resendVerification: $e');
      return false;
    }
  }

  /// Vérifie un token reçu dans le mail de vérification et retourne les
  /// JWT auto-login.
  ///
  /// Lance [InvalidEmailTokenException] si le token est invalide ou expiré.
  Future<EmailAuthTokens> verifyEmail(String token) async {
    final url = buildApiUri('/auth/email/verify');
    // Endpoint public — l'utilisateur n'est pas encore connecté.
    final response = await http.post(
      url,
      headers: _jsonHeaders,
      body: jsonEncode({'token': token}),
    );

    if (response.statusCode == _httpOk) {
      return EmailAuthTokens.fromJson(
        jsonDecode(response.body) as Map<String, dynamic>,
      );
    }
    if (response.statusCode == _httpBadRequest) {
      throw const InvalidEmailTokenException();
    }
    throw Exception('verifyEmail: HTTP ${response.statusCode}');
  }

  /// Demande l'envoi d'un mail de reset password.
  ///
  /// **Anti-énumération** : retourne TOUJOURS `true` même si l'email
  /// n'existe pas. Le client ne doit JAMAIS révéler à l'utilisateur si
  /// l'email est inscrit ou non.
  Future<bool> requestPasswordReset(String email) async {
    final url = buildApiUri('/auth/email/password/reset/request');
    try {
      final response = await http.post(
        url,
        headers: _jsonHeaders,
        body: jsonEncode({'email': email}),
      );
      // 200 = succès (ou email inexistant — indistinguable côté client).
      return response.statusCode == _httpOk;
    } catch (e) {
      debugPrint('⚠️ EmailAuthService.requestPasswordReset: $e');
      return false;
    }
  }

  /// Confirme un reset password avec le token reçu par email + le nouveau
  /// mot de passe. Retourne les JWT auto-login.
  ///
  /// Lance [InvalidEmailTokenException] si le token est invalide ou expiré.
  Future<EmailAuthTokens> confirmPasswordReset({
    required String token,
    required String newPassword,
  }) async {
    final url = buildApiUri('/auth/email/password/reset/confirm');
    final response = await http.post(
      url,
      headers: _jsonHeaders,
      body: jsonEncode({'token': token, 'newPassword': newPassword}),
    );

    if (response.statusCode == _httpOk) {
      return EmailAuthTokens.fromJson(
        jsonDecode(response.body) as Map<String, dynamic>,
      );
    }
    if (response.statusCode == _httpBadRequest) {
      throw const InvalidEmailTokenException();
    }
    if (response.statusCode == _httpUnauthorized ||
        response.statusCode == _httpForbidden) {
      throw const InvalidEmailTokenException(
        'Lien invalide ou expiré. Refaites une demande.',
      );
    }
    throw Exception('confirmPasswordReset: HTTP ${response.statusCode}');
  }
}
