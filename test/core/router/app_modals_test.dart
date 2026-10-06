import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mangatracker/core/router/app_modals.dart';

Widget _app(void Function(BuildContext) onTap) => MaterialApp(
  home: Scaffold(
    body: Builder(
      builder:
          (context) => TextButton(
            onPressed: () => onTap(context),
            child: const Text('open'),
          ),
    ),
  ),
);

void main() {
  testWidgets('deux appuis rapides n\'ouvrent qu\'un seul dialogue', (
    tester,
  ) async {
    await tester.pumpWidget(
      _app((context) {
        // Les deux appels partent avant que le premier soit dessiné : c'est
        // le cas du bouton qui attend une donnée avant d'ouvrir.
        showAppDialog<void>(
          context: context,
          builder: (_) => const AlertDialog(content: Text('dialogue')),
        );
        showAppDialog<void>(
          context: context,
          builder: (_) => const AlertDialog(content: Text('dialogue')),
        );
      }),
    );
    await tester.tap(find.text('open'));
    await tester.pumpAndSettle();
    expect(find.text('dialogue'), findsOneWidget);
  });

  testWidgets('idem pour les feuilles du bas', (tester) async {
    await tester.pumpWidget(
      _app((context) {
        for (var i = 0; i < 2; i++) {
          showAppBottomSheet<void>(
            context: context,
            builder: (_) => const Text('feuille'),
          );
        }
      }),
    );
    await tester.tap(find.text('open'));
    await tester.pumpAndSettle();
    expect(find.text('feuille'), findsOneWidget);
  });

  testWidgets('une fenêtre ouverte DEPUIS une autre reste permise', (
    tester,
  ) async {
    await tester.pumpWidget(
      _app((context) {
        showAppBottomSheet<void>(
          context: context,
          builder:
              (sheetContext) => TextButton(
                onPressed:
                    () => showAppDialog<void>(
                      context: sheetContext,
                      builder: (_) => const Text('imbriqué'),
                    ),
                child: const Text('dans la feuille'),
              ),
        );
      }),
    );
    await tester.tap(find.text('open'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('dans la feuille'));
    await tester.pumpAndSettle();
    expect(find.text('imbriqué'), findsOneWidget);
  });

  testWidgets('fermer puis rouvrir aussitôt fonctionne', (tester) async {
    late BuildContext page;
    await tester.pumpWidget(_app((context) => page = context));
    await tester.tap(find.text('open'));

    showAppDialog<void>(context: page, builder: (_) => const Text('premier'));
    await tester.pumpAndSettle();
    // Même geste qu'un menu : on ferme, puis on ouvre la suite tout de suite.
    Navigator.of(page).pop();
    showAppDialog<void>(context: page, builder: (_) => const Text('second'));
    await tester.pumpAndSettle();
    expect(find.text('premier'), findsNothing);
    expect(find.text('second'), findsOneWidget);
  });

  testWidgets('les feuilles évitent la barre de navigation du système', (
    tester,
  ) async {
    tester.view.padding = const FakeViewPadding(bottom: 144);
    addTearDown(tester.view.reset);
    await tester.pumpWidget(
      _app(
        (context) => showAppBottomSheet<void>(
          context: context,
          builder: (_) => const SizedBox(height: 40, child: Text('bas')),
        ),
      ),
    );
    await tester.tap(find.text('open'));
    await tester.pumpAndSettle();
    final bottom = tester.getBottomLeft(find.text('bas')).dy;
    final screen = tester.view.physicalSize.height / tester.view.devicePixelRatio;
    final systemBar = 144 / tester.view.devicePixelRatio;
    expect(bottom, lessThanOrEqualTo(screen - systemBar));
  });

  // Fil de détente : toute nouvelle fenêtre doit passer par app_modals.dart,
  // sinon le double appui ré-ouvre des fenêtres empilées.
  test('aucun showDialog / showModalBottomSheet / showDatePicker direct', () {
    final offenders = <String>[];
    final raw = RegExp(
      r'\bshow(Dialog|ModalBottomSheet|DatePicker|GeneralDialog)\b\s*[<(]',
    );
    for (final file in Directory('lib').listSync(recursive: true)) {
      if (file is! File || !file.path.endsWith('.dart')) continue;
      if (file.path.endsWith('app_modals.dart')) continue;
      final lines = file.readAsLinesSync();
      for (var i = 0; i < lines.length; i++) {
        final line = lines[i].trim();
        if (line.startsWith('//')) continue;
        if (raw.hasMatch(line)) offenders.add('${file.path}:${i + 1}');
      }
    }
    expect(offenders, isEmpty);
  });
}
