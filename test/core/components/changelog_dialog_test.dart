import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mangatracker/core/components/changelog_dialog.dart';
import 'package:mangatracker/core/service_locator/service_locator.dart';
import 'package:mangatracker/core/services/app_update_service.dart';
import 'package:mangatracker/core/services/translation_service.dart';
import 'package:mangatracker/l10n/app_localizations.dart';

ChangelogInfo _changelog() => ChangelogInfo([
      VersionChanges(
        version: '1.2.3+4',
        notes: ['Première note', 'Seconde note'],
      ),
    ]);

/// Ouvre la dialog via `ChangelogDialog.show` dans une app localisée.
Future<void> _pumpDialog(
  WidgetTester tester, {
  required Locale locale,
  VoidCallback? onClose,
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
          body: TextButton(
            onPressed: () =>
                ChangelogDialog.show(context, _changelog(), onClose: onClose),
            child: const Text('open'),
          ),
        ),
      ),
    ),
  );
  await tester.tap(find.text('open'));
  await tester.pumpAndSettle();
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() async {
    await getIt.reset();
    // Le dialog resout TranslationService a la construction de son State.
    // LanguageService volontairement absent : la traduction automatique des
    // notes ne demarre pas (echec silencieux), ce qui garde le test hors reseau.
    getIt.registerSingleton<TranslationService>(TranslationService());
  });

  tearDown(() async {
    await getIt.reset();
  });

  testWidgets('en anglais, le titre et le bouton de fermeture sont traduits',
      (tester) async {
    await _pumpDialog(tester, locale: const Locale('en'));

    expect(find.text("What's new?"), findsOneWidget);
    expect(find.text('Great!'), findsOneWidget);
    expect(find.text('Quoi de neuf ?'), findsNothing);
    expect(find.text('Super !'), findsNothing);
  });

  testWidgets('en francais (langue de reference), les libelles sont inchanges',
      (tester) async {
    await _pumpDialog(tester, locale: const Locale('fr'));

    expect(find.text('Quoi de neuf ?'), findsOneWidget);
    expect(find.text('Super !'), findsOneWidget);
  });

  testWidgets('le bouton traduit ferme la dialog et notifie onClose',
      (tester) async {
    var closed = 0;
    await _pumpDialog(
      tester,
      locale: const Locale('en'),
      onClose: () => closed++,
    );

    await tester.tap(find.text('Great!'));
    await tester.pumpAndSettle();

    expect(find.byType(ChangelogDialog), findsNothing);
    expect(closed, 1);
  });
}
