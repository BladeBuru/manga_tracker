import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mangatracker/core/components/offline_banner.dart';
import 'package:mangatracker/core/components/session_rejected_banner.dart';
import 'package:mangatracker/l10n/app_localizations.dart';

Future<void> _pump(WidgetTester tester, Widget child) async {
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
      home: Scaffold(body: child),
    ),
  );
  await tester.pumpAndSettle();
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  testWidgets('affiche l\'invitation a se reconnecter', (tester) async {
    await _pump(tester, const SessionRejectedBanner());

    expect(find.textContaining('Session expirée'), findsOneWidget);
    expect(find.byIcon(Icons.lock_clock_outlined), findsOneWidget);
  });

  testWidgets('propose l\'action de reconnexion et la declenche',
      (tester) async {
    var tapped = 0;
    await _pump(tester, SessionRejectedBanner(onReconnect: () => tapped++));

    final action = find.text('Se reconnecter');
    expect(action, findsOneWidget);

    await tester.tap(action);
    await tester.pumpAndSettle();
    expect(tapped, 1);
  });

  testWidgets('sans callback, reste purement informatif', (tester) async {
    await _pump(tester, const SessionRejectedBanner());

    // Pas de bouton : le bandeau n'impose rien, il informe.
    expect(find.byType(TextButton), findsNothing);
    expect(find.textContaining('Session expirée'), findsOneWidget);
  });

  testWidgets('ne dit PAS « hors ligne » — l\'appareil est joignable',
      (tester) async {
    // La confusion des deux bandeaux serait un mensonge a l'utilisateur :
    // sur 401 le serveur repond, c'est la session qui est morte.
    await _pump(tester, const SessionRejectedBanner());

    expect(find.byType(OfflineBanner), findsNothing);
    expect(find.textContaining('hors ligne'), findsNothing);
    expect(find.byIcon(Icons.cloud_off), findsNothing);
  });
}
