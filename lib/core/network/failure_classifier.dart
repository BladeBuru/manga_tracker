import 'dart:async';

import 'package:http/http.dart' show ClientException;
import 'package:mangatracker/core/network/network_compat.dart';
import 'package:mangatracker/features/auth/exceptions/invalid_credentials.exception.dart';
import 'package:mangatracker/features/auth/exceptions/invalid_token.exception.dart';
import 'package:mangatracker/features/auth/exceptions/session_expired.exception.dart';

/// Nature d'un échec de chargement, du point de vue « que montre-t-on ».
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
  /// est joignable : l'utilisateur peut — et devrait — se reconnecter.
  sessionRejected,

  /// Erreur serveur (5xx), parsing, ou toute autre défaillance.
  other,
}

/// Classe une exception remontée par la couche service.
FailureMode classifyFailure(Object error) {
  // Verdict explicite du serveur.
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

/// Vrai si l'échec doit afficher l'indicateur « hors ligne ».
///
/// `isOffline` signifie, dans toute l'app : **« ce que tu vois vient du cache
/// local, faute d'avoir pu joindre le serveur »**. C'est la définition qui
/// rend le bandeau déterministe d'un écran à l'autre.
///
/// Volontairement faux pour [FailureMode.sessionRejected] : l'appareil EST
/// joignable, dire « hors ligne » serait un mensonge. Ce cas a son propre
/// signal, [requiresReauthPrompt].
bool showsOfflineIndicator(FailureMode mode) =>
    mode == FailureMode.network || mode == FailureMode.sessionExpired;

/// Vrai si l'écran doit inviter l'utilisateur à se reconnecter.
///
/// **Invitation, pas redirection.** Le contenu en cache reste affiché et
/// consultable derrière l'invite ; c'est le sens même de la frontière
/// ci-dessous. Ne jamais rebrancher un `Navigator.push('/login')` sur ce
/// drapeau : ce serait re-masquer du contenu que l'utilisateur a déjà vu.
bool requiresReauthPrompt(FailureMode mode) =>
    mode == FailureMode.sessionRejected;

// ─────────────────────────────────────────────────────────────────────────
// 🔒 FRONTIÈRE DE SÉCURITÉ — lecture assouplie, écriture inchangée
// ─────────────────────────────────────────────────────────────────────────
//
// **Décision produit (2026-08-31)** : le cache est servi dans TOUS les modes
// d'échec, `sessionRejected` (401/403) compris. Il n'existe donc plus de
// prédicat `allowsCachedRead()` — il a été supprimé, et non passé à `true`,
// pour qu'aucun appelant ne puisse rebrancher un refus de lecture par
// mégarde.
//
// Raisonnement : le cache local ne contient QUE ce que cet utilisateur avait
// déjà obtenu en étant authentifié. Le lui réafficher ne révèle rien de
// nouveau. Un écran vide ou une redirection forcée ne protège aucune donnée,
// elle masque juste à l'utilisateur ce qu'il a déjà légitimement vu.
//
// Ce qui reste refusé sans session valide :
//  - toute **ÉCRITURE** (marquer un chapitre, modifier la bibliothèque,
//    noter…) : elle exige un token valide et part sinon dans la file
//    d'attente hors ligne. Jamais appliquée localement comme un succès.
//  - toute donnée **NON encore mise en cache** : on ne peut pas la chercher
//    sans session, l'écran affiche un état vide propre.
//
// CONTREPARTIE INDISPENSABLE, sans laquelle cet assouplissement ne tient pas :
// **la déconnexion purge le cache local** (`OfflineCacheService
// .purgeUserScopedCache()`, appelée par `AuthService.logout()`), et une
// connexion avec un compte différent purge aussi (détection par
// `cache_owner_id`). Sans ça, sur un appareil partagé, le cache de
// l'utilisateur précédent resterait consultable par le suivant — ce serait,
// cette fois, une vraie fuite.
//
// ⚠️ Corollaire : l'invalidation AUTOMATIQUE de session (401 intercepté par
// `HttpService`, refresh rejeté au boot) ne doit PAS appeler `logout()`, mais
// `AuthService.clearSessionTokens()`, qui efface les tokens en CONSERVANT le
// cache. Purger là annulerait toute la décision ci-dessus.
