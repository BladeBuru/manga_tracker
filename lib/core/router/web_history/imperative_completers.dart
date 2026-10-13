import 'package:flutter/widgets.dart';
import 'package:go_router/go_router.dart';

/// Origine d'une pile restaurée depuis l'état de l'historique.
enum RestoreKind {
  /// Retour / avance du navigateur (`popstate`).
  browser,

  /// Rafraîchissement du routeur (perte de session) : la pile est relue
  /// depuis l'état courant puis redirigée.
  refresh,
}

/// Garde vivants les `await context.push(...)` quand go_router reconstruit
/// la pile depuis l'historique.
///
/// go_router recrée alors chaque page empilée avec un `Completer` neuf
/// (`RouteMatchListCodec`, flutter/flutter#128122) : l'ancien n'est jamais
/// terminé et le code qui attendait le retour (« rafraîchir au retour »)
/// restait suspendu.
/// - page toujours là (même clé) : son nouveau `Completer` est branché sur
///   l'ancien — le résultat du `pop` arrive bien à l'appelant ;
/// - page retirée par le **navigateur** ([RestoreKind.browser]) : l'attente
///   se termine avec `null`, comme un retour sans résultat. Pas sur un
///   rafraîchissement (déconnexion) : rien ne doit repartir derrière.
void reconcileImperativeCompleters(
  RouteMatchList previous,
  RouteMatchList next, {
  required RestoreKind kind,
}) {
  final before = _imperative(previous);
  final after = _imperative(next);
  before.forEach((key, old) {
    if (old.completer.isCompleted) return;
    final replacement = after[key];
    if (replacement == null) {
      if (kind == RestoreKind.browser) old.completer.complete();
      return;
    }
    if (identical(replacement.completer, old.completer)) return;
    replacement.completer.future.then((value) {
      if (!old.completer.isCompleted) old.completer.complete(value);
    });
  });
}

Map<ValueKey<String>, ImperativeRouteMatch> _imperative(RouteMatchList list) {
  final found = <ValueKey<String>, ImperativeRouteMatch>{};
  void visit(List<RouteMatchBase> matches) {
    for (final match in matches) {
      if (match is ImperativeRouteMatch) found[match.pageKey] = match;
      if (match is ShellRouteMatch) visit(match.matches);
    }
  }

  visit(list.matches);
  return found;
}
