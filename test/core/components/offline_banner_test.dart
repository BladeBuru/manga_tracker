import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mangatracker/core/components/offline_banner.dart';
import 'package:mangatracker/l10n/app_localizations.dart';

Widget _app(Widget child) => MaterialApp(
  locale: const Locale('fr'),
  localizationsDelegates: AppLocalizations.localizationsDelegates,
  supportedLocales: AppLocalizations.supportedLocales,
  home: Scaffold(
    body: Padding(padding: const EdgeInsets.all(16), child: child),
  ),
);

void main() {
  testWidgets('petit écran : compteur lisible, libellé sur une ligne', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(320, 640);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);

    await tester.pumpWidget(_app(const OfflineBanner(pendingActions: 112)));
    await tester.pumpAndSettle();

    expect(tester.takeException(), isNull);
    expect(find.text('Mode hors ligne'), findsOneWidget);
    expect(find.text('112 actions en attente'), findsOneWidget);
    expect(find.textContaining('Closure'), findsNothing);
    // Une seule ligne : la hauteur du libellé est celle d'une ligne.
    final label = tester.getSize(find.text('Mode hors ligne'));
    expect(label.height, lessThan(30));
  });

  testWidgets('en ligne avec des modifications en attente : bouton Synchroniser',
      (tester) async {
    var synced = false;
    await tester.pumpWidget(
      _app(PendingSyncBanner(pendingActions: 3, onSync: () => synced = true)),
    );
    expect(find.text('3 actions en attente'), findsOneWidget);
    await tester.tap(find.text('Synchroniser'));
    expect(synced, isTrue);
  });
}
