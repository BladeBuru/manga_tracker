import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mangatracker/core/service_locator/service_locator.dart';
import 'package:mangatracker/core/services/library_index_service.dart';
import 'package:mangatracker/core/services/offline_cache_service.dart';
import 'package:mangatracker/features/home/bloc/home_section_page_bloc.dart';
import 'package:mangatracker/features/home/bloc/home_section_page_state.dart';
import 'package:mangatracker/features/home/dto/home_section.dto.dart';
import 'package:mangatracker/features/home/dto/home_section_kind.dart';
import 'package:mangatracker/features/home/helpers/home_layout_metrics.dart';
import 'package:mangatracker/features/home/widgets/home_section_carousel.dart';
import 'package:mangatracker/features/manga/dto/manga_quick_view.dto.dart';
import 'package:mangatracker/features/manga/widgets/manga_card.dart';
import 'package:mocktail/mocktail.dart';

import 'home_test_harness.dart';

class MockOfflineCacheService extends Mock implements OfflineCacheService {}

MangaQuickViewDto manga(num muId) => MangaQuickViewDto(
      muId: muId,
      title: 'Titre $muId',
      year: '2014',
      rating: '8.0',
    );

HomeSectionsPageDto pageDto(int page, List<MangaQuickViewDto> items,
        {int limit = 4, int total = 0}) =>
    HomeSectionsPageDto(
      id: 'year:2014',
      kind: HomeSectionKind.year,
      params: const HomeSectionParams(year: 2014),
      page: page,
      limit: limit,
      total: total,
      items: items,
    );

