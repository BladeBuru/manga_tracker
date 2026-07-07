import 'package:bloc/bloc.dart';
import 'package:equatable/equatable.dart';
import 'package:flutter/foundation.dart';
import 'package:mangatracker/core/network/network_compat.dart';
import 'package:mangatracker/core/services/offline_cache_service.dart';
import 'package:mangatracker/features/manga/dto/manga_quick_view.dto.dart';
import 'package:mangatracker/features/manga/services/manga.service.dart';

part 'search_event.dart';
part 'search_state.dart';

/// BLoC de la page Recherche — résultats paginés en scroll infini.
///
/// [SearchRequested] charge la page 1 (fallback cache si hors ligne) ;
/// [SearchNextPageRequested] ajoute la page suivante à la liste accumulée.
class SearchBloc extends Bloc<SearchEvent, SearchState> {
  final MangaService _mangaService;
  final OfflineCacheService _cacheService;

  // 25 = valeur nativement supportée par MangaUpdates (les autres sont
  // coercées silencieusement, ex. 20 → 25) : demandé == servi == enveloppe.
  static const int pageSize = 25;

  SearchBloc({
    required MangaService mangaService,
    required OfflineCacheService cacheService,
  })  : _mangaService = mangaService,
        _cacheService = cacheService,
        super(const SearchInitial()) {
    on<SearchRequested>(_onSearchRequested);
    on<SearchNextPageRequested>(_onNextPageRequested);
    on<SearchCleared>((_, emit) => emit(const SearchInitial()));
  }

  /// Vrai si [query] est toujours la recherche en cours d'affichage.
  ///
  /// Le transformer par défaut de bloc traite les events en CONCURRENCE :
  /// une requête HTTP encore en vol ne doit pas écraser l'état si une
  /// [SearchCleared] ou une [SearchRequested] plus récente est passée
  /// entre-temps (résultats fantômes sous une barre vide / autre query).
  bool _isCurrentSearch(String query) {
    final s = state;
    return s is SearchLoading && s.query == query;
  }

  Future<void> _onSearchRequested(
      SearchRequested event, Emitter<SearchState> emit) async {
    final query = event.query.trim();
    if (query.isEmpty) {
      emit(const SearchInitial());
      return;
    }
    emit(SearchLoading(query));
    try {
      final page =
          await _mangaService.searchForMangas(query, page: 1, limit: pageSize);
      if (!_isCurrentSearch(query)) return; // requête périmée
      await _cacheService.cacheSearchResults(query, page.results);
      if (!_isCurrentSearch(query)) return;
      emit(SearchLoaded(
        query: query,
        results: page.results,
        totalHits: page.totalHits,
        page: page.page,
        hasMore: page.hasMore,
      ));
    } on SocketException {
      final cached = await _cacheService.getCachedSearchResults(query);
      if (!_isCurrentSearch(query)) return;
      if (cached != null && cached.isNotEmpty) {
        emit(SearchLoaded(
          query: query,
          results: cached,
          totalHits: cached.length,
          page: 1,
          hasMore: false,
          isOffline: true,
        ));
      } else {
        emit(SearchError(query, isOffline: true));
      }
    } catch (e) {
      debugPrint('❌ SearchBloc: recherche "$query" échouée: $e');
      if (!_isCurrentSearch(query)) return;
      emit(SearchError(query));
    }
  }

  Future<void> _onNextPageRequested(
      SearchNextPageRequested event, Emitter<SearchState> emit) async {
    final current = state;
    if (current is! SearchLoaded ||
        !current.hasMore ||
        current.isLoadingMore ||
        current.isOffline) {
      return;
    }
    final loadingState =
        current.copyWith(isLoadingMore: true, loadMoreFailed: false);
    emit(loadingState);
    try {
      final next = await _mangaService.searchForMangas(
        current.query,
        page: current.page + 1,
        limit: pageSize,
      );
      // Une SearchRequested/SearchCleared est passée pendant le fetch →
      // ne pas écraser le nouvel état avec l'ancienne pagination.
      if (state != loadingState) return;
      // Dédoublonnage par muId : le classement MU peut glisser entre deux
      // appels (résultats insérés) → évite les doublons visuels à l'append.
      final known = current.results.map((m) => m.muId).toSet();
      final appended = [
        ...current.results,
        ...next.results.where((m) => known.add(m.muId)),
      ];
      emit(SearchLoaded(
        query: current.query,
        results: appended,
        totalHits: next.totalHits,
        page: next.page,
        hasMore: next.hasMore,
      ));
    } catch (e) {
      debugPrint('❌ SearchBloc: page suivante échouée: $e');
      if (state != loadingState) return;
      emit(current.copyWith(isLoadingMore: false, loadMoreFailed: true));
    }
  }
}
