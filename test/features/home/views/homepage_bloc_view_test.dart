import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mangatracker/core/components/app_error_state.dart';
import 'package:mangatracker/core/components/cover_badge.dart';
import 'package:mangatracker/core/components/offline_banner.dart';
import 'package:mangatracker/core/network/network_compat.dart';
import 'package:mangatracker/core/service_locator/service_locator.dart';
import 'package:mangatracker/features/home/bloc/home_sections_bloc.dart';
import 'package:mangatracker/features/home/dto/home_section.dto.dart';
import 'package:mangatracker/features/home/views/homepage_bloc_view.dart';
import 'package:mangatracker/features/home/widgets/home_section_tile.dart';
import 'package:mangatracker/features/home/widgets/home_sections_skeleton.dart';
import 'package:mangatracker/features/manga/widgets/manga_card.dart';
import 'package:mocktail/mocktail.dart';

import '../../../fixtures/fixtures.dart';
import 'home_test_harness.dart';

/// Rendu de l'accueil catalogue en francais : titres traduits de chaque
/// section (dans l'ordre du serveur), pastilles de type, squelettes,
/// erreur reessayable, bandeau hors ligne et navigation « Tout voir ».
void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late MockHomeSectionsService service;
  late MockConnectivityService connectivity;
  late HomeSectionsBloc sectionsBloc;
  late FakeHomePageBloc homePageBloc;
  late HomeSectionsDto fixture;

  setUpAll(() {
    dotenv.testLoad(fileInput: 'MT_API_URL=https://api.test');
  });

  setUp(() async {
    await getIt.reset();
    service = MockHomeSectionsService();
    connectivity = MockConnectivityService();
    when(() => connectivity.isConnected).thenReturn(true);
    when(() => service.getCachedSections()).thenAnswer((_) async => null);
    fixture = HomeSectionsDto.fromJson(loadJsonFixture('home_sections.json'));
  });

  tearDown(() async => getIt.reset());

  /// Les BLoCs sont crees DANS le corps du test : leurs streams doivent
  /// naitre dans la zone FakeAsync de `testWidgets`, sinon leurs emissions
  /// ne sont jamais delivrees au `BlocBuilder` entre deux `pump`.
  Widget view() {
    sectionsBloc =
        HomeSectionsBloc(service: service, connectivity: connectivity);
    homePageBloc = FakeHomePageBloc(loadedHomeState);
    addTearDown(() async {
      await sectionsBloc.close();
      await homePageBloc.close();
    });
    return HomePageBlocView(
      homePageBloc: homePageBloc,
      sectionsBloc: sectionsBloc,
    );
  }

  testWidgets('affiche les sections avec leurs titres traduits en francais',
      (tester) async {
    useTallViewport(tester);
    when(() => service.fetchSections(limit: any(named: 'limit')))
        .thenAnswer((_) async => fixture);

    await tester.pumpWidget(frRouterHarness(home: view()));
    await pumpFrames(tester);

    const expectedTitles = [
      'Dernières sorties',
      'Ce qui marche le mieux',
      'Les mieux notés',
      'Manhwa',
      'Manhua',
      'Manga',
      'Genre : Action',
      'Les sorties de 2014',
      'Le choix de la communauté',
      'Pépites cachées',
    ];
    for (final title in expectedTitles) {
      expect(find.text(title), findsWidgets, reason: 'titre « $title »');
    }
    // Ordre du serveur conserve, section vide (year:1999) et kind inconnu
    // (editorial) absents.
    final tiles = tester
        .widgetList<HomeSectionTile>(find.byType(HomeSectionTile))
        .map((t) => t.section.id)
        .toList();
    expect(tiles, [
      'latest',
      'popular',
      'top_rated',
      'type:Manhwa',
      'type:Manhua',
      'type:Manga',
      'genre:Action',
      'year:2014',
      'community',
      'hidden_gems',
    ]);
    expect(find.text('Les sorties de 1999'), findsNothing);
    // Un bouton « Tout voir » par section.
    expect(find.text('Tout voir'), findsNWidgets(10));
    // Cartes reutilisees, pastille de type sur la cover.
    expect(find.byType(MangaCard), findsWidgets);
    expect(find.byType(CoverBadge), findsWidgets);
    expect(find.text('Solo Leveling'), findsOneWidget);
    // Le compagnon (HomePageBloc) a bien ete sollicite.
    expect(homePageBloc.received, isNotEmpty);
  });

  testWidgets('affiche des squelettes tant que le catalogue charge',
      (tester) async {
    useTallViewport(tester);
    final pending = Completer<HomeSectionsDto>();
    when(() => service.fetchSections(limit: any(named: 'limit')))
        .thenAnswer((_) => pending.future);

    await tester.pumpWidget(frRouterHarness(home: view()));
    await pumpFrames(tester, frames: 2);

    expect(find.byType(HomeSectionsSkeleton), findsWidgets);
    expect(find.byType(HomeSectionTile), findsNothing);

    pending.complete(fixture);
    await pumpFrames(tester);
    expect(find.byType(HomeSectionTile), findsWidgets);
  });

  testWidgets('erreur sans cache : message traduit et bouton Reessayer',
      (tester) async {
    useTallViewport(tester);
    when(() => service.fetchSections(limit: any(named: 'limit')))
        .thenThrow(Exception('HTTP Request Failed with status: 500.'));

    await tester.pumpWidget(frRouterHarness(home: view()));
    await pumpFrames(tester);

    expect(find.byType(AppErrorState), findsOneWidget);
    expect(find.text('Impossible de charger l\'accueil pour le moment.'),
        findsOneWidget);
    expect(find.byType(OfflineBanner), findsNothing);

    when(() => service.fetchSections(limit: any(named: 'limit')))
        .thenAnswer((_) async => fixture);
    await tester.tap(find.text('Réessayer'));
    await pumpFrames(tester);

    expect(find.byType(AppErrorState), findsNothing);
    expect(find.text('Dernières sorties'), findsOneWidget);
    verify(() => service.fetchSections(limit: any(named: 'limit'))).called(2);
  });

  testWidgets('hors ligne avec cache : bandeau + sections servies du cache',
      (tester) async {
    useTallViewport(tester);
    when(() => service.getCachedSections()).thenAnswer((_) async => fixture);
    when(() => service.fetchSections(limit: any(named: 'limit')))
        .thenThrow(const SocketException('offline'));

    await tester.pumpWidget(frRouterHarness(home: view()));
    await pumpFrames(tester);

    expect(find.byType(OfflineBanner), findsOneWidget);
    expect(find.text('Mode hors ligne'), findsOneWidget);
    expect(find.text('Pépites cachées'), findsOneWidget);
  });

  testWidgets('« Tout voir » ouvre /home/section/:id avec l\'id encode',
      (tester) async {
    useTallViewport(tester);
    when(() => service.fetchSections(limit: any(named: 'limit')))
        .thenAnswer((_) async => fixture);
    await tester.pumpWidget(frRouterHarness(
      home: view(),
      extraRoutes: {
        '/home/section/:id': (state) => Scaffold(
              body: Text('section=${state.pathParameters['id']}'),
            ),
      },
    ));
    await pumpFrames(tester);

    // Quatrieme section : `type:Manhwa` (id avec « : », encode a l'appel).
    await tester.tap(find.text('Tout voir').at(3));
    await pumpFrames(tester);

    expect(find.text('section=type:Manhwa'), findsOneWidget);
  });
}
