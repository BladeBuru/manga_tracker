import 'package:bloc/bloc.dart';
import 'package:flutter/foundation.dart';
import 'package:mangatracker/core/network/failure_classifier.dart';
import 'package:mangatracker/core/service_locator/service_locator.dart';
import 'package:mangatracker/features/home/dto/home_section.dto.dart';
import 'package:mangatracker/features/home/services/home_sections.service.dart';

import 'home_section_page_event.dart';
import 'home_section_page_state.dart';

/// BLoC de pagination d'une section de l'accueil.
///
/// **Un seul BLoC pour deux surfaces** (2026-09-09) :
/// - la page « Tout voir » (`/home/section/:id`) le cree via GetIt et part de
///   [LoadSectionPage] (grille, 40 items par page) ;
/// - le carrousel horizontal de l'accueil le cree lui-meme avec
///   [limit] = `HomeSectionsService.defaultLimit` et part de
///   [SeedSectionPage] : sa page 1 est deja affichee, il n'a qu'a enchainer.
///
/// Consequence : append, deduplication par `muId`, garde hors ligne et
/// gestion d'echec sont ecrits **une seule fois**.
///
/// Hors ligne, la premiere page retombe sur l'apercu de la section present
/// dans le cache de l'accueil (sans pagination) — pas de cache dedie par page.
class HomeSectionPageBloc
    extends Bloc<HomeSectionPageEvent, HomeSectionPageState> {
  final String sectionId;

  /// Taille de page demandee au serveur. Doit correspondre a la taille de
  /// l'apercu quand le BLoC est amorce par [SeedSectionPage], sinon la page 2
  /// chevaucherait ou sauterait des titres.
  final int limit;

  final HomeSectionsService? _serviceOverride;

  HomeSectionPageBloc({
    required this.sectionId,
    this.limit = HomeSectionsService.pageLimit,
    HomeSectionsService? service,
  })  : _serviceOverride = service,
        super(const HomeSectionPageInitial()) {
    on<LoadSectionPage>((_, emit) => _loadFirstPage(emit));
    on<RefreshSectionPage>((_, emit) => _loadFirstPage(emit, silent: true));
    on<SeedSectionPage>(_seed);
    on<LoadMoreSectionPage>((_, emit) => _loadMore(emit));
  }

  HomeSectionsService get _service =>
      _serviceOverride ?? getIt<HomeSectionsService>();

  /// Amorce sans requete : les items sont deja a l'ecran.
  ///
  /// `hasMore` suit la meme regle que [HomeSectionsPageDto.hasMore] faute de
  /// `total` : un apercu plein laisse supposer une suite, un apercu incomplet
  /// signe la fin. Hors ligne, la pagination reste fermee.
  void _seed(SeedSectionPage event, Emitter<HomeSectionPageState> emit) {
    emit(HomeSectionPageLoaded(
      sectionId: sectionId,
      kind: event.kind,
      params: event.params,
      items: event.items,
      page: 1,
      hasMore: !event.isOffline && event.items.length >= limit,
      isOffline: event.isOffline,
    ));
  }

  Future<void> _loadFirstPage(
    Emitter<HomeSectionPageState> emit, {
    bool silent = false,
  }) async {
    if (!silent || state is! HomeSectionPageLoaded) {
      emit(const HomeSectionPageLoading());
    }
    try {
      final page = await _service.fetchSectionPage(
        sectionId,
        page: 1,
        limit: limit,
      );
      emit(HomeSectionPageLoaded(
        sectionId: sectionId,
        kind: page.kind,
        params: page.params,
        items: page.items,
        page: page.page,
        total: page.total,
        hasMore: page.hasMore,
      ));
    } on HomeSectionNotFoundException catch (e) {
      emit(HomeSectionPageError(message: e.toString(), notFound: true));
    } catch (e) {
      await _emitFallback(emit, e);
    }
  }

  /// Repli hors ligne : l'apercu de la section dans le cache de l'accueil.
  Future<void> _emitFallback(
    Emitter<HomeSectionPageState> emit,
    Object error,
  ) async {
    final mode = classifyFailure(error);
    final offline = showsOfflineIndicator(mode);
    final reauth = requiresReauthPrompt(mode);
    debugPrint('HomeSectionPageBloc[$sectionId]: echec ($mode), repli cache');

    HomeSectionDto? cached;
    try {
      final sections = await _service.getCachedSections();
      cached = sections?.sections.cast<HomeSectionDto?>().firstWhere(
            (s) => s?.id == sectionId,
            orElse: () => null,
          );
    } catch (_) {
      cached = null;
    }

    if (cached != null && cached.items.isNotEmpty) {
      emit(HomeSectionPageLoaded(
        sectionId: sectionId,
        kind: cached.kind,
        params: cached.params,
        items: cached.items,
        page: 1,
        total: cached.items.length,
        hasMore: false,
        isOffline: offline,
        requiresReauth: reauth,
      ));
    } else {
      emit(HomeSectionPageError(
        message: error.toString(),
        isOffline: offline,
        requiresReauth: reauth,
      ));
    }
  }

  Future<void> _loadMore(Emitter<HomeSectionPageState> emit) async {
    final current = state;
    if (current is! HomeSectionPageLoaded) return;
    if (!current.hasMore || current.isLoadingMore || current.isOffline) return;

    emit(current.copyWith(isLoadingMore: true, loadMoreFailed: false));
    try {
      final next = await _service.fetchSectionPage(
        sectionId,
        page: current.page + 1,
        limit: limit,
      );
      // Deduplication defensive : une insertion cote serveur entre deux pages
      // peut faire glisser un titre d'une page a l'autre.
      final known = current.items.map((m) => m.muId).toSet();
      final appended = next.items.where((m) => known.add(m.muId)).toList();
      emit(current.copyWith(
        items: [...current.items, ...appended],
        page: next.page,
        total: next.total,
        // Une page VIDE ferme la pagination quoi qu'en dise le `total` : sans
        // ca, un carrousel arrive au bout redemanderait la meme page a chaque
        // geste de scroll (le `total` peut mentir, la page vide non).
        hasMore: next.items.isEmpty ? false : next.hasMore,
        isLoadingMore: false,
      ));
    } catch (e) {
      // INVARIANT : toujours emettre, sinon le pied de liste tourne sans fin.
      final mode = classifyFailure(e);
      emit(current.copyWith(
        isLoadingMore: false,
        loadMoreFailed: true,
        isOffline: showsOfflineIndicator(mode),
        requiresReauth: requiresReauthPrompt(mode),
      ));
    }
  }
}
