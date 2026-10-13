import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mangatracker/features/reader/services/reader_bar_visibility.dart';
import 'package:mangatracker/features/reader/widgets/reader_auto_hide_bar.dart';
import 'package:mangatracker/features/reader/widgets/reader_bar_controller.dart';

void main() {
  group('ReaderBarVisibility — au prorata du défilement', () {
    /// Barre de 80 dp, unités = pixels logiques (sauf mention contraire).
    ReaderBarVisibility bar({double slack = 0, DateTime Function()? clock}) =>
        ReaderBarVisibility(
          topZone: 32,
          slack: slack,
          settle: const Duration(milliseconds: 400),
          clock: clock,
        )..extent = 80;

    test('descendre la retire progressivement, remonter la ramène', () {
      final b = bar();
      expect(b.onScroll(1000), 80, reason: 'premier relevé : référence');
      expect(b.onScroll(1030), 50);
      expect(b.onScroll(1060), 20);
      expect(b.onScroll(1500), 0, reason: 'jamais en dessous de 0');
      expect(b.onScroll(1480), 20, reason: 'remonter de 20 en révèle 20');
      expect(b.onScroll(1400), 80, reason: 'jamais au-delà de sa taille');
    });

    test('pixels physiques Android : convertis en pixels logiques', () {
      final b = bar()..scrollUnitsPerLogicalPixel = 2.75;
      b.onScroll(2750);
      expect(b.onScroll(2750 + 110), closeTo(40, 0.01),
          reason: '110 px physiques = 40 dp');
    });

    test('un petit retour en arrière ne la ramène pas entière', () {
      final b = bar(slack: 12);
      b
        ..onScroll(1000)
        ..onScroll(1500);
      expect(b.shown, 0);
      // Relire une ligne : 30 dp vers le haut.
      expect(b.onScroll(1470), 18, reason: '30 dp moins la marge de 12');
      expect(b.snapTarget(), 0, reason: 'moins de la moitié : elle repart');
    });

    test('ancien seuil (24 px physiques = 8,7 dp) : ne bouge plus', () {
      final b = bar(slack: 12)..scrollUnitsPerLogicalPixel = 2.75;
      b
        ..onScroll(5000)
        ..onScroll(9000);
      expect(b.shown, 0);
      expect(b.onScroll(9000 - 24), 0);
    });

    test('au repos, un tremblement du doigt ne la déplace pas', () {
      final b = bar(slack: 12);
      b.onScroll(1000);
      for (final y in [1005, 1001, 1008, 1003]) {
        expect(b.onScroll(y), 80, reason: 'entière : $y');
      }
      b.onScroll(1500);
      for (final y in [1495, 1499, 1493, 1498]) {
        expect(b.onScroll(y), 0, reason: 'cachée : $y');
      }
    });

    test('recalage : entière dès la moitié, cachée en dessous', () {
      final b = bar();
      b
        ..onScroll(1000)
        ..onScroll(1040);
      expect(b.shown, 40);
      expect(b.snapTarget(), 80);
      b.onScroll(1041);
      expect(b.snapTarget(), 0);
    });

    test('près du haut : posée sur le contenu, entière en haut de page', () {
      final b = bar(slack: 12);
      expect(b.onScroll(0), 80);
      expect(b.onScroll(20), 80, reason: 'dans la zone haute');
      expect(b.onScroll(72), 40, reason: 'elle part avec le contenu');
      b.onScroll(900);
      expect(b.shown, 0);
      expect(b.onScroll(10), 80, reason: 'retour en haut de page');
    });

    test('après un recalage sur « entière », le recul de la page est ignoré',
        () {
      var now = DateTime(2026, 10, 13, 12);
      final b = bar(clock: () => now);
      b
        ..onScroll(2000)
        ..onScroll(2050);
      expect(b.shown, 30);
      b.settleAt(80);
      // La page rétrécit sous la barre : en bas de page le navigateur
      // recule de 80 px.
      now = now.add(const Duration(milliseconds: 50));
      expect(b.onScroll(1970), 80, reason: 'recul ignoré');
      now = now.add(const Duration(milliseconds: 500));
      expect(b.onScroll(2000), 50, reason: 'vrai mouvement ensuite');
    });

    test('hauteur connue plus tard : une barre entière le reste', () {
      final b = ReaderBarVisibility();
      expect(b.shown, 0, reason: 'hauteur inconnue');
      b.extent = 56;
      expect(b.shown, 56);
      b.extent = 80;
      expect(b.shown, 80);
      b
        ..onScroll(5000)
        ..onScroll(9000);
      b.extent = 84;
      expect(b.shown, 0, reason: 'une barre cachée reste cachée');
    });

    test('nouvelle page : entière', () {
      final b = bar();
      b
        ..onScroll(500)
        ..onScroll(900);
      expect(b.shown, 0);
      expect(b.reset(), 80);
    });
  });

  group('ReaderAutoHideBar', () {
    /// Unités Android des tests : pixels physiques, au ratio de la vue.
    void scrollTo(WidgetTester tester, ReaderBarController c, double dp) =>
        c.onScroll((dp * tester.view.devicePixelRatio).round());

    /// Cache la barre (défilement vers le bas) puis attend le recalage.
    Future<void> hide(WidgetTester tester, ReaderBarController c) async {
      scrollTo(tester, c, 1000);
      scrollTo(tester, c, 2000);
      await tester.pump(const Duration(milliseconds: 200));
      await tester.pumpAndSettle();
    }

    Future<void> show(WidgetTester tester, ReaderBarController c) async {
      c.reset();
      await tester.pump(const Duration(milliseconds: 200));
      await tester.pumpAndSettle();
    }

    Widget app(
      ReaderBarController c, {
      VoidCallback? onTap,
      Widget? overlay,
    }) =>
        MaterialApp(
          home: Scaffold(
            body: ReaderAutoHideBar(
              controller: c,
              appBar: AppBar(
                title: const Text('Lire en ligne'),
                actions: [
                  IconButton(
                    onPressed: onTap ?? () {},
                    icon: const Icon(Icons.refresh_outlined),
                  ),
                ],
              ),
              page: const SizedBox.expand(key: Key('page')),
              overlay: overlay,
            ),
          ),
        );

    /// Nœud RÉELLEMENT présent dans l'arbre de sémantique :
    /// `find.bySemanticsLabel` voit aussi les nœuds détachés d'un sous-arbre
    /// exclu après coup (la barre était visible avant d'être cachée).
    Finder inSemanticsTree(String label) => find.byElementPredicate((e) {
          if (e is! RenderObjectElement) return false;
          final node = e.renderObject.debugSemantics;
          return node != null && node.attached && node.label == label;
        });

    Rect pageRect(WidgetTester tester) =>
        tester.getRect(find.byKey(const Key('page')));

    testWidgets('cachée : ni touchable ni lue par le lecteur d\'écran', (
      tester,
    ) async {
      var taps = 0;
      final c = ReaderBarController();
      addTearDown(c.dispose);
      await tester.pumpWidget(app(c, onTap: () => taps++));
      await hide(tester, c);
      expect(c.shown, 0);
      expect(find.byIcon(Icons.refresh_outlined).hitTestable(), findsNothing);
      expect(inSemanticsTree('Lire en ligne'), findsNothing);

      await show(tester, c);
      expect(inSemanticsTree('Lire en ligne'), findsOneWidget);
      await tester.tap(find.byIcon(Icons.refresh_outlined));
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
        final c = ReaderBarController();
        addTearDown(c.dispose);

        await tester.pumpWidget(app(c));
        await hide(tester, c);
        expect(pageRect(tester).top, 0);
        expect(pageRect(tester).height, 640,
            reason: 'aucune bande en bas non plus');

        await show(tester, c);
        final bar = tester.getRect(find.byType(AppBar));
        expect(bar.top, 0, reason: "la barre couvre la barre d'état");
        expect(bar.height, 24 + kToolbarHeight);
        expect(pageRect(tester).top, greaterThanOrEqualTo(bar.bottom));
      },
    );

    testWidgets('barres du système : masquées une fois la barre cachée, '
        'de retour dès qu\'elle revient, rétablies en quittant', (
      tester,
    ) async {
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
      final c = ReaderBarController();
      addTearDown(c.dispose);

      await tester.pumpWidget(app(c));
      await hide(tester, c);
      // Elle commence à revenir : les barres du système aussi, aussitôt.
      scrollTo(tester, c, 1900);
      await tester.pump();
      expect(c.shown, greaterThan(0));
      await tester.pumpAndSettle(const Duration(milliseconds: 100));
      await tester.pumpWidget(const MaterialApp(home: SizedBox()));
      expect(modes, [
        'SystemUiMode.edgeToEdge',
        'SystemUiMode.immersiveSticky',
        'SystemUiMode.edgeToEdge',
        'SystemUiMode.edgeToEdge',
      ]);
    });

    testWidgets('au repos, visible, elle réserve sa place (jamais par-dessus)',
        (tester) async {
      final c = ReaderBarController();
      addTearDown(c.dispose);
      await tester.pumpWidget(app(c));
      await tester.pumpAndSettle();
      final bar = tester.getRect(find.byType(AppBar));
      final shown = pageRect(tester);
      expect(shown.top, greaterThanOrEqualTo(bar.bottom));

      await hide(tester, c);
      final hidden = pageRect(tester);
      expect(hidden.top, lessThan(shown.top), reason: 'la page récupère la place');
      expect(hidden.height, greaterThan(shown.height));
    });

    testWidgets('en plein mouvement : à moitié visible, la page juste dessous, '
        'sans être redimensionnée', (tester) async {
      final c = ReaderBarController();
      addTearDown(c.dispose);
      await tester.pumpWidget(app(c));
      await tester.pumpAndSettle();
      final screen = tester.getSize(find.byType(Scaffold));
      final extent = c.extent;

      // Descendre de 12 dp (marge) + 20 dp : 20 dp de barre en moins.
      scrollTo(tester, c, 1000);
      scrollTo(tester, c, 1032);
      await tester.pump();
      expect(c.shown, closeTo(extent - 20, 0.5));
      final bar = tester.getRect(find.byType(AppBar));
      expect(bar.bottom, closeTo(c.shown, 0.5), reason: 'partiellement visible');
      expect(pageRect(tester).top, closeTo(bar.bottom, 0.5),
          reason: 'la page commence sous la barre, jamais dessous');
      expect(pageRect(tester).height, screen.height,
          reason: 'page à hauteur fixe pendant le mouvement');

      // Le défilement s'arrête : recalage, entière (plus de la moitié
      // révélée).
      await tester.pump(const Duration(milliseconds: 200));
      await tester.pumpAndSettle();
      expect(c.shown, extent);
      expect(pageRect(tester).height, screen.height - extent,
          reason: 'au repos, la place est réellement réservée');
    });

    testWidgets('doigt posé sur la page : pas de recalage avant qu\'il se lève',
        (tester) async {
      final c = ReaderBarController();
      addTearDown(c.dispose);
      await tester.pumpWidget(app(c));
      await hide(tester, c);
      final finger = await tester.startGesture(
        tester.getCenter(find.byKey(const Key('page'))),
      );
      scrollTo(tester, c, 1970); // 30 dp vers le haut : 18 dp de barre
      await tester.pump(const Duration(seconds: 1));
      expect(c.shown, closeTo(18, 0.5), reason: 'en attente du doigt');
      await finger.up();
      await tester.pump(const Duration(milliseconds: 200));
      await tester.pumpAndSettle();
      expect(c.shown, 0, reason: 'moins de la moitié : elle repart');
    });

    testWidgets('les recouvrements restent ancrés à l\'écran', (tester) async {
      final c = ReaderBarController();
      addTearDown(c.dispose);
      await tester.pumpWidget(app(
        c,
        overlay: const Stack(
          children: [
            Positioned(
              left: 0,
              right: 0,
              bottom: 0,
              height: 40,
              child: SizedBox(key: Key('banner')),
            ),
          ],
        ),
      ));
      await tester.pumpAndSettle();
      final screen = tester.getSize(find.byType(Scaffold));
      scrollTo(tester, c, 1000);
      scrollTo(tester, c, 1042);
      await tester.pump();
      expect(pageRect(tester).bottom, greaterThan(screen.height),
          reason: 'la page est décalée');
      expect(tester.getRect(find.byKey(const Key('banner'))).bottom,
          screen.height,
          reason: 'le bandeau, lui, ne bouge pas');
      await tester.pump(const Duration(milliseconds: 200));
      await tester.pumpAndSettle();
    });
  });
}
