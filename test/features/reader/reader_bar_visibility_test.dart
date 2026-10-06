import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mangatracker/features/reader/services/reader_bar_visibility.dart';
import 'package:mangatracker/features/reader/widgets/reader_auto_hide_bar.dart';

void main() {
  group('ReaderBarVisibility', () {
    test('se cache en descendant, revient en remontant', () {
      final bar = ReaderBarVisibility(threshold: 24, topZone: 80);
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
      final bar = ReaderBarVisibility(threshold: 24, topZone: 80);
      bar.onScroll(500);
      bar.onScroll(900);
      expect(bar.visible, isFalse);
      expect(bar.onScroll(40), isTrue);
    });

    test('nouvelle page : visible', () {
      final bar = ReaderBarVisibility()
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
                  IconButton(
                    onPressed: onTap,
                    icon: const Icon(Icons.refresh),
                  ),
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
  });
}
