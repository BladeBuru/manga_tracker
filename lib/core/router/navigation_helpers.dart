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


/// Aides de navigation entre pages qui se renvoient l'une à l'autre.
///
/// Problème corrigé (lecture partagée) : la fiche du manga ouvre le groupe,
/// le groupe ouvre la fiche… Chaque aller-retour EMPILAIT deux pages
/// (`[groupe, manga, groupe, manga…]`) : il fallait ensuite appuyer de
/// nombreuses fois sur « retour », et chaque page de groupe empilée gardait
/// son propre rafraîchissement périodique.

/// Emplacements des pages empilées, de la plus ancienne à celle affichée.
List<String> pageStackLocations(RouteMatchList configuration) => [
  for (final match in configuration.matches) ..._locationsOf(match),
];

Iterable<String> _locationsOf(RouteMatchBase match) sync* {
  if (match is ShellRouteMatch) {
    for (final child in match.matches) {
      yield* _locationsOf(child);
    }
  } else {
    yield match.matchedLocation;
  }
}

/// **Pure** : vrai si la page juste en dessous de celle affichée est déjà
/// [location] — y revenir plutôt que l'empiler une seconde fois.
bool shouldPopInsteadOfPush(List<String> stack, String location) {
  if (stack.length < 2) return false;
  return _normalize(stack[stack.length - 2]) == _normalize(location);
}

/// Chemin sans requête ni barre finale : `/manga/12?x=1` ≡ `/manga/12/`.
String _normalize(String location) {
  final path = Uri.parse(location).path;
  return path.length > 1 && path.endsWith('/')
      ? path.substring(0, path.length - 1)
      : path;
}

/// Ouvre [location] — ou revient en arrière si c'est la page juste en
/// dessous (cf. [shouldPopInsteadOfPush]). Retour : le résultat de la page
/// ouverte, `null` si on est revenu en arrière.
Future<T?> pushOrPop<T extends Object?>(
  BuildContext context,
  String location, {
  Object? extra,
}) {
  final router = GoRouter.of(context);
  final stack = pageStackLocations(router.routerDelegate.currentConfiguration);
  if (shouldPopInsteadOfPush(stack, location) && router.canPop()) {
    router.pop();
    return Future<T?>.value();
  }
  return router.push<T>(location, extra: extra);
}
