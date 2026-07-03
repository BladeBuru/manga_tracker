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

  const SearchLoaded({
    required this.query,
    required this.results,
    required this.totalHits,
    required this.page,
    required this.hasMore,
    this.isLoadingMore = false,
    this.loadMoreFailed = false,
    this.isOffline = false,
  });

  SearchLoaded copyWith({
    List<MangaQuickViewDto>? results,
    int? totalHits,
    int? page,
    bool? hasMore,
    bool? isLoadingMore,
    bool? loadMoreFailed,
    bool? isOffline,
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
      ];
}

class SearchError extends SearchState {
  final String query;
  final bool isOffline;

  const SearchError(this.query, {this.isOffline = false});

  @override
  List<Object?> get props => [query, isOffline];
}
