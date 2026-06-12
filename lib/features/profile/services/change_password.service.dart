import 'dart:convert';

import 'package:mangatracker/core/network/http_service.dart';
import 'package:mangatracker/core/network/uri_builder.dart';
import 'package:mangatracker/core/service_locator/service_locator.dart';

/// Tokens JWT retournés par `PUT /user/password` : l'API révoque TOUTES les
/// sessions puis ré-émet un couple access/refresh (auto-login de l'appareil
/// courant — les autres appareils sont déconnectés).
class ChangePasswordTokens {
  final String accessToken;
  final String refreshToken;

  const ChangePasswordTokens({
    required this.accessToken,
    required this.refreshToken,
  });

  factory ChangePasswordTokens.fromJson(Map<String, dynamic> json) {
    return ChangePasswordTokens(
      accessToken: json['accessToken'] as String,
      refreshToken: json['refreshToken'] as String? ?? '',
    );
  }
}

/// Le mot de passe actuel saisi est incorrect (400 `CURRENT_PASSWORD_INVALID`).
class WrongCurrentPasswordException implements Exception {
  const WrongCurrentPasswordException();
}

/// Compte social (Google) sans mot de passe local — rien à changer
/// (400 `SOCIAL_ACCOUNT_NO_PASSWORD`).
class SocialAccountPasswordException implements Exception {
  const SocialAccountPasswordException();
}

/// Service client du changement de mot de passe (utilisateur connecté).
///
/// Distinct du legacy `UserService.changePassword(password)` (encore appelé
/// par l'ancien dialog du profil) : l'API exige désormais le mot de passe
/// ACTUEL et retourne un nouveau couple JWT. Le legacy sera supprimé quand
/// l'entrée de menu du profil pointera vers `/change-password`.
class ChangePasswordService {
  static const _httpOk = 200;
  static const _httpBadRequest = 400;

  HttpService get _httpService => getIt<HttpService>();

  Future<ChangePasswordService> init() async => this;

  /// Change le mot de passe et retourne les nouveaux tokens (auto-login).
  ///
  /// Lance :
  ///  - [WrongCurrentPasswordException] si le mot de passe actuel est faux ;
  ///  - [SocialAccountPasswordException] pour un compte Google sans
  ///    mot de passe local ;
  ///  - [Exception] générique pour tout autre échec (réseau, 5xx…).
  ///
  /// Note : un mauvais mot de passe actuel renvoie 400 (pas 401) côté API,
  /// précisément pour ne pas déclencher le cycle refresh/logout du
  /// `HttpService` sur une simple faute de frappe.
  Future<ChangePasswordTokens> changePassword({
    required String currentPassword,
    required String newPassword,
  }) async {
    final response = await _httpService.putWithAuthTokens(
      buildApiUri('/user/password'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({
        'currentPassword': currentPassword,
        'newPassword': newPassword,
      }),
    );

    if (response.statusCode == _httpOk) {
      return ChangePasswordTokens.fromJson(
        jsonDecode(response.body) as Map<String, dynamic>,
      );
    }
    if (response.statusCode == _httpBadRequest) {
      final code = _extractMessage(response.body);
      if (code == 'CURRENT_PASSWORD_INVALID') {
        throw const WrongCurrentPasswordException();
      }
      if (code == 'SOCIAL_ACCOUNT_NO_PASSWORD') {
        throw const SocialAccountPasswordException();
      }
      throw Exception('changePassword: HTTP 400 ($code)');
    }
    throw Exception('changePassword: HTTP ${response.statusCode}');
  }

  /// Extrait le champ `message` d'un corps d'erreur NestJS (string ou
  /// première entrée d'un tableau class-validator).
  String? _extractMessage(String body) {
    if (body.isEmpty) return null;
    try {
      final decoded = jsonDecode(body);
      if (decoded is Map<String, dynamic>) {
        final message = decoded['message'];
        if (message is String) return message;
        if (message is List && message.isNotEmpty) {
          return message.first.toString();
        }
      }
    } catch (_) {
      return null;
    }
    return null;
  }
}
