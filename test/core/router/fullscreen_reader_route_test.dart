import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:mangatracker/core/router/app_router.dart';

/// Les lecteurs (en ligne, hors ligne) sont plein écran : aucune bande n'est
/// réservée sous eux aux barres du système. Toutes les autres pages gardent
/// cette protection (boutons du bas au-dessus de la barre à boutons).
void main() {
  test('les deux lecteurs sont plein écran', () {
    final router = buildAppRouter();
    addTearDown(router.dispose);
    final names = <String>{};
    void collect(List<RouteBase> routes) {
      for (final r in routes) {
        if (r is GoRoute && r.name != null) names.add(r.name!);
        collect(r.routes);
      }
    }

    collect(router.configuration.routes);
    // Les noms protégés existent bien dans le routeur : un renommage ne doit
    // pas désactiver le plein écran en silence.
    expect(names, containsAll(fullscreenReaderRouteNames));
  });

  test('une autre page garde la bande de protection', () {
    GoRoute route(String name) => GoRoute(
      path: '/$name',
      name: name,
      builder: (_, __) => const SizedBox(),
    );
    expect(isFullscreenReaderRoute(route('manga-read')), isTrue);
    expect(isFullscreenReaderRoute(route('manga-read-offline')), isTrue);
    expect(isFullscreenReaderRoute(route('friends')), isFalse);
    expect(isFullscreenReaderRoute(null), isFalse);
  });
}
