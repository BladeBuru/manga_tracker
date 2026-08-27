import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:mangatracker/features/recommendations/widgets/recommendations_segmented_toggle.dart';

/// Régression : la bascule « Tout / Par genre » utilisait `context.go`.
/// Les deux routes recos étant déclarées à la racine du routeur, `go`
/// reconstruit la pile depuis zéro — plus rien à dépiler, retour arrière
/// impossible, l'utilisateur devait fermer l'application.
void main() {
  Widget harness() {
    final router = GoRouter(
      initialLocation: '/home',
      routes: [
        GoRoute(
          path: '/home',
          builder: (context, state) => Scaffold(
            body: Center(
              child: ElevatedButton(
                onPressed: () => context.push('/recommendations'),
                child: const Text('Voir tout'),
              ),
            ),
          ),
        ),
        GoRoute(
          path: '/recommendations',
          builder: (context, state) => const Scaffold(
            body: RecommendationsSegmentedToggle(
              current: RecommendationsMode.all,
            ),
          ),
        ),
        GoRoute(
          path: '/recommendations/by-genre',
          builder: (context, state) => const Scaffold(
            body: RecommendationsSegmentedToggle(
              current: RecommendationsMode.byGenre,
            ),
          ),
        ),
      ],
    );
    return MaterialApp.router(routerConfig: router);
  }

  /// `canPop` du Navigator racine : true tant qu'un écran reste dessous.
  bool canPop(WidgetTester tester) {
    final context = tester.element(find.byType(Scaffold).last);
    return Navigator.of(context).canPop();
  }

  testWidgets('le retour arrière reste possible après une bascule de mode',
      (tester) async {
    await tester.pumpWidget(harness());
    await tester.pumpAndSettle();

    await tester.tap(find.text('Voir tout'));
    await tester.pumpAndSettle();
    expect(canPop(tester), isTrue,
        reason: 'depuis l\'accueil, la page recos doit être dépilable');

    await tester.tap(find.text('Par genre'));
    await tester.pumpAndSettle();
    expect(canPop(tester), isTrue,
        reason:
            'après bascule vers « Par genre », l\'accueil doit rester dessous');

    await tester.tap(find.text('Tout'));
    await tester.pumpAndSettle();
    expect(canPop(tester), isTrue,
        reason: 'après retour sur « Tout », l\'accueil doit rester dessous');
  });

  testWidgets('les bascules successives n\'empilent pas les pages',
      (tester) async {
    await tester.pumpWidget(harness());
    await tester.pumpAndSettle();

    await tester.tap(find.text('Voir tout'));
    await tester.pumpAndSettle();

    for (var i = 0; i < 3; i++) {
      await tester.tap(find.text('Par genre'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Tout'));
      await tester.pumpAndSettle();
    }

    // Un seul pop doit suffire pour revenir à l'accueil : la bascule
    // remplace la page courante au lieu d'en empiler une nouvelle.
    final context = tester.element(find.byType(Scaffold).last);
    Navigator.of(context).pop();
    await tester.pumpAndSettle();
    expect(find.text('Voir tout'), findsOneWidget);
  });
}
