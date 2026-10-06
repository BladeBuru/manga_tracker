import 'package:flutter/material.dart';
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
