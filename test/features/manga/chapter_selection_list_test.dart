import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mangatracker/features/manga/widgets/chapter_selection_list.dart';
import 'package:mangatracker/l10n/app_localizations.dart';

/// Tient la sélection comme le fait ChapterDownloadDialog.
class _Harness extends StatefulWidget {
  const _Harness({required this.downloaded});

  final Set<int> downloaded;

  @override
  State<_Harness> createState() => _HarnessState();
}

class _HarnessState extends State<_Harness> {
  Set<int> selected = {};

  @override
  Widget build(BuildContext context) {
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
        body: SizedBox(
          height: 560, // 10 lignes de 56
          child: ChapterSelectionList(
            totalChapters: 300,
            readChapters: 200,
            downloaded: widget.downloaded,
            selected: selected,
            onSelectionChanged: (s) => setState(() => selected = s),
            onAnchor: (_) {},
          ),
        ),
      ),
    );
  }
}

void main() {
  Future<_HarnessState> pump(WidgetTester tester,
      {Set<int> downloaded = const {}}) async {
    await tester.pumpWidget(_Harness(downloaded: downloaded));
    await tester.pumpAndSettle();
    return tester.state<_HarnessState>(find.byType(_Harness));
  }

  Finder row(int chapter) => find.text('Chapitre $chapter');

  testWidgets('s\'ouvre sur le premier chapitre non lu, le précédent marqué « Lu »',
      (tester) async {
    await pump(tester);
    expect(row(201), findsOneWidget);
    expect(row(200), findsOneWidget);
    expect(row(1), findsNothing, reason: 'Plus besoin de descendre depuis le 1.');
    expect(find.text('Lu'), findsOneWidget, reason: 'Seul le 200 visible est lu.');
  });

  testWidgets('appui : coche puis décoche', (tester) async {
    final state = await pump(tester);
    await tester.tap(row(202));
    await tester.pump();
    expect(state.selected, {202});
    await tester.tap(row(202));
    await tester.pump();
    expect(state.selected, isEmpty);
  });

  testWidgets('appui long : tout l\'intervalle depuis le dernier coché, '
      'sans les chapitres déjà téléchargés', (tester) async {
    final state = await pump(tester, downloaded: {203});
    await tester.tap(row(201));
    await tester.pump();
    await tester.longPress(row(205));
    await tester.pumpAndSettle();
    expect(state.selected, {201, 202, 204, 205});
  });

  testWidgets('appui long puis glisser : coche en continu', (tester) async {
    final state = await pump(tester);
    final gesture =
        await tester.startGesture(tester.getCenter(row(202)), kind: PointerDeviceKind.touch);
    await tester.pump(kLongPressTimeout + const Duration(milliseconds: 50));
    await gesture.moveBy(const Offset(0, ChapterSelectionList.itemExtent * 3));
    await tester.pump();
    await gesture.up();
    await tester.pumpAndSettle();
    expect(state.selected, {202, 203, 204, 205});
  });

  testWidgets('un chapitre déjà téléchargé est marqué et ne se coche pas',
      (tester) async {
    final state = await pump(tester, downloaded: {204});
    expect(find.byIcon(Icons.offline_pin_outlined), findsOneWidget);
    await tester.tap(row(204));
    await tester.pump();
    expect(state.selected, isEmpty);
  });
}
