import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mangatracker/features/reader/widgets/reader_action_bar.dart';
import 'package:mangatracker/l10n/app_localizations.dart';

/// Libellés attendus en français, la locale de référence du projet.
const _refreshLabel = 'Rafraîchir la page';
const _moreLabel = "Plus d'actions";
const _disableAdBlocker = 'Désactiver le bloqueur de publicités';
const _enableAdBlocker = 'Activer le bloqueur de publicités';
const _downloadLabel = 'Télécharger cette page';
const _copyLabel = "Copier l'URL";
const _interactiveOn = 'Activer le mode détection de pub';
const _interactiveOff = 'Désactiver le mode détection de pub';
const _infoLabel = 'Informations sur le bloqueur de pub';

Future<void> _pumpBar(
  WidgetTester tester, {
  bool adBlockerEnabled = true,
  bool interactiveAdBlockMode = false,
  VoidCallback? onRefresh,
  ValueChanged<bool>? onToggleAdBlocker,
  ValueChanged<ReaderOverflowAction>? onOverflowAction,
}) async {
  final view = tester.view;
  view.devicePixelRatio = 1.0;
  view.physicalSize = const Size(800, 1200);
  addTearDown(() {
    view.resetPhysicalSize();
    view.resetDevicePixelRatio();
  });

  await tester.pumpWidget(
    MaterialApp(
      locale: const Locale('fr'),
      localizationsDelegates: const [
        AppLocalizations.delegate,
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      supportedLocales: AppLocalizations.supportedLocales,
      home: Scaffold(
        appBar: AppBar(
          title: const Text('Lire en ligne'),
          actions: [
            ReaderActionBar(
              adBlockerEnabled: adBlockerEnabled,
              interactiveAdBlockMode: interactiveAdBlockMode,
              onRefresh: onRefresh ?? () {},
              onToggleAdBlocker: onToggleAdBlocker ?? (_) {},
              onOverflowAction: onOverflowAction ?? (_) {},
            ),
          ],
        ),
      ),
    ),
  );
  await tester.pumpAndSettle();
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('actions rapides', () {
    testWidgets('rafraîchir et bloqueur de pub sont visibles directement',
        (tester) async {
      await _pumpBar(tester);

      expect(find.byIcon(Icons.refresh_outlined), findsOneWidget);
      expect(find.byIcon(Icons.block_outlined), findsOneWidget);
      expect(find.byIcon(Icons.more_vert_outlined), findsOneWidget);
    });

    testWidgets('chaque action visible porte un tooltip', (tester) async {
      await _pumpBar(tester);

      expect(find.byTooltip(_refreshLabel), findsOneWidget);
      expect(find.byTooltip(_disableAdBlocker), findsOneWidget);
      expect(find.byTooltip(_moreLabel), findsOneWidget);
    });

    testWidgets('chaque action visible expose un libellé au lecteur d\'écran',
        (tester) async {
      final handle = tester.ensureSemantics();
      await _pumpBar(tester);

      // `label` : ce que lit un lecteur d'écran qui navigue par libellés.
      expect(find.bySemanticsLabel(_refreshLabel), findsOneWidget);
      expect(find.bySemanticsLabel(_disableAdBlocker), findsOneWidget);
      expect(find.bySemanticsLabel(_moreLabel), findsOneWidget);

      // `tooltip` : la propriété alimentée par le tooltip Material.
      for (final label in [_refreshLabel, _disableAdBlocker, _moreLabel]) {
        expect(
          tester.getSemantics(find.byTooltip(label)).tooltip,
          label,
          reason: 'tooltip sémantique manquant pour « $label »',
        );
      }

      handle.dispose();
    });

    testWidgets('le rafraîchissement déclenche le rechargement',
        (tester) async {
      var refreshCount = 0;
      await _pumpBar(tester, onRefresh: () => refreshCount++);

      await tester.tap(find.byTooltip(_refreshLabel));
      await tester.pumpAndSettle();

      expect(refreshCount, 1);
    });
  });

  group('bouton du bloqueur de publicités', () {
    testWidgets('demande la désactivation quand il est actif', (tester) async {
      bool? requested;
      await _pumpBar(
        tester,
        adBlockerEnabled: true,
        onToggleAdBlocker: (value) => requested = value,
      );

      await tester.tap(find.byTooltip(_disableAdBlocker));
      await tester.pumpAndSettle();

      expect(requested, isFalse);
    });

    testWidgets('demande l\'activation quand il est inactif', (tester) async {
      bool? requested;
      await _pumpBar(
        tester,
        adBlockerEnabled: false,
        onToggleAdBlocker: (value) => requested = value,
      );

      // Le libellé décrit l'action à venir : il bascule avec l'état.
      expect(find.byTooltip(_enableAdBlocker), findsOneWidget);

      await tester.tap(find.byTooltip(_enableAdBlocker));
      await tester.pumpAndSettle();

      expect(requested, isTrue);
    });

    testWidgets('expose son état via la sémantique du bouton', (tester) async {
      await _pumpBar(tester, adBlockerEnabled: true);
      final selected = tester.widget<IconButton>(
        find.widgetWithIcon(IconButton, Icons.block_outlined),
      );
      expect(selected.isSelected, isTrue);

      await _pumpBar(tester, adBlockerEnabled: false);
      final unselected = tester.widget<IconButton>(
        find.widgetWithIcon(IconButton, Icons.block_outlined),
      );
      expect(unselected.isSelected, isFalse);
    });
  });

  group('menu overflow', () {
    testWidgets('les actions secondaires ne sont pas visibles au repos',
        (tester) async {
      await _pumpBar(tester);

      expect(find.text(_downloadLabel), findsNothing);
      expect(find.text(_copyLabel), findsNothing);
      expect(find.text(_interactiveOn), findsNothing);
      expect(find.text(_infoLabel), findsNothing);
    });

    testWidgets('les actions secondaires sont accessibles dans le menu',
        (tester) async {
      await _pumpBar(tester);

      await tester.tap(find.byTooltip(_moreLabel));
      await tester.pumpAndSettle();

      expect(find.text(_downloadLabel), findsOneWidget);
      expect(find.text(_copyLabel), findsOneWidget);
      expect(find.text(_interactiveOn), findsOneWidget);
      expect(find.text(_infoLabel), findsOneWidget);
    });

    testWidgets('le libellé du mode détection reflète son état',
        (tester) async {
      await _pumpBar(tester, interactiveAdBlockMode: true);

      await tester.tap(find.byTooltip(_moreLabel));
      await tester.pumpAndSettle();

      expect(find.text(_interactiveOff), findsOneWidget);
      expect(find.text(_interactiveOn), findsNothing);
    });

    testWidgets('choisir une entrée remonte l\'action correspondante',
        (tester) async {
      final selected = <ReaderOverflowAction>[];
      await _pumpBar(tester, onOverflowAction: selected.add);

      await tester.tap(find.byTooltip(_moreLabel));
      await tester.pumpAndSettle();
      await tester.tap(find.text(_downloadLabel));
      await tester.pumpAndSettle();

      expect(selected, [ReaderOverflowAction.downloadPage]);

      await tester.tap(find.byTooltip(_moreLabel));
      await tester.pumpAndSettle();
      await tester.tap(find.text(_infoLabel));
      await tester.pumpAndSettle();

      expect(selected, [
        ReaderOverflowAction.downloadPage,
        ReaderOverflowAction.adBlockerInfo,
      ]);
    });
  });
}
