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

/// Retour bref d'une action réussie.
enum CommentsFeedback { reported }

class CommentsLoaded extends CommentsState {
  final List<CommentDto> items;
  final int currentPage;
  final bool hasMore;
  final bool isLoadingMore;
  final CommentSort sort;

  /// Utilisateur connecté (`null` si inconnu) : « Supprimer » n'est proposé
  /// que sur SES commentaires, « Signaler » sur ceux des autres.
  final int? currentUserId;

  /// Échec ponctuel d'une action — texte via `userFacingErrorMessage`.
  final Object? lastError;
  final CommentsFeedback? feedback;

  const CommentsLoaded({
    required this.items,
    required this.currentPage,
    required this.hasMore,
    this.isLoadingMore = false,
    required this.sort,
    this.currentUserId,
    this.lastError,
    this.feedback,
  });

  bool isMine(CommentDto comment) =>
      currentUserId != null && comment.authorId == currentUserId;

  /// [lastError] et [feedback] sont ponctuels : jamais recopiés.
  CommentsLoaded copyWith({
    List<CommentDto>? items,
    int? currentPage,
    bool? hasMore,
    bool? isLoadingMore,
    CommentSort? sort,
    Object? lastError,
    CommentsFeedback? feedback,
  }) {
    return CommentsLoaded(
      items: items ?? this.items,
      currentPage: currentPage ?? this.currentPage,
      hasMore: hasMore ?? this.hasMore,
      isLoadingMore: isLoadingMore ?? this.isLoadingMore,
      sort: sort ?? this.sort,
      currentUserId: currentUserId,
      lastError: lastError,
      feedback: feedback,
    );
  }

  @override
  List<Object?> get props => [
        items,
        currentPage,
        hasMore,
        isLoadingMore,
        sort,
        currentUserId,
        lastError,
        feedback,
      ];
}

class CommentsError extends CommentsState {
  /// Cause de l'échec — jamais affichée par `toString()`.
  final Object error;
  const CommentsError(this.error);
  @override
  List<Object?> get props => [error];
}
