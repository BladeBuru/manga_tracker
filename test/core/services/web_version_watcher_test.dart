import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mangatracker/core/components/web_update_banner.dart';
import 'package:mangatracker/core/services/web_version_watcher.dart';
import 'package:mangatracker/l10n/app_localizations.dart';

/// Web : « Une nouvelle version est disponible — Recharger ».
void main() {
  group('WebVersionWatcher', () {
    test('version servie différente de la version compilée → mise à jour',
        () async {
      final watcher = WebVersionWatcher(
        runningVersion: '0.18.1+34',
        fetchDeployedVersion: () async => '0.19.0+35',
      );
      await watcher.check();
      expect(watcher.updateAvailable.value, isTrue);
    });

    test('même version : rien', () async {
      final watcher = WebVersionWatcher(
        runningVersion: '0.18.1+34',
        fetchDeployedVersion: () async => '0.18.1+34',
      );
      await watcher.check();
      expect(watcher.updateAvailable.value, isFalse);
    });

    test('sans version compilée : la première lue sert de référence',
        () async {
      var served = '0.18.1+34';
      var now = DateTime(2026, 10, 13, 12);
      final watcher = WebVersionWatcher(
        runningVersion: '',
        fetchDeployedVersion: () async => served,
        clock: () => now,
      );
      await watcher.check();
      expect(watcher.updateAvailable.value, isFalse);

      served = '0.19.0+35';
      await watcher.check(); // trop tôt : ignoré
      expect(watcher.updateAvailable.value, isFalse);

      now = now.add(const Duration(minutes: 2));
      await watcher.check();
      expect(watcher.updateAvailable.value, isTrue);
    });

    test('hors ligne : aucune alerte', () async {
      final watcher = WebVersionWatcher(
        runningVersion: '0.18.1+34',
        fetchDeployedVersion: () async => null,
      );
      await watcher.check();
      expect(watcher.updateAvailable.value, isFalse);
    });

    test('lecture de version.json (format flutter build web)', () {
      expect(
        WebVersionWatcher.parseVersionJson(
          '{"app_name":"mangatracker","version":"0.18.1","build_number":"34","package_name":"mangatracker"}',
        ),
        '0.18.1+34',
      );
      expect(WebVersionWatcher.parseVersionJson('{"version":"1.0.0"}'), '1.0.0');
      expect(WebVersionWatcher.parseVersionJson('[]'), isNull);
    });
  });

  testWidgets('bandeau : apparaît, recharge, se ferme', (tester) async {
    final watcher = WebVersionWatcher(
      runningVersion: '0.18.1+34',
      fetchDeployedVersion: () async => '0.19.0+35',
    );
    addTearDown(watcher.dispose);
    var reloads = 0;
    await tester.pumpWidget(MaterialApp(
      locale: const Locale('fr'),
      localizationsDelegates: const [
        AppLocalizations.delegate,
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      supportedLocales: const [Locale('fr')],
      builder: (context, child) => WebUpdateBanner(
        watcher: watcher,
        onReload: () => reloads++,
        child: child!,
      ),
      home: const Scaffold(body: Text('app')),
    ));
    await tester.pumpAndSettle();

    expect(
      find.text("Une nouvelle version de l'application est disponible."),
      findsOneWidget,
    );
    expect(find.text('app'), findsOneWidget, reason: 'non bloquant');
    await tester.tap(find.text('Recharger'));
    expect(reloads, 1);

    await tester.tap(find.byIcon(Icons.close_outlined));
    await tester.pumpAndSettle();
    expect(find.text('Recharger'), findsNothing);
  });
}
