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

class SendFriendRequest extends FriendsEvent {
  final int userId;
  const SendFriendRequest(this.userId);
  @override
  List<Object?> get props => [userId];
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
