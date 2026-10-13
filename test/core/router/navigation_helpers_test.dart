import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:mangatracker/core/router/navigation_helpers.dart';
import 'package:mangatracker/core/router/route_visibility_listener.dart';

/// Page de test : un bouton qui ouvre [target] via `pushOrPop`.
class _Page extends StatelessWidget {
  final String name;
  final String target;
  const _Page(this.name, this.target);

  @override
  Widget build(BuildContext context) => Scaffold(
    body: Column(
      children: [
        Text('page $name'),
        TextButton(
          onPressed: () => pushOrPop<void>(context, target),
          child: Text('open $target'),
        ),
      ],
    ),
  );
}

GoRouter _router() => GoRouter(
  initialLocation: '/reading-groups',
  routes: [
    GoRoute(
      path: '/reading-groups',
      builder: (_, __) => const _Page('list', '/reading-groups/5'),
    ),
    GoRoute(
      path: '/reading-groups/:id',
      builder: (_, __) => const _Page('group', '/manga/151'),
    ),
    GoRoute(
      path: '/manga/:muId',
      builder: (_, __) => const _Page('manga', '/reading-groups/5'),
    ),
  ],
);

void main() {
  group('shouldPopInsteadOfPush (pur)', () {
    test('la page du dessous est la cible → revenir', () {
      expect(
        shouldPopInsteadOfPush(
          ['/reading-groups', '/reading-groups/5', '/manga/151'],
          '/reading-groups/5',
        ),
        isTrue,
      );
    });

    test('requête et barre finale ignorées', () {
      expect(
        shouldPopInsteadOfPush(['/manga/151', '/reading-groups/5'],
            '/manga/151/?from=group'),
        isTrue,
      );
    });

    test('autre groupe, autre manga ou pile d\'une page → empiler', () {
      expect(
        shouldPopInsteadOfPush(
          ['/reading-groups/4', '/manga/151'],
          '/reading-groups/5',
        ),
        isFalse,
      );
      expect(shouldPopInsteadOfPush(['/manga/151'], '/manga/151'), isFalse);
      expect(shouldPopInsteadOfPush(const [], '/manga/151'), isFalse);
    });
  });

  testWidgets('allers-retours groupe ⇄ manga : la pile ne grandit plus', (
    tester,
  ) async {
    final router = _router();
    addTearDown(router.dispose);
    await tester.pumpWidget(MaterialApp.router(routerConfig: router));
    await tester.pumpAndSettle();

    await tester.tap(find.text('open /reading-groups/5'));
    await tester.pumpAndSettle();
    for (var i = 0; i < 3; i++) {
      await tester.tap(find.text('open /manga/151'));
      await tester.pumpAndSettle();
      expect(find.text('page manga'), findsOneWidget);
      // Depuis la fiche : le groupe est juste en dessous → on y revient.
      await tester.tap(find.text('open /reading-groups/5'));
      await tester.pumpAndSettle();
      expect(find.text('page group'), findsOneWidget);
    }

    expect(
      pageStackLocations(router.routerDelegate.currentConfiguration),
      ['/reading-groups', '/reading-groups/5'],
      reason: 'avant : 2 pages de plus à chaque aller-retour',
    );
  });

  testWidgets('cible différente de la page du dessous → empilée', (
    tester,
  ) async {
    final router = GoRouter(
      initialLocation: '/manga/151',
      routes: [
        GoRoute(
          path: '/manga/:muId',
          builder: (_, __) => const _Page('manga', '/reading-groups/5'),
        ),
        GoRoute(
          path: '/reading-groups/:id',
          builder: (_, __) => const _Page('group', '/reading-groups/6'),
        ),
      ],
    );
    addTearDown(router.dispose);
    await tester.pumpWidget(MaterialApp.router(routerConfig: router));
    await tester.pumpAndSettle();

    await tester.tap(find.text('open /reading-groups/5'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('open /reading-groups/6'));
    await tester.pumpAndSettle();

    expect(
      pageStackLocations(router.routerDelegate.currentConfiguration),
      ['/manga/151', '/reading-groups/5', '/reading-groups/6'],
    );
  });

  testWidgets('RouteVisibilityListener : masquée puis revenue au premier plan',
      (tester) async {
    final events = <String>[];
    final router = GoRouter(
      initialLocation: '/a',
      routes: [
        GoRoute(
          path: '/a',
          builder: (_, __) => RouteVisibilityListener(
            onVisible: () => events.add('visible'),
            onHidden: () => events.add('hidden'),
            child: const Scaffold(body: Text('a')),
          ),
        ),
        GoRoute(
          path: '/b',
          builder: (_, __) => const Scaffold(body: Text('b')),
        ),
      ],
    );
    addTearDown(router.dispose);
    await tester.pumpWidget(MaterialApp.router(routerConfig: router));
    await tester.pumpAndSettle();
    expect(events, isEmpty, reason: 'rien au premier affichage');

    router.push('/b');
    await tester.pumpAndSettle();
    expect(events, ['hidden']);

    router.pop();
    await tester.pumpAndSettle();
    expect(events, ['hidden', 'visible']);
  });
}
