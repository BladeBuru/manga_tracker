import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:mangatracker/core/router/navigation_helpers.dart';
import 'package:mangatracker/core/router/route_extras.dart';
import 'package:mangatracker/core/router/route_extras_codec.dart';
import 'package:mangatracker/core/router/web_history/history_aware_route_information_provider.dart';

/// Historique de navigateur simulé : reçoit ce que le framework signale
/// (`routeInformationUpdated`), et renvoie un `popstate`
/// (`pushRouteInformation`) quand on recule / avance, comme le moteur web.
class _FakeBrowser extends BrowserHistoryBridge {
  _FakeBrowser(this.tester);

  final WidgetTester tester;
  final List<Map<String, Object?>> entries = [];
  int index = -1;
  int pushes = 0;
  int replaces = 0;
  int goCalls = 0;

  String get location => entries[index]['uri']! as String;

  Future<Object?> onNavigation(MethodCall call) async {
    if (call.method != 'routeInformationUpdated') return null;
    final args = Map<String, Object?>.from(call.arguments as Map);
    final entry = {'uri': args['uri'], 'state': args['state']};
    if (args['replace'] == true && index >= 0) {
      entries[index] = entry;
      replaces++;
    } else {
      entries.removeRange(index + 1, entries.length);
      entries.add(entry);
      index++;
      pushes++;
    }
    return null;
  }

  @override
  int? serialCount() => index;

  @override
  void go(int delta) {
    goCalls++;
    index += delta;
    // Le navigateur traite le retour de façon asynchrone.
    scheduleMicrotask(_popState);
  }

  /// Bouton retour / avance du navigateur.
  Future<void> browserGo(int delta) async {
    index += delta;
    await _popState();
  }

  Future<void> _popState() async {
    final entry = entries[index];
    final message = const JSONMethodCodec().encodeMethodCall(
      MethodCall('pushRouteInformation', {
        'location': entry['uri'],
        'state': entry['state'],
      }),
    );
    await tester.binding.defaultBinaryMessenger.handlePlatformMessage(
      'flutter/navigation',
      message,
      (_) {},
    );
  }
}

class _Page extends StatelessWidget {
  final String name;
  const _Page(this.name);

  @override
  Widget build(BuildContext context) => Scaffold(
        appBar: AppBar(title: Text(name)),
        body: Center(
          child: ElevatedButton(
            onPressed: () => popOrGo(context, fallback: '/home'),
            child: Text('back-$name'),
          ),
        ),
      );
}

