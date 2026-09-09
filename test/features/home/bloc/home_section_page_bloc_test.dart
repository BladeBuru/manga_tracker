import 'package:flutter_test/flutter_test.dart';
import 'package:mangatracker/core/network/network_compat.dart';
import 'package:mangatracker/features/auth/exceptions/invalid_credentials.exception.dart';
import 'package:mangatracker/features/home/bloc/home_section_page_bloc.dart';
import 'package:mangatracker/features/home/bloc/home_section_page_event.dart';
import 'package:mangatracker/features/home/bloc/home_section_page_state.dart';
import 'package:mangatracker/features/home/dto/home_section.dto.dart';
import 'package:mangatracker/features/home/dto/home_section_kind.dart';
import 'package:mangatracker/features/home/services/home_sections.service.dart';
import 'package:mangatracker/features/manga/dto/manga_quick_view.dto.dart';
import 'package:mocktail/mocktail.dart';

import '../../../fixtures/fixtures.dart';

class MockHomeSectionsService extends Mock implements HomeSectionsService {}

MangaQuickViewDto manga(num muId) => MangaQuickViewDto(
      muId: muId,
      title: 'Manga $muId',
      year: '2014',
      rating: '8',
    );

HomeSectionsPageDto pageDto({
  required int page,
  required List<MangaQuickViewDto> items,
  int limit = 2,
  int total = 5,
}) =>
    HomeSectionsPageDto(
      id: 'year:2014',
      kind: HomeSectionKind.year,
      params: const HomeSectionParams(year: 2014),
      page: page,
      limit: limit,
      total: total,
      items: items,
    );

