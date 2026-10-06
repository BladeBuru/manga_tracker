import 'package:flutter_test/flutter_test.dart';
import 'package:mangatracker/core/bloc/notification_counts_cubit.dart';
import 'package:mangatracker/core/services/notification_counts_service.dart';
import 'package:mangatracker/features/friends/dto/friend.dto.dart';
import 'package:mangatracker/features/friends/services/friends.service.dart';
import 'package:mangatracker/features/manga/services/notification_service.dart';
import 'package:mangatracker/features/sharing/dto/share.dto.dart';
import 'package:mangatracker/features/sharing/services/sharing.service.dart';
import 'package:mocktail/mocktail.dart';

class _Friends extends Mock implements FriendsService {}

class _Sharing extends Mock implements SharingService {}

class _Notifications extends Mock implements NotificationService {}

FriendshipDto _request(int id) => FriendshipDto(
  id: id,
  status: FriendshipStatus.pending,
  direction: FriendshipDirection.received,
  otherUserId: id,
  otherUsername: 'ami$id',
  createdAt: DateTime(2026),
);

MangaShareDto _share(int id, {bool seen = false}) => MangaShareDto(
  id: id,
  senderId: 1,
  senderUsername: 'ami',
  mangaMuId: '$id',
  mangaTitle: 'Titre $id',
  createdAt: DateTime(2026),
  seenAt: seen ? DateTime(2026) : null,
);

void main() {
  late _Friends friends;
  late _Sharing sharing;
  late NotificationCountsService service;

  setUp(() {
    friends = _Friends();
    sharing = _Sharing();
    service = NotificationCountsService(
      friends: friends,
      sharing: sharing,
      notifications: _Notifications(),
    );
  });

  tearDown(() => service.dispose());

  test('compte chaque source séparément (où aller), et le total', () async {
    when(() => friends.getPendingRequests())
        .thenAnswer((_) async => [_request(1), _request(2)]);
    when(() => sharing.getInbox()).thenAnswer(
      (_) async => [_share(1), _share(2, seen: true), _share(3)],
    );

    final counts = await service.refresh();
    expect(counts.pendingFriendRequests, 2);
    expect(counts.unseenShares, 2);
    expect(counts.total, 4);
  });

  test('une source en échec garde sa dernière valeur (pas de clignotement)',
      () async {
    when(() => friends.getPendingRequests())
        .thenAnswer((_) async => [_request(1)]);
    when(() => sharing.getInbox()).thenAnswer((_) async => [_share(1)]);
    await service.refresh();

    when(() => friends.getPendingRequests()).thenThrow(Exception('réseau'));
    when(() => sharing.getInbox()).thenThrow(Exception('réseau'));
    when(() => sharing.getUnseenCount()).thenThrow(Exception('réseau'));
    final counts = await service.refresh();
    expect(counts, const NotificationCounts(
      pendingFriendRequests: 1,
      unseenShares: 1,
    ));
  });

  test('« tout vu » et déconnexion remettent les pastilles à zéro', () async {
    when(() => friends.getPendingRequests())
        .thenAnswer((_) async => [_request(1)]);
    when(() => sharing.getInbox()).thenAnswer((_) async => [_share(1)]);
    await service.refresh();

    service.markSharesSeen();
    expect(service.lastCounts.unseenShares, 0);
    expect(service.lastCounts.pendingFriendRequests, 1);

    service.reset();
    expect(service.lastCounts, NotificationCounts.zero);
  });

  test('le cubit expose les compteurs dès sa création puis à chaque mise '
      'à jour', () async {
    when(() => friends.getPendingRequests())
        .thenAnswer((_) async => [_request(1)]);
    when(() => sharing.getInbox()).thenAnswer((_) async => [_share(1)]);
    await service.refresh();

    final cubit = NotificationCountsCubit(service: service);
    addTearDown(cubit.close);
    expect(cubit.state.total, 2);

    when(() => sharing.getInbox()).thenAnswer((_) async => []);
    await cubit.refresh();
    await Future<void>.delayed(Duration.zero);
    expect(cubit.state.total, 1);
  });
}
