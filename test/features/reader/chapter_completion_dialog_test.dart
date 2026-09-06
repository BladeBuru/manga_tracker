import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mangatracker/features/reader/widgets/chapter_completion_dialog.dart';
import 'package:mangatracker/features/reader/widgets/chapter_skip_dialog.dart';
import 'package:mangatracker/l10n/app_localizations.dart';

/// Les modales du lecteur sont extraites de la WebView justement pour être
/// testables : la vue du lecteur ne s'instancie pas en test unitaire, mais la
/// question posée à l'utilisateur, elle, doit être vérifiable.
Future<bool?> _showAndCapture(
  WidgetTester tester,
  Future<bool?> Function(BuildContext context) show,
) async {
  bool? captured;
  var opened = false;

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
      home: Builder(
        builder: (context) => Scaffold(
          body: Center(
            child: ElevatedButton(
              onPressed: () async {
                opened = true;
                captured = await show(context);
              },
              child: const Text('ouvrir'),
            ),
          ),
        ),
      ),
    ),
  );

  await tester.tap(find.text('ouvrir'));
  await tester.pumpAndSettle();
  expect(opened, isTrue);
  return captured;
}

void main() {
  group('modale de fin de chapitre', () {
    testWidgets('pose la question sur le chapitre en cours', (tester) async {
      await _showAndCapture(
        tester,
        (context) => ChapterCompletionDialog.show(context, chapter: 133),
      );

      expect(find.text('Avez-vous fini le chapitre 133 ?'), findsOneWidget);
      expect(find.text('Valider la lecture'), findsOneWidget);
      expect(find.text('Oui, valider'), findsOneWidget);
      expect(find.text('Non'), findsOneWidget);
    });

    testWidgets('« Oui, valider » répond true', (tester) async {
      bool? answer;
      await _showAndCapture(tester, (context) async {
        answer = await ChapterCompletionDialog.show(context, chapter: 133);
        return answer;
      });

      await tester.tap(find.text('Oui, valider'));
      await tester.pumpAndSettle();

      expect(answer, isTrue);
    });

    testWidgets('« Non » répond false — rien ne doit être enregistré',
        (tester) async {
      bool? answer;
      await _showAndCapture(tester, (context) async {
        answer = await ChapterCompletionDialog.show(context, chapter: 133);
        return answer;
      });

      await tester.tap(find.text('Non'));
      await tester.pumpAndSettle();

      expect(answer, isFalse);
    });

    testWidgets('ne se ferme pas en touchant à côté', (tester) async {
      await _showAndCapture(
        tester,
        (context) => ChapterCompletionDialog.show(context, chapter: 133),
      );

      // Coin haut-gauche = barrière modale.
      await tester.tapAt(const Offset(10, 10));
      await tester.pumpAndSettle();

      expect(find.text('Avez-vous fini le chapitre 133 ?'), findsOneWidget,
          reason: 'La question doit recevoir une réponse explicite.');
    });
  });

  group('modale de saut de chapitres', () {
    testWidgets('la question porte sur le chapitre QUITTÉ', (tester) async {
      await _showAndCapture(
        tester,
        (context) => ChapterSkipDialog.show(
          context,
          previousChapter: 134,
          nextChapter: 140,
        ),
      );

      // Le texte est sur deux lignes : on cherche le fragment décisif.
      expect(
        find.textContaining('Marquer 134 comme lu ?'),
        findsOneWidget,
        reason: 'Sauter du 134 au 140 ne doit jamais proposer 139 ni 140.',
      );
      expect(find.textContaining('du chapitre 134 au 140'), findsOneWidget);
    });

    testWidgets('« Oui » répond true', (tester) async {
      bool? answer;
      await _showAndCapture(tester, (context) async {
        answer = await ChapterSkipDialog.show(
          context,
          previousChapter: 134,
          nextChapter: 140,
        );
        return answer;
      });

      await tester.tap(find.text('Oui'));
      await tester.pumpAndSettle();

      expect(answer, isTrue);
    });
  });
}
