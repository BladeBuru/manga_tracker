import 'package:bloc/bloc.dart';
import 'package:flutter/foundation.dart';
import 'package:mangatracker/core/network/failure_classifier.dart';
import 'package:mangatracker/core/service_locator/service_locator.dart';
import 'package:mangatracker/features/home/dto/home_section.dto.dart';
import 'package:mangatracker/features/home/services/home_sections.service.dart';

import 'home_section_page_event.dart';
import 'home_section_page_state.dart';

/// BLoC de la page « Tout voir » d'une section (`/home/section/:id`).
///
/// Une instance par page (factory GetIt parametree par [sectionId]). Grille
/// paginee via `GET /mangas/home/sections/:id?page&limit` ; hors ligne, la
/// premiere page retombe sur l'apercu de la section present dans le cache de
/// l'accueil (20 items, sans pagination) — pas de cache dedie par page.
class HomeSectionPageBloc
    extends Bloc<HomeSectionPageEvent, HomeSectionPageState> {
  final String sectionId;
  final HomeSectionsService? _serviceOverride;

  HomeSectionPageBloc({required this.sectionId, HomeSectionsService? service})
      : _serviceOverride = service,
        super(const HomeSectionPageInitial()) {
    on<LoadSectionPage>((_, emit) => _loadFirstPage(emit));
    on<RefreshSectionPage>((_, emit) => _loadFirstPage(emit, silent: true));
    on<LoadMoreSectionPage>((_, emit) => _loadMore(emit));
  }

  HomeSectionsService get _service =>
      _serviceOverride ?? getIt<HomeSectionsService>();

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
        limit: HomeSectionsService.pageLimit,
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
        limit: HomeSectionsService.pageLimit,
      );
      // Deduplication defensive : une insertion cote serveur entre deux pages
      // peut faire glisser un titre d'une page a l'autre.
      final known = current.items.map((m) => m.muId).toSet();
      final appended = next.items.where((m) => known.add(m.muId)).toList();
      emit(current.copyWith(
        items: [...current.items, ...appended],
        page: next.page,
        total: next.total,
        hasMore: next.hasMore,
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
