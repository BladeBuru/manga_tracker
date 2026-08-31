part of 'search_bloc.dart';

abstract class SearchState extends Equatable {
  const SearchState();

  @override
  List<Object?> get props => [];
}

class SearchInitial extends SearchState {
  const SearchInitial();
}

class SearchLoading extends SearchState {
  final String query;

  const SearchLoading(this.query);

  @override
  List<Object?> get props => [query];
}

class SearchLoaded extends SearchState {
  final String query;
  final List<MangaQuickViewDto> results;
  final int totalHits;
  final int page;
  final bool hasMore;
  final bool isLoadingMore;
  final bool loadMoreFailed;
  final bool isOffline;

  /// Le serveur a rejeté la session (401/403) : l'utilisateur est invité à se
  /// reconnecter, **sans être bloqué**. Le contenu en cache reste affiché
  /// derrière l'invitation — cf. `failure_classifier.dart`, frontière de
  /// sécurité. Ne jamais rebrancher une redirection forcée dessus.
  final bool requiresReauth;

  const SearchLoaded({
    required this.query,
    required this.results,
    required this.totalHits,
    required this.page,
    required this.hasMore,
    this.isLoadingMore = false,
    this.loadMoreFailed = false,
    this.isOffline = false,
    this.requiresReauth = false,
  });

  SearchLoaded copyWith({
    List<MangaQuickViewDto>? results,
    int? totalHits,
    int? page,
    bool? hasMore,
    bool? isLoadingMore,
    bool? loadMoreFailed,
    bool? isOffline,
    bool? requiresReauth,
  }) {
    return SearchLoaded(
      query: query,
      results: results ?? this.results,
      totalHits: totalHits ?? this.totalHits,
      page: page ?? this.page,
      hasMore: hasMore ?? this.hasMore,
      isLoadingMore: isLoadingMore ?? this.isLoadingMore,
      loadMoreFailed: loadMoreFailed ?? this.loadMoreFailed,
      isOffline: isOffline ?? this.isOffline,
      requiresReauth: requiresReauth ?? this.requiresReauth,
    );
  }

  @override
  List<Object?> get props => [
        query,
        results,
        totalHits,
        page,
        hasMore,
        isLoadingMore,
        loadMoreFailed,
        isOffline,
        requiresReauth,
      ];
}

class SearchError extends SearchState {
  final String query;
  final bool isOffline;

  /// Le serveur a rejeté la session (401/403) : l'utilisateur est invité à se
  /// reconnecter, **sans être bloqué**. Le contenu en cache reste affiché
  /// derrière l'invitation — cf. `failure_classifier.dart`, frontière de
  /// sécurité. Ne jamais rebrancher une redirection forcée dessus.
  final bool requiresReauth;

  const SearchError(this.query,
      {this.isOffline = false, this.requiresReauth = false});

  @override
  List<Object?> get props => [query, isOffline, requiresReauth];
}