/// Page « Tout voir » : premiere page, scroll infini (append + dedup), fin de
/// liste, 404, et repli hors ligne sur l'apercu du cache de l'accueil.
void main() {
  late MockHomeSectionsService service;

  HomeSectionPageBloc buildBloc([String id = 'year:2014']) =>
      HomeSectionPageBloc(sectionId: id, service: service);

  setUp(() {
    service = MockHomeSectionsService();
    when(() => service.getCachedSections()).thenAnswer((_) async => null);
  });

  void stubPage(int page, HomeSectionsPageDto dto) => when(
        () => service.fetchSectionPage(any(),
            page: page, limit: any(named: 'limit')),
      ).thenAnswer((_) async => dto);

  test('LoadSectionPage : Loading puis Loaded avec la premiere page', () async {
    stubPage(
      1,
      HomeSectionsPageDto.fromJson(loadJsonFixture('home_section_page.json')),
    );
    final bloc = buildBloc();
    addTearDown(bloc.close);

    final expectation = expectLater(
      bloc.stream,
      emitsInOrder([
        const HomeSectionPageLoading(),
        isA<HomeSectionPageLoaded>()
            .having((s) => s.kind, 'kind', HomeSectionKind.year)
            .having((s) => s.params.year, 'year', 2014)
            .having((s) => s.items.length, 'items', 2)
            .having((s) => s.total, 'total', 5)
            .having((s) => s.hasMore, 'hasMore', true)
            .having((s) => s.isOffline, 'isOffline', false),
      ]),
    );
    bloc.add(const LoadSectionPage());
    await expectation;
    verify(() => service.fetchSectionPage('year:2014', page: 1, limit: 40))
        .called(1);
  });

  test('LoadMoreSectionPage : ajoute la page suivante, dedoublonne, puis fin',
      () async {
    stubPage(1, pageDto(page: 1, items: [manga(1), manga(2)]));
    // Le serveur a insere un titre : le 2 glisse en page 2 → ignore.
    stubPage(2, pageDto(page: 2, items: [manga(2), manga(3)]));
    stubPage(3, pageDto(page: 3, items: [manga(4)]));
    final bloc = buildBloc();
    addTearDown(bloc.close);

    bloc.add(const LoadSectionPage());
    await bloc.stream.firstWhere((s) => s is HomeSectionPageLoaded);

    bloc.add(const LoadMoreSectionPage());
    var state = await bloc.stream.firstWhere(
      (s) => s is HomeSectionPageLoaded && !s.isLoadingMore && s.page == 2,
    ) as HomeSectionPageLoaded;
    expect(state.items.map((m) => m.muId), [1, 2, 3]);
    expect(state.hasMore, isTrue);

    bloc.add(const LoadMoreSectionPage());
    state = await bloc.stream.firstWhere(
      (s) => s is HomeSectionPageLoaded && !s.isLoadingMore && s.page == 3,
    ) as HomeSectionPageLoaded;
    expect(state.items.map((m) => m.muId), [1, 2, 3, 4]);
    expect(state.hasMore, isFalse, reason: '3 × 2 ≥ total 5');

    // Plus rien a charger : aucun appel supplementaire.
    bloc.add(const LoadMoreSectionPage());
    await Future<void>.delayed(const Duration(milliseconds: 20));
    verifyNever(() => service.fetchSectionPage(any(),
        page: 4, limit: any(named: 'limit')));
  });

  test('LoadMoreSectionPage en echec : loadMoreFailed, donnees conservees',
      () async {
    stubPage(1, pageDto(page: 1, items: [manga(1), manga(2)]));
    when(() => service.fetchSectionPage(any(),
            page: 2, limit: any(named: 'limit')))
        .thenThrow(const SocketException('offline'));
    final bloc = buildBloc();
    addTearDown(bloc.close);

    bloc.add(const LoadSectionPage());
    await bloc.stream.firstWhere((s) => s is HomeSectionPageLoaded);
    bloc.add(const LoadMoreSectionPage());
    final state = await bloc.stream.firstWhere(
      (s) => s is HomeSectionPageLoaded && s.loadMoreFailed,
    ) as HomeSectionPageLoaded;

    expect(state.items, hasLength(2));
    expect(state.isLoadingMore, isFalse);
    expect(state.isOffline, isTrue, reason: 're-evalue a chaque echec');
  });

  test('404 → HomeSectionPageError.notFound', () async {
    when(() => service.fetchSectionPage(any(),
            page: any(named: 'page'), limit: any(named: 'limit')))
        .thenThrow(const HomeSectionNotFoundException('type:Novel'));
    final bloc = buildBloc('type:Novel');
    addTearDown(bloc.close);

    bloc.add(const LoadSectionPage());
    final state =
        await bloc.stream.firstWhere((s) => s is HomeSectionPageError);
    expect((state as HomeSectionPageError).notFound, isTrue);
    expect(state.isOffline, isFalse);
  });

  test('hors ligne : repli sur l\'apercu du cache de l\'accueil, sans pagination',
      () async {
    when(() => service.fetchSectionPage(any(),
            page: any(named: 'page'), limit: any(named: 'limit')))
        .thenThrow(const SocketException('offline'));
    when(() => service.getCachedSections()).thenAnswer(
      (_) async =>
          HomeSectionsDto.fromJson(loadJsonFixture('home_sections.json')),
    );
    final bloc = buildBloc();
    addTearDown(bloc.close);

    bloc.add(const LoadSectionPage());
    final state = await bloc.stream
        .firstWhere((s) => s is HomeSectionPageLoaded) as HomeSectionPageLoaded;

    expect(state.isOffline, isTrue);
    expect(state.kind, HomeSectionKind.year);
    expect(state.items.map((m) => m.muId), [601]);
    expect(state.hasMore, isFalse);

    // Hors ligne, le scroll infini reste inerte.
    bloc.add(const LoadMoreSectionPage());
    await Future<void>.delayed(const Duration(milliseconds: 20));
    verify(() => service.fetchSectionPage(any(),
        page: any(named: 'page'), limit: any(named: 'limit'))).called(1);
  });

  test('session rejetee + cache → servi avec invite, pas hors ligne', () async {
    when(() => service.fetchSectionPage(any(),
            page: any(named: 'page'), limit: any(named: 'limit')))
        .thenThrow(InvalidCredentialsException('rejected'));
    when(() => service.getCachedSections()).thenAnswer(
      (_) async =>
          HomeSectionsDto.fromJson(loadJsonFixture('home_sections.json')),
    );
    final bloc = buildBloc('latest');
    addTearDown(bloc.close);

    bloc.add(const LoadSectionPage());
    final state = await bloc.stream
        .firstWhere((s) => s is HomeSectionPageLoaded) as HomeSectionPageLoaded;
    expect(state.requiresReauth, isTrue);
    expect(state.isOffline, isFalse);
    expect(state.items, hasLength(2));
  });

  test('hors ligne sans cache pour cette section → Error hors ligne', () async {
    when(() => service.fetchSectionPage(any(),
            page: any(named: 'page'), limit: any(named: 'limit')))
        .thenThrow(const SocketException('offline'));
    when(() => service.getCachedSections()).thenAnswer(
      (_) async =>
          HomeSectionsDto.fromJson(loadJsonFixture('home_sections.json')),
    );
    final bloc = buildBloc('genre:Romance');
    addTearDown(bloc.close);

    bloc.add(const LoadSectionPage());
    final state =
        await bloc.stream.firstWhere((s) => s is HomeSectionPageError);
    expect(state.isOffline, isTrue);
    expect((state as HomeSectionPageError).notFound, isFalse);
  });

  test('RefreshSectionPage : repart de la page 1 sans passer par Loading',
      () async {
    stubPage(1, pageDto(page: 1, items: [manga(1), manga(2)]));
    final bloc = buildBloc();
    addTearDown(bloc.close);
    bloc.add(const LoadSectionPage());
    await bloc.stream.firstWhere((s) => s is HomeSectionPageLoaded);

    stubPage(1, pageDto(page: 1, items: [manga(9), manga(8)]));
    final expectation = expectLater(
      bloc.stream,
      emits(isA<HomeSectionPageLoaded>()
          .having((s) => s.items.map((m) => m.muId).toList(), 'items', [9, 8])),
    );
    bloc.add(const RefreshSectionPage());
    await expectation;
  });

  // ─────────────────────────────────────────────────────────────────────────
  // Amorce par un apercu deja affiche (carrousel de l'accueil) : c'est ce qui
  // permet de ne PAS ecrire une seconde pagination pour le carrousel.
  // ─────────────────────────────────────────────────────────────────────────

  test('SeedSectionPage : apercu plein → page 1 posee, aucune requete',
      () async {
    final bloc = HomeSectionPageBloc(
        sectionId: 'year:2014', limit: 2, service: service);
    addTearDown(bloc.close);

    bloc.add(SeedSectionPage(
      kind: HomeSectionKind.year,
      params: const HomeSectionParams(year: 2014),
      items: [manga(1), manga(2)],
    ));
    final state = await bloc.stream.firstWhere((s) => s is HomeSectionPageLoaded)
        as HomeSectionPageLoaded;

    expect(state.items.map((m) => m.muId), [1, 2]);
    expect(state.page, 1);
    expect(state.hasMore, isTrue, reason: 'apercu plein → il y a une suite');
    verifyNever(() => service.fetchSectionPage(any(),
        page: any(named: 'page'), limit: any(named: 'limit')));
  });

  test('SeedSectionPage : apercu incomplet → pagination fermee', () async {
    final bloc = HomeSectionPageBloc(
        sectionId: 'year:2014', limit: 20, service: service);
    addTearDown(bloc.close);

    bloc.add(SeedSectionPage(kind: HomeSectionKind.year, items: [manga(1)]));
    final state = await bloc.stream.firstWhere((s) => s is HomeSectionPageLoaded)
        as HomeSectionPageLoaded;
    expect(state.hasMore, isFalse);

    bloc.add(const LoadMoreSectionPage());
    await Future<void>.delayed(const Duration(milliseconds: 20));
    verifyNever(() => service.fetchSectionPage(any(),
        page: any(named: 'page'), limit: any(named: 'limit')));
  });

  test('SeedSectionPage hors ligne : le defilement ne tente rien', () async {
    final bloc = HomeSectionPageBloc(
        sectionId: 'year:2014', limit: 2, service: service);
    addTearDown(bloc.close);

    bloc.add(SeedSectionPage(
      kind: HomeSectionKind.year,
      items: [manga(1), manga(2)],
      isOffline: true,
    ));
    final state = await bloc.stream.firstWhere((s) => s is HomeSectionPageLoaded)
        as HomeSectionPageLoaded;
    expect(state.isOffline, isTrue);
    expect(state.hasMore, isFalse, reason: 'aucune suite a esperer hors ligne');

    bloc.add(const LoadMoreSectionPage());
    await Future<void>.delayed(const Duration(milliseconds: 20));
    verifyNever(() => service.fetchSectionPage(any(),
        page: any(named: 'page'), limit: any(named: 'limit')));
  });

  test('apercu puis page suivante : append, dedoublonnage par muId', () async {
    stubPage(2, pageDto(page: 2, items: [manga(2), manga(3)], total: 0));
    final bloc = HomeSectionPageBloc(
        sectionId: 'year:2014', limit: 2, service: service);
    addTearDown(bloc.close);

    bloc.add(SeedSectionPage(
      kind: HomeSectionKind.year,
      items: [manga(1), manga(2)],
    ));
    await bloc.stream.firstWhere((s) => s is HomeSectionPageLoaded);

    bloc.add(const LoadMoreSectionPage());
    final state = await bloc.stream.firstWhere(
      (s) => s is HomeSectionPageLoaded && !s.isLoadingMore && s.page == 2,
    ) as HomeSectionPageLoaded;

    expect(state.items.map((m) => m.muId), [1, 2, 3],
        reason: 'le titre 2 renvoye deux fois ne figure qu une seule fois');
    verify(() => service.fetchSectionPage('year:2014', page: 2, limit: 2))
        .called(1);
  });

  test('page vide : la pagination se ferme et ne reboucle jamais', () async {
    // `total` mensonger : le serveur annonce une suite mais ne renvoie rien.
    stubPage(2, pageDto(page: 2, items: [], total: 99));
    final bloc = HomeSectionPageBloc(
        sectionId: 'year:2014', limit: 2, service: service);
    addTearDown(bloc.close);

    bloc.add(SeedSectionPage(
      kind: HomeSectionKind.year,
      items: [manga(1), manga(2)],
    ));
    await bloc.stream.firstWhere((s) => s is HomeSectionPageLoaded);

    bloc.add(const LoadMoreSectionPage());
    final state = await bloc.stream.firstWhere(
      (s) => s is HomeSectionPageLoaded && !s.isLoadingMore && s.page == 2,
    ) as HomeSectionPageLoaded;
    expect(state.hasMore, isFalse);
    expect(state.items, hasLength(2));

    // Meme en insistant : plus aucun appel.
    bloc.add(const LoadMoreSectionPage());
    bloc.add(const LoadMoreSectionPage());
    await Future<void>.delayed(const Duration(milliseconds: 20));
    verify(() => service.fetchSectionPage(any(),
        page: 2, limit: any(named: 'limit'))).called(1);
  });
}
