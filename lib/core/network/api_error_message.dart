import 'package:mangatracker/core/network/api_exception.dart';
import 'package:mangatracker/core/network/failure_classifier.dart';
import 'package:mangatracker/l10n/app_localizations.dart';

/// Texte à montrer à l'utilisateur pour un échec, quelle que soit sa nature.
///
/// Remplace les `'$e'` / `e.toString()` qui affichaient
/// « Exception: sendRequest failed: 403 {"statusCode":403,…} ».
///
/// Ordre de décision :
///  1. réseau injoignable / session sans verdict → « vérifiez votre
///     connexion » ; session refusée par le serveur → « reconnectez-vous » ;
///  2. 429 → « Trop de tentatives… » (toujours le texte de l'app : le
///     message du serveur est technique) ; 5xx → service indisponible ;
///  3. message rédigé par le serveur (`{message: "..."}` en chaîne, pas une
///     liste de validation ni un intitulé HTTP générique) → affiché tel quel ;
///  4. 403 / 404 / 409 → texte de l'app propre au code ;
///  5. sinon [fallback] (texte de l'écran, ex. « Échec de l'envoi »), à
///     défaut un message générique.
String userFacingErrorMessage(
  Object? error,
  AppLocalizations l10n, {
  String? fallback,
}) {
  if (error == null) return fallback ?? l10n.errorGeneric;
  if (error is! ApiException) {
    final mode = classifyFailure(error);
    if (showsOfflineIndicator(mode)) return l10n.networkError;
    if (requiresReauthPrompt(mode)) return l10n.errorSessionExpired;
    return fallback ?? l10n.errorGeneric;
  }
  if (error.isTooManyRequests) return l10n.errorTooManyRequests;
  if (error.isServerError) return l10n.errorServerUnavailable;
  final written = writtenServerMessage(error);
  if (written != null) return written;
  switch (error.statusCode) {
    case 403:
      return l10n.errorForbidden;
    case 404:
      return l10n.errorNotFound;
    case 409:
      return l10n.errorConflict;
  }
  return fallback ?? l10n.errorGeneric;
}

/// Intitulés HTTP / Nest par défaut : ils ne disent rien de plus que le code.
const Set<String> _genericPhrases = {
  'bad request',
  'unauthorized',
  'forbidden',
  'forbidden resource',
  'not found',
  'conflict',
  'too many requests',
  'internal server error',
  'service unavailable',
  'throttlerexception: too many requests',
};

/// Message rédigé par le serveur, ou `null` s'il n'est pas montrable
/// (absent, liste de validation, intitulé générique, simple écho du champ
/// `error`). Exposé pour les tests.
String? writtenServerMessage(ApiException error) {
  final message = error.serverMessage?.trim();
  if (message == null || message.isEmpty) return null;
  if (error.isValidationMessage) return null;
  final lower = message.toLowerCase();
  if (_genericPhrases.contains(lower)) return null;
  if (error.serverError != null && lower == error.serverError!.toLowerCase()) {
    return null;
  }
  // Message technique (`Cannot GET /friends/sent`, nom d'exception…).
  if (lower.startsWith('cannot ') || lower.contains('exception')) return null;
  return message;
}
