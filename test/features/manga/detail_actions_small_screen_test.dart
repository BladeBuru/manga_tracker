import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mangatracker/core/theme/app_theme.dart';
import 'package:mangatracker/features/manga/widgets/detail_read_online_button.dart';
import 'package:mangatracker/features/manga/widgets/detail_status_selector.dart';
import 'package:mangatracker/features/reader/widgets/reader_chapter_title.dart';
import 'package:mangatracker/l10n/app_localizations.dart';

/// Barre d'actions de la fiche et titre du lecteur hors ligne sur un petit
/// téléphone (320 dp) avec texte agrandi : libellés sur UNE ligne, numéro de
/// chapitre toujours visible.
Widget _app(Locale locale, Widget child) => MaterialApp(
  locale: locale,
  theme: AppTheme.light,
  localizationsDelegates: AppLocalizations.localizationsDelegates,
  supportedLocales: AppLocalizations.supportedLocales,
  builder:
      (context, child) => MediaQuery(
        data: MediaQuery.of(
          context,
        ).copyWith(textScaler: const TextScaler.linear(1.3)),
        child: child!,
      ),
  home: Scaffold(body: child),
);

/// Même disposition que la barre d'actions de `DetailBlocView`.
Widget _actionBar(Widget main) => Row(
  children: [
    const Padding(
      padding: EdgeInsets.only(left: 16),
      child: SizedBox(width: 48, height: 48),
    ),
    Expanded(child: main),
    const Padding(
      padding: EdgeInsets.only(right: 16),
      child: SizedBox(width: 48, height: 48),
    ),
  ],
);

Future<void> _smallPhone(WidgetTester tester) async {
  tester.view.physicalSize = const Size(320, 640);
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.reset);
}

void main() {
  for (final locale in const [Locale('fr'), Locale('de'), Locale('ja')]) {
    testWidgets('« Lire en ligne » sur une ligne (${locale.languageCode})', (
      tester,
    ) async {
      await _smallPhone(tester);
      await tester.pumpWidget(
        _app(
          locale,
          _actionBar(
            DetailReadOnlineButton(
              hasCustomLink: true,
              onReadOnline: () {},
              onAddLink: () {},
              onOpenMenu: () {},
            ),
          ),
        ),
      );
      final l10n = lookupAppLocalizations(locale);
      expect(tester.takeException(), isNull);
      expect(tester.getSize(find.text(l10n.readOnline)).height, lessThan(30));
    });

    testWidgets('« Ajouter un lien » sur une ligne (${locale.languageCode})', (
      tester,
    ) async {
      await _smallPhone(tester);
      await tester.pumpWidget(
        _app(
          locale,
          _actionBar(
            DetailReadOnlineButton(
              hasCustomLink: false,
              onReadOnline: () {},
              onAddLink: () {},
              onOpenMenu: () {},
            ),
          ),
        ),
      );
      final l10n = lookupAppLocalizations(locale);
      expect(tester.takeException(), isNull);
      expect(tester.getSize(find.text(l10n.addLink)).height, lessThan(30));
    });

    testWidgets(
      '« Ajouter à la bibliothèque » sur une ligne (${locale.languageCode})',
      (tester) async {
        await _smallPhone(tester);
        await tester.pumpWidget(
          _app(
            locale,
            const Padding(
              padding: EdgeInsets.symmetric(horizontal: 16),
              child: Row(
                children: [
                  Expanded(child: DetailAddToLibraryButton(muId: 1)),
                  SizedBox(width: 56, height: 48),
                ],
              ),
            ),
          ),
        );
        final l10n = lookupAppLocalizations(locale);
        expect(tester.takeException(), isNull);
        expect(
          tester.getSize(find.text(l10n.addToLibrary)).height,
          lessThan(30),
        );
      },
    );
  }

  testWidgets('lecteur hors ligne : le numéro de chapitre reste visible', (
    tester,
  ) async {
    await _smallPhone(tester);
    await tester.pumpWidget(
      MaterialApp(
        locale: const Locale('fr'),
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        home: Scaffold(
          appBar: AppBar(
            title: const ReaderChapterTitle(
              mangaTitle:
                  'Un titre extrêmement long qui ne tient jamais en entier',
              chapterNumber: 1234,
            ),
            actions: [
              IconButton(onPressed: () {}, icon: const Icon(Icons.arrow_back)),
              IconButton(
                onPressed: () {},
                icon: const Icon(Icons.arrow_forward),
              ),
            ],
          ),
        ),
      ),
    );
    expect(tester.takeException(), isNull);
    expect(find.text('Chapitre 1234'), findsOneWidget);
  });
}
