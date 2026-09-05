import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mangatracker/core/components/app_empty_state.dart';
import 'package:mangatracker/core/components/cover_badge.dart';
import 'package:mangatracker/core/components/offline_banner.dart';
import 'package:mangatracker/core/network/network_compat.dart';
import 'package:mangatracker/core/router/app_router.dart';
import 'package:mangatracker/core/service_locator/service_locator.dart';
import 'package:mangatracker/features/home/bloc/home_section_page_bloc.dart';
import 'package:mangatracker/features/home/dto/home_section.dto.dart';
import 'package:mangatracker/features/home/dto/home_section_kind.dart';
import 'package:mangatracker/features/home/services/home_sections.service.dart';
import 'package:mangatracker/features/home/views/home_section_page.dart';
import 'package:mangatracker/features/manga/dto/manga_quick_view.dto.dart';
import 'package:mangatracker/features/manga/widgets/manga_card.dart';
import 'package:mocktail/mocktail.dart';

import '../../../fixtures/fixtures.dart';
import 'home_test_harness.dart';

MangaQuickViewDto manga(num muId, {String? type}) => MangaQuickViewDto(
      muId: muId,
      title: 'Titre $muId',
      year: '2014',
      rating: '8.0',
      type: type,
    );

HomeSectionsPageDto pageDto(int page, List<MangaQuickViewDto> items,
        {int limit = 2, int total = 5}) =>
    HomeSectionsPageDto(
      id: 'year:2014',
      kind: HomeSectionKind.year,
      params: const HomeSectionParams(year: 2014),
      page: page,
      limit: limit,
      total: total,
      items: items,
    );

/// Page « Tout voir » en francais : en-tete traduit + compteur, grille de
/// cartes, scroll infini, section introuvable, repli hors ligne.
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
    when(() => service.getCachedSections()).thenAnswer((_) async => null);
  });

  tearDown(() async => getIt.reset());

  /// Le BLoC est cree DANS le corps du test : son stream doit naitre dans la
  /// zone FakeAsync de `testWidgets`, sinon ses emissions ne sont jamais
  /// delivrees au `BlocBuilder` entre deux `pump`.
  Widget page({HomeSectionExtras? extras}) {
    bloc = HomeSectionPageBloc(sectionId: 'year:2014', service: service);
    addTearDown(bloc.close);
    return HomeSectionPage(sectionId: 'year:2014', extras: extras, bloc: bloc);
  }

  const extras = HomeSectionExtras(
    kind: HomeSectionKind.year,
    params: HomeSectionParams(year: 2014),
  );

  testWidgets('en-tete traduit, compteur de titres et grille de cartes',
      (tester) async {
    useTallViewport(tester, size: const Size(800, 1600));
    when(() => service.fetchSectionPage(any(),
            page: 1, limit: any(named: 'limit')))
        .thenAnswer((_) async => HomeSectionsPageDto.fromJson(
            loadJsonFixture('home_section_page.json')));

    await tester.pumpWidget(frRouterHarness(home: page(extras: extras)));
    // Avant la reponse : le titre vient deja des extras.
    expect(find.text('Les sorties de 2014'), findsNWidgets(2));
    await pumpFrames(tester);

    expect(find.text('Les sorties de 2014'), findsNWidgets(2),
        reason: 'AppBar + en-tete de section');
    expect(find.text('5 titres'), findsOneWidget);
    expect(find.byType(MangaCard), findsNWidgets(2));
    expect(find.text('My Hero Academia'), findsOneWidget);
    expect(find.byType(CoverBadge), findsNWidgets(2));
    expect(find.text('Manga'), findsNWidgets(2));
    expect(find.text('Tout voir'), findsNothing);
  });

  testWidgets('sans extras (acces direct), le titre vient de la reponse',
      (tester) async {
    useTallViewport(tester, size: const Size(800, 1600));
    when(() => service.fetchSectionPage(any(),
            page: 1, limit: any(named: 'limit')))
        .thenAnswer((_) async => pageDto(1, [manga(1)], total: 1));

    await tester.pumpWidget(frRouterHarness(home: page()));
    expect(find.text('year:2014'), findsWidgets, reason: 'repli sur l\'id');
    await pumpFrames(tester);

    expect(find.text('Les sorties de 2014'), findsNWidgets(2));
    expect(find.text('1 titre'), findsOneWidget);
    expect(find.text('Vous avez tout vu'), findsOneWidget);
  });

  testWidgets('scroll infini : la page suivante est ajoutee a la grille',
      (tester) async {
    useTallViewport(tester, size: const Size(800, 1600));
    when(() => service.fetchSectionPage(any(),
            page: 1, limit: any(named: 'limit')))
        .thenAnswer((_) async => pageDto(1, [manga(1), manga(2)]));
    when(() => service.fetchSectionPage(any(),
            page: 2, limit: any(named: 'limit')))
        .thenAnswer((_) async => pageDto(2, [manga(3), manga(4)]));

    await tester.pumpWidget(frRouterHarness(home: page(extras: extras)));
    await pumpFrames(tester);
    expect(find.byType(MangaCard), findsNWidgets(2));

    await tester.drag(find.byType(CustomScrollView), const Offset(0, -400));
    await pumpFrames(tester);

    verify(() => service.fetchSectionPage('year:2014', page: 2, limit: 40))
        .called(1);
    expect(find.byType(MangaCard), findsNWidgets(4));
  });

  testWidgets('section inconnue (404) : etat vide traduit + retour',
      (tester) async {
    useTallViewport(tester, size: const Size(800, 1600));
    when(() => service.fetchSectionPage(any(),
            page: any(named: 'page'), limit: any(named: 'limit')))
        .thenThrow(const HomeSectionNotFoundException('year:2014'));

    await tester.pumpWidget(frRouterHarness(home: page(extras: extras)));
    await pumpFrames(tester);

    expect(find.byType(AppEmptyState), findsOneWidget);
    expect(find.text('Cette section n\'existe plus.'), findsOneWidget);
    expect(find.text('Retour'), findsOneWidget);
    expect(find.byType(MangaCard), findsNothing);
  });

  testWidgets('hors ligne : apercu du cache + bandeau, sans scroll infini',
      (tester) async {
    useTallViewport(tester, size: const Size(800, 1600));
    when(() => service.fetchSectionPage(any(),
            page: any(named: 'page'), limit: any(named: 'limit')))
        .thenThrow(const SocketException('offline'));
    when(() => service.getCachedSections()).thenAnswer((_) async =>
        HomeSectionsDto.fromJson(loadJsonFixture('home_sections.json')));

    await tester.pumpWidget(frRouterHarness(home: page(extras: extras)));
    await pumpFrames(tester);

    expect(find.byType(OfflineBanner), findsOneWidget);
    expect(find.text('My Hero Academia'), findsOneWidget);
    expect(find.text('Vous avez tout vu'), findsOneWidget);

    await tester.drag(find.byType(CustomScrollView), const Offset(0, -400));
    await pumpFrames(tester);
    verify(() => service.fetchSectionPage(any(),
        page: any(named: 'page'), limit: any(named: 'limit'))).called(1);
  });
}
