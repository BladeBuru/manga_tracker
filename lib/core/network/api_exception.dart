import 'dart:convert';

import 'package:http/http.dart' show Response;

/// Réponse HTTP non réussie de l'API, avec ce que le serveur en dit.
///
/// Remplace les `Exception('xxx failed: 403 {json}')` affichées telles quelles
/// à l'utilisateur (« Exception: …403 {"statusCode":403,…} »). Le texte à
/// montrer se calcule avec `userFacingErrorMessage` (`api_error_message.dart`),
/// jamais avec `toString()`.
///
/// Classée `FailureMode.other` par `classifyFailure` : un refus métier
/// (403 « pas amis », 409 « déjà demandé ») n'est ni une panne réseau ni un
/// rejet de session.
class ApiException implements Exception {
  final int statusCode;

  /// Champ `message` d'un corps d'erreur NestJS (`{statusCode, message,
  /// error}`) : chaîne, ou première entrée d'un tableau class-validator.
  final String? serverMessage;

  /// Champ `error` de NestJS (« Conflict », « Forbidden »…), utile pour
  /// distinguer un message générique d'un message rédigé.
  final String? serverError;

  /// `true` si [serverMessage] vient d'un tableau de validation
  /// (class-validator, en anglais technique) : jamais montré tel quel.
  final bool isValidationMessage;

  const ApiException(
    this.statusCode, {
    this.serverMessage,
    this.serverError,
    this.isValidationMessage = false,
  });

  /// Construit l'exception depuis une réponse ; le corps n'est jamais conservé
  /// en entier (il peut contenir des données à ne pas journaliser).
  factory ApiException.fromResponse(Response response) {
    final parsed = parseNestErrorBody(response.body);
    return ApiException(
      response.statusCode,
      serverMessage: parsed.message,
      serverError: parsed.error,
      isValidationMessage: parsed.fromList,
    );
  }

  bool get isTooManyRequests => statusCode == 429;
  bool get isServerError => statusCode >= 500;

  /// Volontairement sans le message serveur : un `toString()` qui finirait
  /// dans un journal ou à l'écran ne doit rien révéler de plus que le code.
  @override
  String toString() => 'ApiException($statusCode)';
}

/// Résultat de la lecture d'un corps d'erreur NestJS.
class NestErrorBody {
  final String? message;
  final String? error;

  /// `message` était un tableau (erreurs de validation).
  final bool fromList;

  const NestErrorBody({this.message, this.error, this.fromList = false});
}

/// Lit `{statusCode, message, error}` ; `message` peut être une chaîne ou un
/// tableau (validation class-validator). Tout corps illisible → vide.
NestErrorBody parseNestErrorBody(String body) {
  if (body.trim().isEmpty) return const NestErrorBody();
  try {
    final decoded = jsonDecode(body);
    if (decoded is! Map) return const NestErrorBody();
    final raw = decoded['message'];
    String? message;
    var fromList = false;
    if (raw is String) {
      message = raw.trim();
    } else if (raw is List && raw.isNotEmpty) {
      message = raw.first?.toString().trim();
      fromList = true;
    }
    final error = decoded['error'];
    return NestErrorBody(
      message: (message == null || message.isEmpty) ? null : message,
      error: error is String ? error : null,
      fromList: fromList,
    );
  } catch (_) {
    return const NestErrorBody();
  }
}

/// Vrai si [statusCode] est un succès (2xx). Plusieurs routes POST de l'API
/// renvoient 201 là où le client attendait 200 (`mark-seen`, `report`) :
/// toute vérification de succès passe par ici.
bool isHttpSuccess(int statusCode) => statusCode >= 200 && statusCode < 300;
