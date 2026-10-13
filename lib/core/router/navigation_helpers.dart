import 'package:flutter/widgets.dart';
import 'package:go_router/go_router.dart';
import 'package:mangatracker/core/router/auth_redirect.dart';
import 'package:mangatracker/core/service_locator/service_locator.dart';
import 'package:mangatracker/features/auth/services/auth_session.dart';

/// Retour en arrière sûr : `pop` s'il y a une page en dessous, sinon
/// [fallback].
///
/// Une page ouverte par lien direct, F5 ou bouton « avance » du navigateur
/// est seule dans la pile : `context.pop()` y levait « There is nothing to
/// pop » (ou vidait la pile → écran blanc).
void popOrGo(BuildContext context, {String fallback = homeLocation}) {
  final router = GoRouter.of(context);
  if (router.canPop()) {
    router.pop();
  } else {
    router.go(fallback);
  }
}

/// `go` qui **remplace** l'entrée courante de l'historique du navigateur
/// (transitions d'authentification : démarrage → accueil, connexion →
/// destination, déconnexion → connexion). Sans effet visible hors web.
void goReplacing(BuildContext context, String location) {
  final router = GoRouter.of(context);
  Router.neglect(context, () => router.go(location));
}

/// Emplacement courant (page empilée comprise), pour revenir après la
/// connexion.
Uri currentLocation(BuildContext context) {
  final config = GoRouter.of(context).routerDelegate.currentConfiguration;
  if (config.isEmpty) return Uri(path: '/');
  final last = config.last;
  if (last is ImperativeRouteMatch) return last.matches.uri;
  return config.uri;
}

/// Ouvre la connexion (invitation à se reconnecter), en revenant ensuite à
/// la page courante. `go` et non `push` : on n'empile jamais `/login` sur
/// l'application.
///
/// La demande vient d'un refus du serveur (`SessionRejectedBanner`…) : la
/// session est marquée rejetée, sinon le garde renverrait aussitôt une
/// session encore « connectée » hors de `/login`.
void goToLogin(BuildContext context) {
  if (getIt.isRegistered<AuthSession>()) getIt<AuthSession>().markRejected();
  context.go(loginLocationFor(currentLocation(context)));
}
