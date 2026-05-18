part of 'comments_bloc.dart';

abstract class CommentsState extends Equatable {
  const CommentsState();
  @override
  List<Object?> get props => [];
}

class CommentsInitial extends CommentsState {
  const CommentsInitial();
}

class CommentsLoading extends CommentsState {
  const CommentsLoading();
}

class CommentsLoaded extends CommentsState {
  final List<CommentDto> items;
  final int currentPage;
  final bool hasMore;
  final bool isLoadingMore;
  final CommentSort sort;
  final String? lastError;

  const CommentsLoaded({
    required this.items,
    required this.currentPage,
    required this.hasMore,
    this.isLoadingMore = false,
    required this.sort,
    this.lastError,
  });

  CommentsLoaded copyWith({
    List<CommentDto>? items,
    int? currentPage,
    bool? hasMore,
    bool? isLoadingMore,
    CommentSort? sort,
    String? lastError,
  }) {
    return CommentsLoaded(
      items: items ?? this.items,
      currentPage: currentPage ?? this.currentPage,
      hasMore: hasMore ?? this.hasMore,
      isLoadingMore: isLoadingMore ?? this.isLoadingMore,
      sort: sort ?? this.sort,
      lastError: lastError,
    );
  }

  @override
  List<Object?> get props =>
      [items, currentPage, hasMore, isLoadingMore, sort, lastError];
}

class CommentsError extends CommentsState {
  final String message;
  const CommentsError(this.message);
  @override
  List<Object?> get props => [message];
}
