import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mangatracker/features/recommendations/dto/dismissal_reason.dart';
import 'package:mangatracker/features/recommendations/widgets/dismiss_recommendation_sheet.dart';
import 'package:mangatracker/l10n/app_localizations.dart';

/// Tests de la feuille modale « ne plus me recommander ce titre ».
///
/// Ce qui compte ici : les trois raisons sont bien proposées (la raison est
/// la valeur de la fonctionnalité, pas le rejet lui-même) et une fermeture
/// sans choix ne rejette rien.
void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  Widget harness({required void Function(DismissalReason?) onResult}) {
    return MaterialApp(
      locale: const Locale('fr'),
      localizationsDelegates: const [
        AppLocalizations.delegate,
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      supportedLocales: AppLocalizations.supportedLocales,
      home: Scaffold(
        body: Builder(
          builder: (context) => ElevatedButton(
            onPressed: () async {
              final reason = await showDismissRecommendationSheet(
                context,
                mangaTitle: 'One Piece',
              );
              onResult(reason);
            },
            child: const Text('ouvrir'),
          ),
        ),
      ),
    );
  }

  Future<void> openSheet(WidgetTester tester) async {
    await tester.tap(find.text('ouvrir'));
    await tester.pumpAndSettle();
  }

  testWidgets('propose les trois raisons et rappelle le titre concerné', (
    tester,
  ) async {
    await tester.pumpWidget(harness(onResult: (_) {}));
    await openSheet(tester);

    expect(find.text('Déjà lu'), findsOneWidget);
    expect(find.text('Pas intéressé'), findsOneWidget);
    expect(find.text('Vu ailleurs'), findsOneWidget);
    // Le titre est rappelé pour qu'on sache ce qu'on écarte.
    expect(find.textContaining('One Piece'), findsOneWidget);
  });

  testWidgets('« Vu ailleurs » renvoie seenElsewhere — le cas fondateur', (
    tester,
  ) async {
    DismissalReason? result;
    await tester.pumpWidget(harness(onResult: (r) => result = r));
    await openSheet(tester);

    await tester.tap(find.text('Vu ailleurs'));
    await tester.pumpAndSettle();

    expect(result, DismissalReason.seenElsewhere);
  });

  testWidgets('« Déjà lu » renvoie alreadyRead', (tester) async {
    DismissalReason? result;
    await tester.pumpWidget(harness(onResult: (r) => result = r));
    await openSheet(tester);

    await tester.tap(find.text('Déjà lu'));
    await tester.pumpAndSettle();

    expect(result, DismissalReason.alreadyRead);
  });

  testWidgets('« Pas intéressé » renvoie notInterested', (tester) async {
    DismissalReason? result;
    await tester.pumpWidget(harness(onResult: (r) => result = r));
    await openSheet(tester);

    await tester.tap(find.text('Pas intéressé'));
    await tester.pumpAndSettle();

    expect(result, DismissalReason.notInterested);
  });

  testWidgets('Annuler ferme la feuille sans rien écarter', (tester) async {
    DismissalReason? result;
    var called = false;
    await tester.pumpWidget(
      harness(
        onResult: (r) {
          called = true;
          result = r;
        },
      ),
    );
    await openSheet(tester);

    await tester.tap(find.text('Annuler'));
    await tester.pumpAndSettle();

    expect(called, isTrue, reason: 'la feuille doit bien se fermer');
    expect(result, isNull, reason: 'aucune raison choisie = aucun rejet');
  });
}