void main() {
  late GoRouter router;
  late _FakeBrowser browser;
  var blocked = false;

  setUp(() {
    GoRouter.optionURLReflectsImperativeAPIs = true;
    blocked = false;
  });
  tearDown(() => GoRouter.optionURLReflectsImperativeAPIs = false);

  Future<void> pumpApp(WidgetTester tester, {String initial = '/home'}) async {
    browser = _FakeBrowser(tester);
    tester.binding.defaultBinaryMessenger
        .setMockMethodCallHandler(SystemChannels.navigation, browser.onNavigation);
    addTearDown(() => tester.binding.defaultBinaryMessenger
        .setMockMethodCallHandler(SystemChannels.navigation, null));
    router = GoRouter(
      initialLocation: initial,
      extraCodec: const RouteExtrasCodec(),
      // Comme le garde d'auth : session perdue → tout sauf /login renvoie
      // à /login (sur une restauration, go_router évalue la racine de pile).
      redirect: (context, state) =>
          blocked && state.uri.path != '/login' ? '/login' : null,
      routes: [
        for (final name in ['home', 'a', 'b', 'login'])
          GoRoute(path: '/$name', builder: (_, __) => _Page(name)),
      ],
    );
    addTearDown(router.dispose);
    final provider = HistoryAwareRouteInformationProvider(
      router,
      enabled: true,
      bridge: browser,
    );
    await tester.pumpWidget(MaterialApp.router(
      routerConfig: RouterConfig<RouteMatchList>(
        routeInformationProvider: provider,
        routeInformationParser: router.routeInformationParser,
        routerDelegate: router.routerDelegate,
        backButtonDispatcher: router.backButtonDispatcher,
      ),
    ));
    await tester.pumpAndSettle();
  }

  testWidgets('chaque page empilée a son URL', (tester) async {
    await pumpApp(tester);
    router.push('/a');
    await tester.pumpAndSettle();
    expect(browser.location, '/a');
    expect(browser.entries.length, 2);
  });

  testWidgets(
      'retour dans l\'app = vrai retour du navigateur, sans doublon en avant',
      (tester) async {
    await pumpApp(tester);
    router.push('/a');
    await tester.pumpAndSettle();
    final result = router.push<bool>('/b');
    await tester.pumpAndSettle();
    expect(browser.entries.length, 3);

    router.pop(true);
    await tester.pumpAndSettle();

    expect(browser.goCalls, 1, reason: 'history.go(-1) au lieu d\'un push');
    expect(browser.index, 1);
    expect(browser.location, '/a');
    expect(browser.entries.length, 3, reason: '/b reste « en avant »');
    expect(await result, isTrue, reason: 'le résultat du pop est transmis');
    expect(find.text('a'), findsOneWidget);
  });

  testWidgets(
      'après un retour, le await push(...) de la page restante aboutit encore',
      (tester) async {
    await pumpApp(tester);
    final aResult = router.push<bool>('/a');
    await tester.pumpAndSettle();
    router.push('/b');
    await tester.pumpAndSettle();
    router.pop();
    await tester.pumpAndSettle();

    var done = false;
    unawaited(aResult.then((_) => done = true));
    router.pop(true);
    await tester.pumpAndSettle();
    expect(done, isTrue);
    expect(await aResult, isTrue);
    expect(browser.location, '/home');
  });

  testWidgets('bouton retour du navigateur : le await push(...) se termine',
      (tester) async {
    await pumpApp(tester);
    final result = router.push<bool>('/a');
    await tester.pumpAndSettle();

    await browser.browserGo(-1);
    await tester.pumpAndSettle();

    expect(find.text('home'), findsOneWidget);
    expect(await result, isNull);
  });

  testWidgets(
      'retour du navigateur vers une page interdite : entrée remplacée',
      (tester) async {
    await pumpApp(tester);
    router.push('/a');
    await tester.pumpAndSettle();
    router.push('/b');
    await tester.pumpAndSettle();
    blocked = true;
    final pushesBefore = browser.pushes;

    await browser.browserGo(-1);
    await tester.pumpAndSettle();

    expect(find.text('login'), findsOneWidget);
    expect(browser.pushes, pushesBefore, reason: 'aucune entrée ajoutée');
    expect(browser.location, '/login');
    expect(browser.entries.length, 3, reason: 'pas de piège sur /login');
  });

  testWidgets('les extras survivent au retour du navigateur', (tester) async {
    await pumpApp(tester);
    router.push('/a', extra: const MangaDetailExtras(title: 'Berserk'));
    await tester.pumpAndSettle();
    router.push('/b');
    await tester.pumpAndSettle();
    await browser.browserGo(-1);
    await tester.pumpAndSettle();
    final extra = router.routerDelegate.currentConfiguration.last
        .buildState(router.configuration, router.routerDelegate.currentConfiguration)
        .extra;
    expect(extra, isA<MangaDetailExtras>());
    expect((extra! as MangaDetailExtras).title, 'Berserk');
  });

  testWidgets('popOrGo : retour s\'il y a une page dessous, sinon le repli',
      (tester) async {
    await pumpApp(tester, initial: '/a');
    // Lien direct : rien à dépiler.
    await tester.tap(find.text('back-a'));
    await tester.pumpAndSettle();
    expect(find.text('home'), findsOneWidget);

    router.push('/b');
    await tester.pumpAndSettle();
    await tester.tap(find.text('back-b'));
    await tester.pumpAndSettle();
    expect(find.text('home'), findsOneWidget);
    expect(router.canPop(), isFalse);
  });
}
