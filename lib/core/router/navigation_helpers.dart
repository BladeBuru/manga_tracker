import 'package:flutter/widgets.dart';
import 'package:go_router/go_router.dart';

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
