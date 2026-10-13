import 'package:flutter/foundation.dart';

/// État de la session tel que le routeur le voit.
///
/// - [signedOut] : aucune session (jamais connecté sur cet appareil,
///   déconnexion explicite, ou jetons absents/expirés au démarrage). Seul cet
///   état renvoie vers `/login`.
/// - [authenticated] : jetons utilisables.
/// - [rejected] : le serveur a refusé la session pendant l'utilisation
///   (401/403, jetons effacés par `clearSessionTokens()`). ❌ Jamais de
///   redirection forcée : le cache reste lisible et `SessionRejectedBanner`
///   invite à se reconnecter (cf. CLAUDE.md, mode offline-first).
enum AuthStatus { signedOut, authenticated, rejected }

/// Session courante, initialisée AVANT `runApp` depuis les jetons stockés.
///
/// Singleton GetIt. Mise à jour par `AuthService` : connexion
/// ([markSignedIn]), rejet automatique ([markRejected]), déconnexion
/// explicite ([markSignedOut]).
///
/// [routerRefresh] ne notifie QUE la perte de session (passage à
/// [AuthStatus.signedOut]) : c'est le filet de sécurité du garde du routeur.
/// Une connexion, elle, est toujours suivie d'une navigation explicite
/// (`AuthNavigation.completeSignIn`) — rafraîchir le routeur à ce moment-là
/// quitterait `/login` avant la proposition d'activer la biométrie, et
/// laisserait une entrée d'historique en trop.
class AuthSession {
  AuthSession({AuthStatus initial = AuthStatus.signedOut})
      : _status = ValueNotifier<AuthStatus>(initial);

  final ValueNotifier<AuthStatus> _status;
  final _Signal _signedOut = _Signal();
  bool _startupCompleted = false;

  /// Statut courant, observable (notifie chaque changement).
  ValueListenable<AuthStatus> get status => _status;

  AuthStatus get current => _status.value;

  bool get isAuthenticated => current == AuthStatus.authenticated;

  /// `refreshListenable` du routeur — ne notifie que la perte de session.
  Listenable get routerRefresh => _signedOut;

  /// `StartupPage` a fini son travail (rafraîchissement, biométrie,
  /// « Quoi de neuf ? »). Avant, `/` doit rester affichée même connecté.
  bool get startupCompleted => _startupCompleted;

  /// Lit les jetons stockés : une session est utilisable si l'access token
  /// OU le refresh token n'est pas expiré (même règle que `StartupPage`).
  Future<void> restore({
    required Future<String?> Function(String key) read,
    required bool Function(String? token) isExpired,
  }) async {
    final access = await read('accessToken');
    final refresh = await read('refreshToken');
    final usable = !isExpired(access) || !isExpired(refresh);
    _status.value = usable ? AuthStatus.authenticated : AuthStatus.signedOut;
  }

  void markSignedIn() => _status.value = AuthStatus.authenticated;

  /// Rejet automatique : sans effet si personne n'était connecté.
  void markRejected() {
    if (current == AuthStatus.signedOut) return;
    _status.value = AuthStatus.rejected;
  }

  void markSignedOut() {
    final wasSignedOut = current == AuthStatus.signedOut;
    _status.value = AuthStatus.signedOut;
    if (!wasSignedOut) _signedOut.fire();
  }

  void markStartupCompleted() => _startupCompleted = true;
}

class _Signal extends ChangeNotifier {
  void fire() => notifyListeners();
}
