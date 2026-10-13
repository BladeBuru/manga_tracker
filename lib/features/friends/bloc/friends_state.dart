part of 'friends_bloc.dart';

abstract class FriendsState extends Equatable {
  const FriendsState();
  @override
  List<Object?> get props => [];
}

class FriendsInitial extends FriendsState {
  const FriendsInitial();
}

class FriendsLoading extends FriendsState {
  const FriendsLoading();
}

/// Retour bref d'une action réussie (barre de message).
enum FriendsFeedback { requestSent, requestCancelled, nowFriends }

class FriendsLoaded extends FriendsState {
  final List<FriendshipDto> accepted;

  /// Demandes reçues, à accepter ou refuser.
  final List<FriendshipDto> pending;

  /// Demandes envoyées, encore sans réponse (annulables).
  final List<FriendshipDto> sent;

  /// Requête dont [searchResults] sont la réponse.
  final String searchQuery;
  final List<UserSearchResultDto> searchResults;
  final bool searchLoading;

  /// Échec de la dernière recherche — affiché à la place de « Aucun
  /// utilisateur trouvé ».
  final Object? searchError;

  /// Événements ponctuels : présents sur UN état, effacés au suivant.
  final FriendsFeedback? feedback;
  final String? feedbackName;
  final Object? actionError;

  /// Une partie des listes vient du cache ou n'a pas pu être chargée.
  final bool isOffline;

  const FriendsLoaded({
    required this.accepted,
    required this.pending,
    this.sent = const [],
    this.searchQuery = '',
    this.searchResults = const [],
    this.searchLoading = false,
    this.searchError,
    this.feedback,
    this.feedbackName,
    this.actionError,
    this.isOffline = false,
  });

  /// Relation effective avec un résultat : les listes locales (à jour après
  /// chaque action) priment sur le champ `relation` du serveur.
  FriendRelation relationOf(UserSearchResultDto user) {
    if (accepted.any((f) => f.otherUserId == user.id)) {
      return FriendRelation.friends;
    }
    if (receivedFrom(user.id) != null) return FriendRelation.pendingReceived;
    if (sentTo(user.id) != null) return FriendRelation.pendingSent;
    return user.relation;
  }

  FriendshipDto? receivedFrom(int userId) => _byUser(pending, userId);
  FriendshipDto? sentTo(int userId) => _byUser(sent, userId);

  static FriendshipDto? _byUser(List<FriendshipDto> list, int userId) {
    for (final f in list) {
      if (f.otherUserId == userId) return f;
    }
    return null;
  }

  /// Copie ; les champs ponctuels ([feedback], [feedbackName],
  /// [actionError]) ne sont PAS recopiés : ils s'effacent d'eux-mêmes.
  FriendsLoaded copyWith({
    List<FriendshipDto>? accepted,
    List<FriendshipDto>? pending,
    List<FriendshipDto>? sent,
    String? searchQuery,
    List<UserSearchResultDto>? searchResults,
    bool? searchLoading,
    Object? Function()? searchError,
    FriendsFeedback? feedback,
    String? feedbackName,
    Object? actionError,
    bool? isOffline,
  }) {
    return FriendsLoaded(
      accepted: accepted ?? this.accepted,
      pending: pending ?? this.pending,
      sent: sent ?? this.sent,
      searchQuery: searchQuery ?? this.searchQuery,
      searchResults: searchResults ?? this.searchResults,
      searchLoading: searchLoading ?? this.searchLoading,
      searchError: searchError != null ? searchError() : this.searchError,
      feedback: feedback,
      feedbackName: feedbackName,
      actionError: actionError,
      isOffline: isOffline ?? this.isOffline,
    );
  }

  /// Met à jour la relation d'un résultat de recherche après une action.
  List<UserSearchResultDto> resultsWith(int userId, FriendRelation relation) => [
        for (final r in searchResults)
          r.id == userId ? r.withRelation(relation) : r,
      ];

  @override
  List<Object?> get props => [
        accepted,
        pending,
        sent,
        searchQuery,
        searchResults,
        searchLoading,
        searchError,
        feedback,
        feedbackName,
        actionError,
        isOffline,
      ];
}

class FriendsError extends FriendsState {
  /// Cause de l'échec — texte via `userFacingErrorMessage`, jamais
  /// `toString()`.
  final Object error;
  final bool isOffline;
  const FriendsError(this.error, {this.isOffline = false});
  @override
  List<Object?> get props => [error, isOffline];
}