/// Carrousel de l'accueil : le defilement horizontal charge la suite, ne
/// reboucle pas sur une page vide, reste inerte hors ligne, et signale les
/// titres deja presents dans la bibliotheque.
void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late MockHomeSectionsService service;
  late HomeSectionPageBloc bloc;

  setUpAll(() {
    dotenv.testLoad(fileInput: 'MT_API_URL=https://api.test');
  });

  setUp(() async {
    await getIt.reset();
    service = MockHomeSectionsService();
  });

  tearDown(() async => getIt.reset());

  /// Ecran etroit : quatre cartes debordent a peine, un seul geste suffit
  /// donc a arriver assez pres de la fin pour declencher la suite.
  void useNarrowViewport(WidgetTester tester) {
    tester.view.physicalSize = const Size(400, 900);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(() {
      tester.view.resetPhysicalSize();
      tester.view.resetDevicePixelRatio();
    });
  }

  HomeSectionDto section(List<MangaQuickViewDto> items) => HomeSectionDto(
        id: 'year:2014',
        kind: HomeSectionKind.year,
        params: const HomeSectionParams(year: 2014),
        items: items,
      );

  /// Le BLoC est cree DANS le corps du test (zone FakeAsync), comme pour la
  /// page « Tout voir » : sinon ses emissions ne sont jamais delivrees au
  /// `BlocBuilder` entre deux `pump`.
  Widget carousel({
    required List<MangaQuickViewDto> items,
    bool isOffline = false,
  }) {
    bloc =
        HomeSectionPageBloc(sectionId: 'year:2014', limit: 4, service: service);
    addTearDown(bloc.close);
    return Scaffold(
      body: Align(
        alignment: Alignment.topLeft,
        child: HomeSectionCarousel(
          section: section(items),
          metrics: HomeLayoutMetrics.of(400),
          isOffline: isOffline,
          bloc: bloc,
        ),
      ),
    );
  }

  Future<void> scrollToEnd(WidgetTester tester) async {
    await tester.drag(find.byType(HomeSectionCarousel), const Offset(-400, 0));
    await pumpFrames(tester);
  }

  final fourItems = [manga(1), manga(2), manga(3), manga(4)];

  testWidgets('le defilement charge la page suivante et la met a la suite',
      (tester) async {
    useNarrowViewport(tester);
    when(() => service.fetchSectionPage(any(),
            page: 2, limit: any(named: 'limit')))
        .thenAnswer((_) async => pageDto(2, [manga(5), manga(6)]));

    await tester.pumpWidget(frRouterHarness(home: carousel(items: fourItems)));
    await pumpFrames(tester);
    expect(find.byType(MangaCard), findsWidgets);

    await scrollToEnd(tester);

    verify(() => service.fetchSectionPage('year:2014', page: 2, limit: 4))
        .called(1);
    // Rendu paresseux : la source de verite du carrousel est l etat du BLoC.
    final state = bloc.state as HomeSectionPageLoaded;
    expect(state.items.map((m) => m.muId), [1, 2, 3, 4, 5, 6]);
  });

  testWidgets('un titre renvoye deux fois par le serveur reste unique',
      (tester) async {
    useNarrowViewport(tester);
    when(() => service.fetchSectionPage(any(),
            page: 2, limit: any(named: 'limit')))
        .thenAnswer((_) async => pageDto(2, [manga(4), manga(5)]));

    await tester.pumpWidget(frRouterHarness(home: carousel(items: fourItems)));
    await pumpFrames(tester);
    await scrollToEnd(tester);

    final state = bloc.state as HomeSectionPageLoaded;
    expect(state.items.map((m) => m.muId), [1, 2, 3, 4, 5]);
  });

  testWidgets('page vide : un seul appel, meme en insistant', (tester) async {
    useNarrowViewport(tester);
    when(() => service.fetchSectionPage(any(),
            page: any(named: 'page'), limit: any(named: 'limit')))
        .thenAnswer((_) async => pageDto(2, const [], total: 99));

    await tester.pumpWidget(frRouterHarness(home: carousel(items: fourItems)));
    await pumpFrames(tester);
    await scrollToEnd(tester);
    await scrollToEnd(tester);
    await scrollToEnd(tester);

    verify(() => service.fetchSectionPage(any(),
        page: any(named: 'page'), limit: any(named: 'limit'))).called(1);
    expect((bloc.state as HomeSectionPageLoaded).hasMore, isFalse);
  });

  testWidgets('hors ligne : la section reste telle quelle, aucun appel',
      (tester) async {
    useNarrowViewport(tester);

    await tester.pumpWidget(
        frRouterHarness(home: carousel(items: fourItems, isOffline: true)));
    await pumpFrames(tester);
    await scrollToEnd(tester);

    verifyNever(() => service.fetchSectionPage(any(),
        page: any(named: 'page'), limit: any(named: 'limit')));
    expect((bloc.state as HomeSectionPageLoaded).items, hasLength(4));
  });

  testWidgets('indicateur de chargement discret pendant la page suivante',
      (tester) async {
    useNarrowViewport(tester);
    final pending = Completer<HomeSectionsPageDto>();
    when(() => service.fetchSectionPage(any(),
            page: 2, limit: any(named: 'limit')))
        .thenAnswer((_) => pending.future);

    await tester.pumpWidget(frRouterHarness(home: carousel(items: fourItems)));
    await pumpFrames(tester);
    await scrollToEnd(tester);

    expect(find.byType(CircularProgressIndicator), findsOneWidget);

    // L'arrivee des elements ne doit pas faire sauter le carrousel.
    final position =
        tester.state<ScrollableState>(find.byType(Scrollable).first).position;
    final offsetBefore = position.pixels;

    pending.complete(pageDto(2, [manga(5)]));
    await pumpFrames(tester);
    expect(find.byType(CircularProgressIndicator), findsNothing);
    expect(position.pixels, offsetBefore,
        reason: 'position de defilement conservee');
  });

  testWidgets('pastille bibliotheque sur les seuls titres deja possedes',
      (tester) async {
    useNarrowViewport(tester);
    final cache = MockOfflineCacheService();
    when(() => cache.getCachedLibrary()).thenAnswer((_) async => [manga(2)]);
    getIt.registerLazySingleton<LibraryIndexService>(
        () => LibraryIndexService(cache: cache));

    await tester.pumpWidget(frRouterHarness(home: carousel(items: fourItems)));
    await pumpFrames(tester);

    expect(find.byIcon(Icons.bookmark_added_outlined), findsOneWidget);
    expect(
      find.byWidgetPredicate((w) =>
          w is Semantics &&
          w.properties.label == 'Déjà dans ma bibliothèque'),
      findsOneWidget,
      reason: 'annonce lecteur d ecran, pas seulement une couleur',
    );

    // Retrait depuis une fiche : la pastille disparait sans rechargement.
    getIt<LibraryIndexService>().setOwned(2, owned: false);
    await pumpFrames(tester);
    expect(find.byIcon(Icons.bookmark_added_outlined), findsNothing);
  });

  testWidgets('sans index de bibliotheque, les cartes restent sans pastille',
      (tester) async {
    useNarrowViewport(tester);

    await tester.pumpWidget(frRouterHarness(home: carousel(items: fourItems)));
    await pumpFrames(tester);

    expect(find.byType(MangaCard), findsWidgets);
    expect(find.byIcon(Icons.bookmark_added_outlined), findsNothing);
  });
}
