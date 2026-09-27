import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mangatracker/features/reader/widgets/challenge_handoff_banner.dart';
import 'package:mangatracker/l10n/app_localizations.dart';

Future<void> _pump(WidgetTester tester, Widget child) async {
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
  testWidgets('explique la vérification et annonce la reprise automatique',
      (tester) async {
    await _pump(tester, ChallengeHandoffBanner(onOpenInBrowser: () {}));

    expect(find.textContaining('Vérification de sécurité du site'),
        findsOneWidget);
    expect(find.textContaining('reprendra automatiquement'), findsOneWidget);
    expect(find.byIcon(Icons.verified_user_outlined), findsOneWidget);
  });

  testWidgets('propose la sortie vers le navigateur et la déclenche',
      (tester) async {
    var opened = 0;
    await _pump(
      tester,
      ChallengeHandoffBanner(onOpenInBrowser: () => opened++),
    );

    await tester.tap(find.text('Ouvrir dans le navigateur'));
    await tester.pump();

    expect(opened, 1);
  });
}
