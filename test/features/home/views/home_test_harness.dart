import 'package:bloc/bloc.dart';
import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:mangatracker/core/services/connectivity_service.dart';
import 'package:mangatracker/features/home/bloc/homepage_bloc.dart';
import 'package:mangatracker/features/home/bloc/homepage_event.dart';
import 'package:mangatracker/features/home/bloc/homepage_state.dart';
import 'package:mangatracker/features/home/services/home_sections.service.dart';
import 'package:mangatracker/l10n/app_localizations.dart';
import 'package:mocktail/mocktail.dart';

class MockHomeSectionsService extends Mock implements HomeSectionsService {}

class MockConnectivityService extends Mock implements ConnectivityService {}

/// `HomePageBloc` de substitution : un vrai `Bloc` (stream, etat) sans les
/// services derriere. Absorbe tous les evenements de la vue et expose un
/// etat de depart choisi par le test.
class FakeHomePageBloc extends Bloc<HomePageEvent, HomePageState>
    implements HomePageBloc {
  final List<HomePageEvent> received = [];

  FakeHomePageBloc(super.initial) {
    on<HomePageEvent>((event, _) => received.add(event));
  }
}

/// Etat « accueil charge » minimal : utilisateur verifie, aucune reco.
const HomePageLoaded loadedHomeState = HomePageLoaded(
  popularMangas: [],
  newMangas: [],
  trendingMangas: [],
  user: null,
);

const List<LocalizationsDelegate<dynamic>> testLocalizationDelegates = [
  AppLocalizations.delegate,
  GlobalMaterialLocalizations.delegate,
  GlobalWidgetsLocalizations.delegate,
  GlobalCupertinoLocalizations.delegate,
];

/// Application de test en francais, avec un routeur minimal : la page sous
/// test a `/home`, et une page temoin pour chaque destination attendue.
Widget frRouterHarness({
  required Widget home,
  Map<String, Widget Function(GoRouterState state)> extraRoutes = const {},
}) {
  final router = GoRouter(
    initialLocation: '/home',
    routes: [
      GoRoute(path: '/home', builder: (_, __) => home),
      for (final entry in extraRoutes.entries)
        GoRoute(path: entry.key, builder: (_, state) => entry.value(state)),
    ],
  );
  return MaterialApp.router(
    locale: const Locale('fr'),
    localizationsDelegates: testLocalizationDelegates,
    supportedLocales: AppLocalizations.supportedLocales,
    routerConfig: router,
  );
}

/// Viewport de test : les slivers sont paresseux, une fenetre haute permet
/// de verifier toutes les sections sans defiler.
void useTallViewport(WidgetTester tester, {Size size = const Size(800, 4200)}) {
  tester.view.physicalSize = size;
  tester.view.devicePixelRatio = 1.0;
  addTearDown(() {
    tester.view.resetPhysicalSize();
    tester.view.resetDevicePixelRatio();
  });
}

/// Les covers passent par `CachedNetworkImage` dont le placeholder est anime
/// en boucle : `pumpAndSettle` ne converge jamais. On pompe a la main.
Future<void> pumpFrames(WidgetTester tester, {int frames = 6}) async {
  for (var i = 0; i < frames; i++) {
    await tester.pump(const Duration(milliseconds: 50));
  }
}
