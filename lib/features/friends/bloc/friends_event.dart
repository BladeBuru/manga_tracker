part of 'friends_bloc.dart';

abstract class FriendsEvent extends Equatable {
  const FriendsEvent();
  @override
  List<Object?> get props => [];
}

class LoadFriends extends FriendsEvent {
  final bool forceRefresh;
  const LoadFriends({this.forceRefresh = false});
  @override
  List<Object?> get props => [forceRefresh];
}

class SearchUsers extends FriendsEvent {
  final String query;
  const SearchUsers(this.query);
  @override
  List<Object?> get props => [query];
}

/// Envoi d'une demande, APRÈS confirmation de l'utilisateur (la vue
/// demande d'abord « Envoyer une demande d'ami à X ? »).
class SendFriendRequest extends FriendsEvent {
  final int userId;

  /// Nom affiché dans le message de retour (« Vous et X êtes amis »).
  final String? displayName;

  const SendFriendRequest(this.userId, {this.displayName});
  @override
  List<Object?> get props => [userId, displayName];
}

class RespondToRequest extends FriendsEvent {
  final int friendshipId;
  final FriendshipStatus newStatus;
  const RespondToRequest({
    required this.friendshipId,
    required this.newStatus,
  });
  @override
  List<Object?> get props => [friendshipId, newStatus];
}

class RemoveFriend extends FriendsEvent {
  final int friendshipId;
  const RemoveFriend(this.friendshipId);
  @override
  List<Object?> get props => [friendshipId];
}

/// Annule une demande que j'ai envoyée (`DELETE /friends/:id`).
class CancelFriendRequest extends FriendsEvent {
  final int friendshipId;
  const CancelFriendRequest(this.friendshipId);
  @override
  List<Object?> get props => [friendshipId];
}
