import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mangatracker/features/sharing/dto/reading_group.dto.dart';
import 'package:mangatracker/features/sharing/services/reading_group_progress_choices.dart';
import 'package:mangatracker/features/sharing/widgets/reading_group_progress_dialog.dart';
import 'package:mangatracker/l10n/app_localizations.dart';

ReadingGroupMemberDto member(int id, String name, {int? read}) =>
    ReadingGroupMemberDto(
      userId: id,
      username: name,
      readChapters: read,
      joinedAt: DateTime(2026),
    );

ReadingGroupDto groupOf(List<ReadingGroupMemberDto> members) => ReadingGroupDto(
  id: 7,
  ownerId: 1,
  mangaMuId: '151',
  mangaTitle: 'Solo Leveling',
  createdAt: DateTime(2026),
  members: members,
);

/// Ouvre la fenêtre et expose sa valeur de retour.
Future<List<int?>> pumpDialog(
  WidgetTester tester, {
  required int initial,
  List<ReadingGroupProgressTarget> targets = const [],
}) async {
  final results = <int?>[];
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
        body: Builder(
          builder: (context) => TextButton(
            onPressed: () async => results.add(
              await ReadingGroupProgressDialog.show(
                context,
                initialChapters: initial,
                targets: targets,
              ),
            ),
            child: const Text('ouvrir'),
          ),
        ),
      ),
    ),
  );
  await tester.tap(find.text('ouvrir'));
  await tester.pumpAndSettle();
  return results;
}

String fieldText(WidgetTester tester) =>
    tester.widget<TextField>(find.byType(TextField)).controller!.text;

void main() {
  group('ReadingGroupProgressChoices (pur)', () {
    final g = groupOf([
      member(1, 'moi', read: 105),
      member(2, 'Léa', read: 124),
      member(3, 'Tom', read: 110),
      member(4, 'Zoé', read: 90),
      member(5, 'Nouveau'),
    ]);

    test('ma progression d\'après le groupe, null si non identifié', () {
      expect(ReadingGroupProgressChoices.myChapters(g, 1), 105);
      expect(ReadingGroupProgressChoices.myChapters(g, null), isNull);
      expect(ReadingGroupProgressChoices.myChapters(g, 99), isNull);
    });

    test('membres en avance, du plus avancé au moins avancé, sans moi', () {
      expect(
        ReadingGroupProgressChoices.aheadOf(g, currentUserId: 1, myChapters: 105),
        const [
          ReadingGroupProgressTarget(name: 'Léa', chapter: 124),
          ReadingGroupProgressTarget(name: 'Tom', chapter: 110),
        ],
      );
    });
  });

  testWidgets('pré-remplie avec ma progression ; −/+ ajustent d\'un chapitre',
      (tester) async {
    final results = await pumpDialog(tester, initial: 105);
    expect(find.text('Ma progression'), findsOneWidget);
    expect(fieldText(tester), '105');

    await tester.tap(find.byTooltip('Un chapitre de plus'));
    await tester.tap(find.byTooltip('Un chapitre de plus'));
    await tester.pump();
    expect(fieldText(tester), '107');

    await tester.tap(find.byTooltip('Un chapitre de moins'));
    await tester.pump();
    expect(fieldText(tester), '106');

    await tester.tap(find.text('Enregistrer'));
    await tester.pumpAndSettle();
    expect(results, [106]);
  });

  testWidgets('« Me caler sur » reprend le chapitre du membre', (tester) async {
    final results = await pumpDialog(
      tester,
      initial: 105,
      targets: const [ReadingGroupProgressTarget(name: 'Léa', chapter: 124)],
    );

    await tester.tap(find.text('Me caler sur Léa (ch. 124)'));
    await tester.pump();
    expect(fieldText(tester), '124');

    await tester.tap(find.text('Enregistrer'));
    await tester.pumpAndSettle();
    expect(results, [124]);
  });

  testWidgets('saisie vide refusée, la fenêtre reste ouverte', (tester) async {
    final results = await pumpDialog(tester, initial: 3);

    await tester.enterText(find.byType(TextField), '');
    await tester.tap(find.text('Enregistrer'));
    await tester.pumpAndSettle();

    expect(find.text('Saisis un nombre entier, 0 ou plus.'), findsOneWidget);
    expect(find.text('Ma progression'), findsOneWidget);
    expect(results, isEmpty);
  });

  testWidgets('seuls les chiffres sont acceptés ; 0 est valide, pas en dessous',
      (tester) async {
    final results = await pumpDialog(tester, initial: 1);

    await tester.enterText(find.byType(TextField), '-4.5a');
    await tester.pump();
    expect(fieldText(tester), '45');

    await tester.enterText(find.byType(TextField), '0');
    await tester.pump();
    final decrease = tester.widget<IconButton>(
      find.ancestor(
        of: find.byIcon(Icons.remove_outlined),
        matching: find.byType(IconButton),
      ),
    );
    expect(decrease.onPressed, isNull, reason: 'pas de chapitre négatif');

    await tester.tap(find.text('Enregistrer'));
    await tester.pumpAndSettle();
    expect(results, [0]);
  });

  testWidgets('Annuler ne renvoie rien', (tester) async {
    final results = await pumpDialog(tester, initial: 10);

    await tester.tap(find.text('Annuler'));
    await tester.pumpAndSettle();

    expect(results, [null]);
  });
}
