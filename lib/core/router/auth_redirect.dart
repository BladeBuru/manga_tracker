/// Garde d'authentification du routeur — logique **pure** (ni Flutter, ni
/// GetIt) : testée sans widget dans `test/core/router/auth_redirect_test.dart`.
///
/// Règles :
/// - aucune session ([AuthStatus.signedOut]) + page protégée →
///   `/login?from=<page demandée>` ;
/// - connecté ([AuthStatus.authenticated]) sur une page de connexion
///   (`/login`, `/register`, `/forgot-password`), ou sur `/` une fois le
///   démarrage terminé → `from` (validé) ou `/home` ;
/// - session rejetée ([AuthStatus.rejected]) : **aucune** redirection
///   (offline-first : le cache reste lisible, invitation non bloquante).
library;

import 'package:mangatracker/features/auth/services/auth_session.dart';

/// Accueil après connexion quand aucune destination n'est demandée.
const String homeLocation = '/home';

/// Pages accessibles sans session.
const Set<String> publicPaths = {
  '/',
  '/login',
  '/register',
  '/forgot-password',
  '/auth/verify',
  '/auth/reset-password',
};

/// Pages qui n'ont pas de sens une fois connecté.
const Set<String> signedOutOnlyPaths = {
  '/login',
  '/register',
  '/forgot-password',
};

/// Paramètre de requête qui porte la page à rouvrir après la connexion.
const String returnToParam = 'from';

/// Valide une destination de retour : **chemin interne uniquement**.
///
/// Refuse tout ce qui pourrait sortir de l'application (`https://…`,
/// `//hote`, `\\hote`, schémas) et les pages d'authentification elles-mêmes
/// (boucle). Retourne `null` si la valeur n'est pas utilisable.
String? safeReturnPath(String? raw) {
  if (raw == null) return null;
  final value = raw.trim();
  if (value.isEmpty || !value.startsWith('/')) return null;
  if (value.startsWith('//') || value.contains('\\')) return null;
  final uri = Uri.tryParse(value);
  if (uri == null || uri.hasScheme || uri.hasAuthority) return null;
  if (uri.path == '/' || signedOutOnlyPaths.contains(uri.path)) return null;
  return uri.toString();
}

/// `/login`, avec `from` quand la page demandée n'est pas l'accueil.
String loginLocationFor(Uri attempted) {
  final from = safeReturnPath(attempted.toString());
  if (from == null || from == homeLocation) return '/login';
  return Uri(path: '/login', queryParameters: {returnToParam: from}).toString();
}

/// Destination imposée par l'état de session, ou `null` pour laisser passer.
String? resolveAuthRedirect(
  Uri location, {
  required AuthStatus status,
  required bool startupCompleted,
}) {
  final path = location.path.isEmpty ? '/' : location.path;
  switch (status) {
    case AuthStatus.authenticated:
      final leaveAuthPage = signedOutOnlyPaths.contains(path) ||
          (path == '/' && startupCompleted);
      if (!leaveAuthPage) return null;
      return safeReturnPath(location.queryParameters[returnToParam]) ??
          homeLocation;
    case AuthStatus.signedOut:
      if (publicPaths.contains(path)) return null;
      return loginLocationFor(location);
    case AuthStatus.rejected:
      return null;
  }
}
