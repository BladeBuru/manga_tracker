import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mangatracker/core/components/horizontal_scroll_arrows.dart';
import 'package:mangatracker/core/components/hover_feedback.dart';
import 'package:mangatracker/l10n/app_localizations.dart';

/// Souris / grand écran : curseur « main », survol, flèches de carrousel.
void main() {
  Widget app(Widget child, {bool disableAnimations = false}) => MaterialApp(
        locale: const Locale('fr'),
        localizationsDelegates: const [
          AppLocalizations.delegate,
          GlobalMaterialLocalizations.delegate,
          GlobalWidgetsLocalizations.delegate,
          GlobalCupertinoLocalizations.delegate,
        ],
        supportedLocales: const [Locale('fr')],
        home: Builder(
          builder: (context) => MediaQuery(
            data: MediaQuery.of(context)
                .copyWith(disableAnimations: disableAnimations),
            child: Scaffold(body: child),
          ),
        ),
      );

  double zoomOf(WidgetTester tester) =>
      tester.widget<AnimatedScale>(find.byType(AnimatedScale)).scale;

  testWidgets('carte survolée : curseur main et couverture zoomée',
      (tester) async {
    await tester.pumpWidget(app(Center(
      child: HoverFeedback(
        child: SizedBox(
          width: 120,
          height: 160,
          child: HoverZoom(child: Container(color: Colors.grey)),
        ),
      ),
    )));
    expect(zoomOf(tester), 1);

    final mouse = await tester.createGesture(kind: PointerDeviceKind.mouse);
    await mouse.addPointer(location: Offset.zero);
    addTearDown(mouse.removePointer);
    await mouse.moveTo(tester.getCenter(find.byType(HoverZoom)));
    await tester.pumpAndSettle();

    expect(zoomOf(tester), greaterThan(1));
    expect(
      RendererBinding.instance.mouseTracker.debugDeviceActiveCursor(1),
      SystemMouseCursors.click,
    );

    await mouse.moveTo(const Offset(1, 1));
    await tester.pumpAndSettle();
    expect(zoomOf(tester), 1);
  });

  testWidgets('au doigt : aucun changement', (tester) async {
    await tester.pumpWidget(app(Center(
      child: HoverFeedback(
        child: SizedBox(
          width: 120,
          height: 160,
          child: HoverZoom(child: Container(color: Colors.grey)),
        ),
      ),
    )));
    final finger = await tester.startGesture(
      tester.getCenter(find.byType(HoverZoom)),
    );
    await tester.pumpAndSettle();
    expect(zoomOf(tester), 1);
    await finger.up();
  });

  testWidgets('animations réduites : pas de zoom, curseur conservé',
      (tester) async {
    await tester.pumpWidget(app(
      Center(
        child: HoverFeedback(
          child: SizedBox(
            width: 120,
            height: 160,
            child: HoverZoom(child: Container(color: Colors.grey)),
          ),
        ),
      ),
      disableAnimations: true,
    ));
    final mouse = await tester.createGesture(kind: PointerDeviceKind.mouse);
    await mouse.addPointer(location: Offset.zero);
    addTearDown(mouse.removePointer);
    await mouse.moveTo(tester.getCenter(find.byType(HoverZoom)));
    await tester.pumpAndSettle();
    expect(zoomOf(tester), 1);
  });

  group('flèches de carrousel', () {
    Widget carousel(ScrollController controller) => SizedBox(
          height: 200,
          child: HorizontalScrollArrows(
            controller: controller,
            centerY: 80,
            child: ListView.builder(
              controller: controller,
              scrollDirection: Axis.horizontal,
              itemCount: 30,
              itemBuilder: (_, i) => SizedBox(width: 140, child: Text('t$i')),
            ),
          ),
        );

    testWidgets('grand écran : suivant puis précédent', (tester) async {
      tester.view.physicalSize = const Size(1200, 800);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.reset);
      final controller = ScrollController();
      addTearDown(controller.dispose);
      await tester.pumpWidget(app(carousel(controller)));
      await tester.pumpAndSettle();

      expect(find.byTooltip('Titres suivants'), findsOneWidget);
      expect(find.byTooltip('Titres précédents'), findsNothing);

      await tester.tap(find.byTooltip('Titres suivants'));
      await tester.pumpAndSettle();
      expect(controller.offset, greaterThan(0));
      expect(find.byTooltip('Titres précédents'), findsOneWidget);
    });

    testWidgets('téléphone : aucune flèche', (tester) async {
      tester.view.physicalSize = const Size(400, 800);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.reset);
      final controller = ScrollController();
      addTearDown(controller.dispose);
      await tester.pumpWidget(app(carousel(controller)));
      await tester.pumpAndSettle();
      expect(find.byType(IconButton), findsNothing);
    });
  });
}
