import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mangatracker/features/reader/services/reader_bar_visibility.dart';
import 'package:mangatracker/features/reader/widgets/reader_auto_hide_bar.dart';

void main() {
  group('ReaderBarVisibility', () {
    test('se cache en descendant, revient en remontant', () {
      final bar = ReaderBarVisibility(
        threshold: 24,
        topZone: 80,
        settle: Duration.zero,
      );
      expect(bar.onScroll(100), isTrue);
      expect(bar.onScroll(140), isFalse, reason: 'descente franche');
      expect(bar.onScroll(600), isFalse);
      expect(bar.onScroll(560), isTrue, reason: 'remontée franche');
    });

    test('un tremblement du doigt ne la fait pas clignoter', () {
      final bar = ReaderBarVisibility(threshold: 24, topZone: 80);
      bar.onScroll(300);
      for (final y in [310, 305, 312, 304, 309]) {
        expect(bar.onScroll(y), isTrue);
      }
    });

    test('toujours visible près du haut de la page', () {
      final bar = ReaderBarVisibility(
        threshold: 24,
        topZone: 80,
        settle: Duration.zero,
      );
      bar.onScroll(500);
      bar.onScroll(900);
      expect(bar.visible, isFalse);
      expect(bar.onScroll(40), isTrue);
    });

    test('juste après une bascule, le recul de la page est ignoré', () {
      var now = DateTime(2026, 10, 6, 12);
      final bar = ReaderBarVisibility(
        threshold: 24,
        topZone: 80,
        settle: const Duration(milliseconds: 400),
        clock: () => now,
      );
      bar.onScroll(2000);
      expect(bar.onScroll(2100), isFalse, reason: 'cachée en descendant');
      // La page s'agrandit : en bas de page le navigateur recule de 56 px.
      now = now.add(const Duration(milliseconds: 50));
      expect(bar.onScroll(2044), isFalse, reason: 'recul ignoré');
      // Après le délai, un vrai mouvement vers le haut la fait revenir.
      now = now.add(const Duration(milliseconds: 500));
      expect(bar.onScroll(2030), isFalse, reason: 'mouvement trop court');
      expect(bar.onScroll(2000), isTrue, reason: 'remontée franche');
    });

    test('nouvelle page : visible', () {
      final bar =
          ReaderBarVisibility()
            ..onScroll(500)
            ..onScroll(900);
      expect(bar.visible, isFalse);
      bar.reset();
      expect(bar.visible, isTrue);
    });
  });

  group('ReaderAutoHideBar', () {
    Widget app({required bool visible, required VoidCallback onTap}) =>
        MaterialApp(
          home: Scaffold(
            body: ReaderAutoHideBar(
              visible: visible,
              appBar: AppBar(
                title: const Text('Lire en ligne'),
                actions: [
                  IconButton(onPressed: onTap, icon: const Icon(Icons.refresh)),
                ],
              ),
              child: const ColoredBox(color: Colors.white),
            ),
          ),
        );

    testWidgets('cachée : ni touchable ni lue par le lecteur d\'écran', (
      tester,
    ) async {
      var taps = 0;
      await tester.pumpWidget(app(visible: false, onTap: () => taps++));
      await tester.pumpAndSettle();
      expect(find.byIcon(Icons.refresh).hitTestable(), findsNothing);
      expect(find.bySemanticsLabel('Lire en ligne'), findsNothing);

      await tester.pumpWidget(app(visible: true, onTap: () => taps++));
      await tester.pumpAndSettle();
      await tester.tap(find.byIcon(Icons.refresh));
      expect(taps, 1);
    });

    testWidgets(
      "cachée : la page occupe tout l'écran, sans bande vide en haut",
      (tester) async {
        // Barre d'état de 24 px : avant, la page restait sous une bande
        // blanche de cette hauteur une fois la barre cachée (retour v0.18.0).
        tester.view.physicalSize = const Size(360, 640);
        tester.view.devicePixelRatio = 1;
        tester.view.padding = const FakeViewPadding(top: 24, bottom: 24);
        tester.view.viewPadding = const FakeViewPadding(top: 24, bottom: 24);
        addTearDown(tester.view.reset);

        Widget page(bool visible) => MaterialApp(
          home: Scaffold(
            body: ReaderAutoHideBar(
              visible: visible,
              appBar: AppBar(title: const Text('Lire en ligne')),
              child: const SizedBox.expand(key: Key('page')),
            ),
          ),
        );

        await tester.pumpWidget(page(false));
        await tester.pumpAndSettle();
        final rect = tester.getRect(find.byKey(const Key('page')));
        expect(rect.top, 0);
        expect(rect.height, 640, reason: 'aucune bande en bas non plus');

        await tester.pumpWidget(page(true));
        await tester.pumpAndSettle();
        final bar = tester.getRect(find.byType(AppBar));
        expect(bar.top, 0, reason: "la barre couvre la barre d'état");
        expect(
          tester.getRect(find.byKey(const Key('page'))).top,
          greaterThanOrEqualTo(bar.bottom),
        );
      },
    );

    testWidgets('barres du système : masquées avec la barre, rétablies en '
        'quittant le lecteur', (tester) async {
      final modes = <Object?>[];
      tester.binding.defaultBinaryMessenger.setMockMethodCallHandler(
        SystemChannels.platform,
        (call) async {
          if (call.method == 'SystemChrome.setEnabledSystemUIMode') {
            modes.add(call.arguments);
          }
          return null;
        },
      );
      addTearDown(
        () => tester.binding.defaultBinaryMessenger.setMockMethodCallHandler(
          SystemChannels.platform,
          null,
        ),
      );

      Widget page(bool visible) => MaterialApp(
        home: Scaffold(
          body: ReaderAutoHideBar(
            visible: visible,
            appBar: AppBar(title: const Text('Lire en ligne')),
            child: const SizedBox.expand(),
          ),
        ),
      );

      await tester.pumpWidget(page(true));
      await tester.pumpWidget(page(false));
      await tester.pumpWidget(page(true));
      await tester.pumpWidget(const MaterialApp(home: SizedBox()));
      expect(modes, [
        'SystemUiMode.edgeToEdge',
        'SystemUiMode.immersiveSticky',
        'SystemUiMode.edgeToEdge',
        'SystemUiMode.edgeToEdge',
      ]);
    });

    testWidgets('visible, elle ne recouvre pas la page (place réservée)', (
      tester,
    ) async {
      Widget page(bool visible) => MaterialApp(
        home: Scaffold(
          body: ReaderAutoHideBar(
            visible: visible,
            appBar: AppBar(title: const Text('Lire en ligne')),
            child: const SizedBox.expand(key: Key('page')),
          ),
        ),
      );
      await tester.pumpWidget(page(true));
      await tester.pumpAndSettle();
      final bar = tester.getRect(find.byType(AppBar));
      final shown = tester.getRect(find.byKey(const Key('page')));
      expect(shown.top, greaterThanOrEqualTo(bar.bottom));

      await tester.pumpWidget(page(false));
      await tester.pumpAndSettle();
      final hidden = tester.getRect(find.byKey(const Key('page')));
      expect(
        hidden.top,
        lessThan(shown.top),
        reason: 'la page récupère la place',
      );
      expect(hidden.height, greaterThan(shown.height));
    });
  });
}
