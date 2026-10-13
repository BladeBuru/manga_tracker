import 'dart:async';

import 'package:flutter_test/flutter_test.dart';
import 'package:mangatracker/core/network/api_exception.dart';
import 'package:mangatracker/features/friends/bloc/friends_bloc.dart';
import 'package:mangatracker/features/friends/dto/friend.dto.dart';
import 'package:mangatracker/features/friends/services/friends.service.dart';
import 'package:mocktail/mocktail.dart';

class _Service extends Mock implements FriendsService {}

FriendshipDto _friendship(
  int id,
  int otherUserId, {
  FriendshipStatus status = FriendshipStatus.pending,
  FriendshipDirection direction = FriendshipDirection.received,
}) =>
    FriendshipDto(
      id: id,
      status: status,
      direction: direction,
      otherUserId: otherUserId,
      otherUsername: 'user$otherUserId',
      createdAt: DateTime(2026),
    );

UserSearchResultDto _user(int id, {FriendRelation relation = FriendRelation.none}) =>
    UserSearchResultDto(id: id, username: 'user$id', relation: relation);

void main() {
  late _Service service;

  setUp(() {
    service = _Service();
    when(() => service.getAcceptedFriends(forceRefresh: any(named: 'forceRefresh')))
        .thenAnswer((_) async => []);
    when(() => service.getPendingRequests()).thenAnswer((_) async => []);
    when(() => service.getSentRequests()).thenAnswer((_) async => []);
  });

  Future<void> settle() async {
    for (var i = 0; i < 4; i++) {
      await Future<void>.delayed(Duration.zero);
    }
  }

  Future<FriendsBloc> loaded() async {
    final bloc = FriendsBloc(service: service, refreshBadges: () {});
    addTearDown(bloc.close);
    bloc.add(const LoadFriends(forceRefresh: true));
    await settle();
    expect(bloc.state, isA<FriendsLoaded>());
    return bloc;
  }

  test('une réponse de recherche périmée n\'écrase pas la plus récente',
      () async {
    final slow = Completer<List<UserSearchResultDto>>();
    when(() => service.searchUsers('lé')).thenAnswer((_) => slow.future);
    when(() => service.searchUsers('léa')).thenAnswer((_) async => [_user(2)]);
    final bloc = await loaded();

    bloc.add(const SearchUsers('lé'));
    await settle();
    bloc.add(const SearchUsers('léa'));
    await settle();
    slow.complete([_user(1), _user(3)]); // arrive APRÈS « léa »
    await settle();

    final state = bloc.state as FriendsLoaded;
    expect(state.searchQuery, 'léa');
    expect(state.searchResults.map((u) => u.id), [2]);
    expect(state.searchLoading, isFalse);
  });

  test('échec de recherche : conservé dans l\'état (affiché), pas « aucun '
      'résultat »', () async {
    when(() => service.searchUsers(any())).thenThrow(const ApiException(429));
    final bloc = await loaded();
    bloc.add(const SearchUsers('léa'));
    await settle();
    final state = bloc.state as FriendsLoaded;
    expect(state.searchError, isA<ApiException>());
    expect(state.searchResults, isEmpty);
  });

  test('relation effective : listes locales, puis champ du serveur', () async {
    when(() => service.getAcceptedFriends(forceRefresh: any(named: 'forceRefresh')))
        .thenAnswer((_) async => [
              _friendship(10, 1, status: FriendshipStatus.accepted),
            ]);
    when(() => service.getPendingRequests())
        .thenAnswer((_) async => [_friendship(11, 2)]);
    when(() => service.getSentRequests()).thenAnswer((_) async => [
          _friendship(12, 3, direction: FriendshipDirection.sent),
        ]);
    final bloc = await loaded();
    final state = bloc.state as FriendsLoaded;

    expect(state.relationOf(_user(1)), FriendRelation.friends);
    expect(state.relationOf(_user(2)), FriendRelation.pendingReceived);
    expect(state.relationOf(_user(3)), FriendRelation.pendingSent);
    expect(state.relationOf(_user(4)), FriendRelation.none);
    expect(
      state.relationOf(_user(5, relation: FriendRelation.pendingSent)),
      FriendRelation.pendingSent,
      reason: 'serveur récent : relation renvoyée par la recherche',
    );
  });

  test('envoyer : demande ajoutée aux envoyées, résultat « Demande envoyée »',
      () async {
    when(() => service.searchUsers('léa')).thenAnswer((_) async => [_user(4)]);
    when(() => service.sendRequest(addresseeId: 4)).thenAnswer(
      (_) async => _friendship(20, 4, direction: FriendshipDirection.sent),
    );
    final bloc = await loaded();
    bloc.add(const SearchUsers('léa'));
    await settle();

    bloc.add(const SendFriendRequest(4));
    await settle();
    final state = bloc.state as FriendsLoaded;
    expect(state.sent.map((f) => f.id), [20]);
    expect(state.relationOf(state.searchResults.single),
        FriendRelation.pendingSent);
    expect(state.feedback, FriendsFeedback.requestSent);
  });

  test('doublon (409) : l\'erreur du serveur est remontée, rien ne change',
      () async {
    when(() => service.sendRequest(addresseeId: 4)).thenThrow(
      const ApiException(409, serverMessage: 'Une demande est déjà en attente'),
    );
    final bloc = await loaded();
    bloc.add(const SendFriendRequest(4));
    await settle();
    final state = bloc.state as FriendsLoaded;
    expect(state.sent, isEmpty);
    expect((state.actionError as ApiException).statusCode, 409);
  });

  test('annuler une demande envoyée : retirée, résultat « Ajouter »', () async {
    when(() => service.getSentRequests()).thenAnswer((_) async => [
          _friendship(12, 3, direction: FriendshipDirection.sent),
        ]);
    when(() => service.searchUsers('user3')).thenAnswer(
      (_) async => [_user(3, relation: FriendRelation.pendingSent)],
    );
    when(() => service.deleteFriendship(12)).thenAnswer((_) async {});
    final bloc = await loaded();
    bloc.add(const SearchUsers('user3'));
    await settle();

    bloc.add(const CancelFriendRequest(12));
    await settle();
    final state = bloc.state as FriendsLoaded;
    expect(state.sent, isEmpty);
    expect(state.relationOf(state.searchResults.single), FriendRelation.none);
    expect(state.feedback, FriendsFeedback.requestCancelled);
  });

  test('une liste en échec n\'empêche pas d\'afficher les autres', () async {
    when(() => service.getSentRequests()).thenThrow(const ApiException(500));
    when(() => service.getPendingRequests())
        .thenAnswer((_) async => [_friendship(11, 2)]);
    final bloc = await loaded();
    final state = bloc.state as FriendsLoaded;
    expect(state.pending.single.id, 11);
    expect(state.sent, isEmpty);
  });
}
