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

class FriendsLoaded extends FriendsState {
  final List<FriendshipDto> accepted;
  final List<FriendshipDto> pending;
  final List<UserSearchResultDto> searchResults;

  /// Message d'info bref à afficher (snackbar), ex: 'request_sent'.
  /// L'UI le lit puis envoie un nouvel event pour le clear.
  final String? lastActionMessage;
  final String? lastActionError;
  final String? searchError;

  const FriendsLoaded({
    required this.accepted,
    required this.pending,
    required this.searchResults,
    this.lastActionMessage,
    this.lastActionError,
    this.searchError,
  });

  FriendsLoaded copyWith({
    List<FriendshipDto>? accepted,
    List<FriendshipDto>? pending,
    List<UserSearchResultDto>? searchResults,
    String? lastActionMessage,
    String? lastActionError,
    String? searchError,
  }) {
    return FriendsLoaded(
      accepted: accepted ?? this.accepted,
      pending: pending ?? this.pending,
      searchResults: searchResults ?? this.searchResults,
      lastActionMessage: lastActionMessage,
      lastActionError: lastActionError,
      searchError: searchError,
    );
  }

  @override
  List<Object?> get props => [
        accepted,
        pending,
        searchResults,
        lastActionMessage,
        lastActionError,
        searchError,
      ];
}

class FriendsError extends FriendsState {
  final String message;
  const FriendsError(this.message);
  @override
  List<Object?> get props => [message];
}
