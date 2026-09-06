import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mangatracker/features/reader/widgets/resume_reading_dialog.dart';
import 'package:mangatracker/l10n/app_localizations.dart';

/// La modale de reprise ne s'affiche que dans le cas ambigu (la lecture en
/// cours porte sur un AUTRE chapitre que celui qui allait s'ouvrir). Ses deux
/// issues doivent donc être explicites et chiffrées : aucune ne doit
/// ressembler à un saut dans le vide.
Future<bool?> _showAndCapture(
  WidgetTester tester, {
  required int resumeChapter,
  required int declinedChapter,
  Locale locale = const Locale('fr'),
}) async {
  bool? captured;

  await tester.pumpWidget(
    MaterialApp(
      locale: locale,
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
                captured = await ResumeReadingDialog.show(
                  context,
                  resumeChapter: resumeChapter,
                  declinedChapter: declinedChapter,
                );
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
  return captured;
}

void main() {
  group('modale de reprise de lecture', () {
    testWidgets('nomme les deux chapitres, pas seulement celui de la reprise',
        (tester) async {
      await _showAndCapture(tester, resumeChapter: 50, declinedChapter: 42);

      expect(find.text('Reprendre votre lecture ?'), findsOneWidget);
      expect(
        find.textContaining('chapitre 50'),
        findsWidgets,
        reason: 'l\'utilisateur doit savoir OÙ il reprendrait',
      );
      expect(
        find.text('Ouvrir le chapitre 42'),
        findsOneWidget,
        reason: 'refuser doit annoncer précisément ce qui s\'ouvrira',
      );
    });

    testWidgets('« Reprendre » rend true', (tester) async {
      await _showAndCapture(tester, resumeChapter: 50, declinedChapter: 42);

      await tester.tap(find.text('Reprendre le chapitre 50'));
      await tester.pumpAndSettle();

      expect(find.byType(ResumeReadingDialog), findsNothing);
    });

    testWidgets('« Ouvrir le chapitre suivant » rend false', (tester) async {
      await _showAndCapture(tester, resumeChapter: 50, declinedChapter: 42);

      await tester.tap(find.text('Ouvrir le chapitre 42'));
      await tester.pumpAndSettle();

      expect(find.byType(ResumeReadingDialog), findsNothing);
    });

    testWidgets('est traduite (aucun texte français en anglais)',
        (tester) async {
      await _showAndCapture(
        tester,
        resumeChapter: 50,
        declinedChapter: 42,
        locale: const Locale('en'),
      );

      expect(find.text('Resume your reading?'), findsOneWidget);
      expect(find.text('Resume chapter 50'), findsOneWidget);
      expect(find.text('Open chapter 42'), findsOneWidget);
      expect(find.text('Reprendre votre lecture ?'), findsNothing);
    });

    testWidgets('utilise une icône, jamais un émoji', (tester) async {
      await _showAndCapture(tester, resumeChapter: 50, declinedChapter: 42);

      expect(find.byIcon(Icons.bookmark_outline), findsOneWidget);
      expect(find.byIcon(Icons.play_arrow), findsOneWidget);
    });
  });
}
