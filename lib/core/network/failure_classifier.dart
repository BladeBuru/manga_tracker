import 'dart:async';

import 'package:http/http.dart' show ClientException;
import 'package:mangatracker/core/network/network_compat.dart';
import 'package:mangatracker/features/auth/exceptions/invalid_credentials.exception.dart';
import 'package:mangatracker/features/auth/exceptions/invalid_token.exception.dart';
import 'package:mangatracker/features/auth/exceptions/session_expired.exception.dart';

/// Nature d'un échec de chargement, du point de vue « peut-on servir le cache ».
///
/// Remplace les deux heuristiques historiques, toutes deux cassées :
///  - `on SocketException` seul — ne matche jamais sur le web (le stub de
///    `network_compat_web.dart` n'est jamais levé, c'est `ClientException`)
///    et ne couvre pas les échecs d'authentification ;
///  - `e.toString().contains('InvalidCredentialsException')` — dépend du
///    `Object.toString()` par défaut, que dart2js minifie en release web.
enum FailureMode {
  /// Réseau injoignable : avion, tunnel, wifi de train captif, timeout.
  network,

  /// Plus de credentials utilisables, **sans verdict du serveur** (tokens
  /// expirés localement, ou refresh impossible faute de réseau).
  sessionExpired,

  /// Le serveur a **explicitement** rejeté la session (401/403). L'appareil
  /// est joignable : l'utilisateur doit se reconnecter.
  sessionRejected,

  /// Erreur serveur (5xx), parsing, ou toute autre défaillance.
  other,
}

/// Classe une exception remontée par la couche service.
FailureMode classifyFailure(Object error) {
  // Verdict explicite du serveur → login obligatoire.
  if (error is InvalidCredentialsException || error is InvalidTokenException) {
    return FailureMode.sessionRejected;
  }

  // Pas de credentials utilisables, mais aucun verdict serveur.
  if (error is SessionExpiredException) {
    return FailureMode.sessionExpired;
  }

  // Réseau injoignable — mobile (`dart:io`) et web (`package:http`).
  if (error is SocketException || error is TimeoutException) {
    return FailureMode.network;
  }
  if (error is ClientException) {
    return FailureMode.network;
  }

  return FailureMode.other;
}

/// Vrai si l'écran peut servir ses données en cache pour cet échec.
///
/// **Frontière de sécurité** : tout sauf un rejet explicite du serveur. Un
/// token expiré n'empêche pas de relire ce que l'utilisateur a déjà consulté
/// (cas « je regarde où j'en suis dans le train »), mais un compte révoqué ou
/// une session tuée côté serveur renvoie bien vers l'écran de connexion.
bool allowsCachedRead(FailureMode mode) => mode != FailureMode.sessionRejected;

/// Vrai si l'échec doit afficher l'indicateur « hors ligne ».
///
/// `isOffline` signifie, dans toute l'app : **« ce que tu vois vient du cache
/// local, faute d'avoir pu joindre le serveur »**. C'est la définition qui
/// rend le bandeau déterministe d'un écran à l'autre.
bool showsOfflineIndicator(FailureMode mode) =>
    mode == FailureMode.network || mode == FailureMode.sessionExpired;
