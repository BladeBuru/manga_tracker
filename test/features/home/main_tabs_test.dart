import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:mangatracker/features/home/views/main_tabs_pager.dart';

/// Coque des onglets : conteneur `PageView` (glissement au doigt, pas à la
/// souris), état conservé, retour Android vers l'onglet accueil.
void main() {
  late GoRouter router;
  late StatefulNavigationShell shell;
  var homeBuilds = 0;

  Future<void> pumpShell(WidgetTester tester, {String initial = '/home'}) async {
    homeBuilds = 0;
    router = GoRouter(
      initialLocation: initial,
      routes: [
        StatefulShellRoute(
          builder: (context, state, navigationShell) {
            shell = navigationShell;
            return MainTabsBackScope(
              currentIndex: navigationShell.currentIndex,
              onBackToHome: () => navigationShell.goBranch(0),
              child: Scaffold(body: navigationShell),
            );
          },
          navigatorContainerBuilder: (context, navigationShell, children) =>
              MainTabsPager(shell: navigationShell, children: children),
          branches: [
            for (final name in ['home', 'library', 'search'])
              StatefulShellBranch(routes: [
                GoRoute(
                  path: '/$name',
                  builder: (_, __) {
                    if (name == 'home') homeBuilds++;
                    return _Tab(name);
                  },
                ),
              ]),
          ],
        ),
      ],
    );
    addTearDown(router.dispose);
    await tester.pumpWidget(MaterialApp.router(routerConfig: router));
    await tester.pumpAndSettle();
  }

  String location() => router.routerDelegate.currentConfiguration.uri.path;

  testWidgets('changer d\'onglet change l\'URL et garde l\'onglet vivant',
      (tester) async {
    await pumpShell(tester);
    await tester.enterText(find.byType(TextField), 'en cours');
    shell.goBranch(1);
    await tester.pumpAndSettle();
    expect(location(), '/library');
    expect(find.text('library'), findsOneWidget);

    shell.goBranch(0);
    await tester.pumpAndSettle();
    expect(location(), '/home');
    expect(find.text('en cours'), findsOneWidget, reason: 'état conservé');
  });

  testWidgets('un lien direct ouvre le bon onglet', (tester) async {
    await pumpShell(tester, initial: '/search');
    expect(find.text('search'), findsOneWidget);
    expect(shell.currentIndex, 2);
  });

  testWidgets('glissement au doigt : onglet suivant', (tester) async {
    await pumpShell(tester);
    await tester.fling(find.text('home'), const Offset(-500, 0), 2000);
    await tester.pumpAndSettle();
    expect(location(), '/library');
  });

  testWidgets('glissement à la souris : aucun changement d\'onglet',
      (tester) async {
    await pumpShell(tester);
    final gesture = await tester.startGesture(
      tester.getCenter(find.text('home')),
      kind: PointerDeviceKind.mouse,
    );
    for (var i = 0; i < 10; i++) {
      await gesture.moveBy(const Offset(-60, 0));
      await tester.pump(const Duration(milliseconds: 16));
    }
    await gesture.up();
    await tester.pumpAndSettle();
    expect(location(), '/home');
  });

  testWidgets('retour Android hors accueil : onglet accueil, sans sortir',
      (tester) async {
    await pumpShell(tester);
    shell.goBranch(2);
    await tester.pumpAndSettle();

    final handled = await tester.binding.handlePopRoute();
    await tester.pumpAndSettle();
    expect(location(), '/home');
    expect(handled, isTrue);

    // Sur l'accueil, le retour n'est plus retenu (sortie de l'app).
    expect(
      ModalRoute.of(tester.element(find.byType(MainTabsPager)))!.popDisposition,
      isNot(RoutePopDisposition.doNotPop),
    );
    expect(homeBuilds, 1, reason: 'onglet accueil jamais reconstruit');
  });
}

class _Tab extends StatelessWidget {
  final String name;
  const _Tab(this.name);

  @override
  Widget build(BuildContext context) => Column(
        children: [
          Text(name),
          if (name == 'home') const SizedBox(width: 200, child: TextField()),
        ],
      );
}
