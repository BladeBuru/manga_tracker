import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mangatracker/features/friends/bloc/friends_bloc.dart';
import 'package:mangatracker/features/friends/dto/friend.dto.dart';
import 'package:mangatracker/features/friends/services/friends.service.dart';
import 'package:mangatracker/features/friends/views/friends_list_page.dart';
import 'package:mocktail/mocktail.dart';

import '../home/views/home_test_harness.dart';

class _Service extends Mock implements FriendsService {}

/// Recherche d'amis : état de relation visible, confirmation avant tout
/// envoi, échec affiché (et non « Aucun utilisateur trouvé »).
void main() {
  late _Service service;

  setUp(() {
    service = _Service();
    when(() => service.getAcceptedFriends(forceRefresh: any(named: 'forceRefresh')))
        .thenAnswer((_) async => []);
    when(() => service.getPendingRequests()).thenAnswer((_) async => []);
    when(() => service.getSentRequests()).thenAnswer((_) async => []);
  });

  Widget page() => frRouterHarness(
        home: FriendsListPage(
          createBloc: () => FriendsBloc(service: service, refreshBadges: () {}),
        ),
      );

  Future<void> search(WidgetTester tester, String query) async {
    await tester.enterText(find.byType(TextField), query);
    await tester.pump(const Duration(milliseconds: 350)); // temporisation
    await pumpFrames(tester);
  }

  testWidgets('« Ajouter » demande confirmation, puis envoie', (tester) async {
    when(() => service.searchUsers('léa')).thenAnswer(
      (_) async => [const UserSearchResultDto(id: 4, username: 'lea', displayName: 'Léa')],
    );
    when(() => service.sendRequest(addresseeId: 4)).thenAnswer(
      (_) async => FriendshipDto(
        id: 20,
        status: FriendshipStatus.pending,
        direction: FriendshipDirection.sent,
        otherUserId: 4,
        otherUsername: 'lea',
        createdAt: DateTime(2026),
      ),
    );
    await tester.pumpWidget(page());
    await pumpFrames(tester);
    await search(tester, 'léa');

    await tester.tap(find.text('Ajouter'));
    await pumpFrames(tester);
    expect(find.text("Envoyer une demande d'ami à Léa ?"), findsOneWidget);
    verifyNever(() => service.sendRequest(addresseeId: any(named: 'addresseeId')));

    await tester.tap(find.text('Envoyer'));
    await pumpFrames(tester);
    verify(() => service.sendRequest(addresseeId: 4)).called(1);
    expect(find.text('Demande envoyée'), findsWidgets);
  });

  testWidgets('relations affichées : Ami, Demande envoyée, Accepter',
      (tester) async {
    when(() => service.searchUsers('ami')).thenAnswer((_) async => const [
          UserSearchResultDto(id: 1, username: 'a', relation: FriendRelation.friends),
          UserSearchResultDto(id: 2, username: 'b', relation: FriendRelation.pendingSent),
          UserSearchResultDto(id: 3, username: 'c', relation: FriendRelation.pendingReceived),
        ]);
    await tester.pumpWidget(page());
    await pumpFrames(tester);
    await search(tester, 'ami');

    expect(find.text('Ami'), findsOneWidget);
    expect(find.text('Demande envoyée'), findsOneWidget);
    expect(find.text('Accepter'), findsOneWidget);
    expect(find.text('Ajouter'), findsNothing);
  });

  testWidgets('échec de la recherche : message d\'échec, pas « aucun '
      'utilisateur »', (tester) async {
    when(() => service.searchUsers(any())).thenThrow(Exception('boom'));
    await tester.pumpWidget(page());
    await pumpFrames(tester);
    await search(tester, 'léa');

    expect(find.text('La recherche a échoué. Réessayez.'), findsOneWidget);
    expect(find.text('Aucun utilisateur trouvé.'), findsNothing);
  });
}
