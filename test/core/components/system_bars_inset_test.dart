import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mangatracker/core/components/system_bars_inset.dart';

void main() {
  Widget app(Widget home) => MaterialApp(
    builder: (context, child) => SystemBarsInset(child: child!),
    home: home,
  );

  testWidgets('un bouton en bas de page reste au-dessus de la barre à boutons',
      (tester) async {
    tester.view.physicalSize = const Size(360, 640);
    tester.view.devicePixelRatio = 1;
    tester.view.padding = const FakeViewPadding(bottom: 48);
    tester.view.viewPadding = const FakeViewPadding(bottom: 48);
    addTearDown(tester.view.reset);

    await tester.pumpWidget(
      app(
        Scaffold(
          body: Column(
            children: [
              const Spacer(),
              FilledButton(onPressed: () {}, child: const Text('Valider')),
            ],
          ),
        ),
      ),
    );

    final buttonBottom = tester.getBottomLeft(find.byType(FilledButton)).dy;
    expect(buttonBottom, lessThanOrEqualTo(640 - 48));
  });

  testWidgets('pas de double marge : la barre du bas ne se décale pas deux fois',
      (tester) async {
    tester.view.physicalSize = const Size(360, 640);
    tester.view.devicePixelRatio = 1;
    tester.view.padding = const FakeViewPadding(bottom: 48);
    tester.view.viewPadding = const FakeViewPadding(bottom: 48);
    addTearDown(tester.view.reset);

    late EdgeInsets inner;
    await tester.pumpWidget(
      app(
        Builder(
          builder: (context) {
            inner = MediaQuery.paddingOf(context);
            return const SizedBox();
          },
        ),
      ),
    );
    expect(inner.bottom, 0);
  });

  testWidgets('clavier : la bande déjà réservée n\'est pas comptée deux fois',
      (tester) async {
    tester.view.physicalSize = const Size(360, 640);
    tester.view.devicePixelRatio = 1;
    tester.view.viewPadding = const FakeViewPadding(bottom: 48);
    tester.view.viewInsets = const FakeViewPadding(bottom: 300);
    addTearDown(tester.view.reset);

    late EdgeInsets insets;
    await tester.pumpWidget(
      app(
        Builder(
          builder: (context) {
            insets = MediaQuery.viewInsetsOf(context);
            return const SizedBox();
          },
        ),
      ),
    );
    expect(insets.bottom, 252);
  });

  testWidgets('sans barre système : rien ne change', (tester) async {
    await tester.pumpWidget(app(const Text('x', textDirection: TextDirection.ltr)));
    expect(find.byType(ColoredBox), findsNothing);
  });
}
