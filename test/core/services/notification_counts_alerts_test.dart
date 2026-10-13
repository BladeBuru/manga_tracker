import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mangatracker/core/network/api_exception.dart';
import 'package:mangatracker/core/services/notification_counts_service.dart';
import 'package:mangatracker/features/friends/dto/friend.dto.dart';
import 'package:mangatracker/features/friends/services/friends.service.dart';
import 'package:mangatracker/features/manga/services/notification_preferences_service.dart';
import 'package:mangatracker/features/manga/services/notification_service.dart';
import 'package:mangatracker/features/notifications/dto/app_notification.dto.dart';
import 'package:mangatracker/features/notifications/services/notification_alerter.dart';
import 'package:mangatracker/features/notifications/services/notifications.service.dart';
import 'package:mangatracker/features/sharing/dto/share.dto.dart';
import 'package:mangatracker/features/sharing/services/sharing.service.dart';
import 'package:mangatracker/l10n/app_localizations.dart';
import 'package:mocktail/mocktail.dart';
import 'package:shared_preferences/shared_preferences.dart';

class _Friends extends Mock implements FriendsService {}

class _Sharing extends Mock implements SharingService {}

class _Feed extends Mock implements NotificationsService {}

class _Local extends Mock implements NotificationService {}

FriendshipDto _request(int id) => FriendshipDto(
      id: id,
      status: FriendshipStatus.pending,
      direction: FriendshipDirection.received,
      otherUserId: 100 + id,
      otherUsername: 'ami$id',
      createdAt: DateTime(2026),
    );

MangaShareDto _share(int id) => MangaShareDto(
      id: id,
      senderId: 1,
      senderUsername: 'lea',
      mangaMuId: '$id',
      mangaTitle: 'Titre $id',
      createdAt: DateTime(2026),
    );

AppNotificationDto _friendRequestItem(String id, int friendshipId) =>
    AppNotificationDto(
      id: id,
      type: AppNotificationType.friendRequest,
      createdAt: DateTime(2026, 10, 13),
      actor: const NotificationActor(id: '7', username: 'lea'),
      data: {'friendshipId': friendshipId},
    );

NotificationsPageDto _page(List<AppNotificationDto> items) => NotificationsPageDto(
      items: items,
      unreadCount: items.where((n) => n.isUnread).length,
    );

/// Notifications locales : un seul chemin, première passe silencieuse mais
/// jamais un silence définitif, interrupteurs respectés.
void main() {
  late _Friends friends;
  late _Sharing sharing;
  late _Feed feed;
  late _Local local;
  late NotificationCountsService service;

  setUp(() {
    SharedPreferences.setMockInitialValues({});
    friends = _Friends();
    sharing = _Sharing();
    feed = _Feed();
    local = _Local();
    when(() => local.showFamilyNotification(
          family: any(named: 'family'),
          key: any(named: 'key'),
          title: any(named: 'title'),
          body: any(named: 'body'),
          payload: any(named: 'payload'),
          muId: any(named: 'muId'),
        )).thenAnswer((_) async {});
    when(() => friends.getPendingRequests()).thenAnswer((_) async => []);
    when(() => sharing.getInbox()).thenAnswer((_) async => []);
    service = NotificationCountsService(
      friends: friends,
      sharing: sharing,
      feed: feed,
      alerter: NotificationAlerter(
        notifications: local,
        localizations: () => lookupAppLocalizations(const Locale('fr')),
      ),
    );
  });

  setUpAll(() => registerFallbackValue(NotificationFamily.newChapters));

  tearDown(() => service.dispose());

  List<String> shownKeys() => verify(() => local.showFamilyNotification(
        family: any(named: 'family'),
        key: captureAny(named: 'key'),
        title: any(named: 'title'),
        body: any(named: 'body'),
        payload: any(named: 'payload'),
        muId: any(named: 'muId'),
      )).captured.cast<String>();

  void stubFeed(int unread, List<AppNotificationDto> items) {
    when(() => feed.fetchUnreadCount()).thenAnswer((_) async => unread);
    when(() => feed.fetchPage(limit: any(named: 'limit'), before: any(named: 'before')))
        .thenAnswer((_) async => _page(items));
  }

  test('la cloche suit /notifications/unread-count', () async {
    stubFeed(4, [_friendRequestItem('a', 1)]);
    final counts = await service.refresh();
    expect(counts.unreadNotifications, 4);
    expect(counts.total, 0, reason: 'l\'onglet « Mon compte » garde son total');

    service.setUnreadNotifications(1);
    expect(service.lastCounts.unreadNotifications, 1);
  });

  test('première passe silencieuse, puis la nouvelle demande d\'ami sonne '
      'UNE fois', () async {
    stubFeed(1, [_friendRequestItem('a', 1)]);
    await service.refresh(); // référence : rien ne sonne
    verifyNever(() => local.showFamilyNotification(
          family: any(named: 'family'),
          key: any(named: 'key'),
          title: any(named: 'title'),
          body: any(named: 'body'),
          payload: any(named: 'payload'),
          muId: any(named: 'muId'),
        ));

    stubFeed(2, [_friendRequestItem('b', 2), _friendRequestItem('a', 1)]);
    await service.refresh();
    expect(shownKeys(), ['friendship:2']);

    // Même état au tour suivant : aucun doublon.
    await service.refresh();
    stubFeed(3, [
      _friendRequestItem('c', 3),
      _friendRequestItem('b', 2),
      _friendRequestItem('a', 1),
    ]);
    await service.refresh();
    expect(shownKeys(), ['friendship:3'],
        reason: 'la référence de départ ne rend pas muet pour toujours');
  });

  test('centre disponible : la boîte de réception n\'annonce plus rien '
      '(pas de double notification)', () async {
    stubFeed(0, []);
    when(() => sharing.getInbox()).thenAnswer((_) async => [_share(1)]);
    await service.refresh();
    when(() => sharing.getInbox()).thenAnswer((_) async => [_share(2), _share(1)]);
    await service.refresh();
    verifyNever(() => local.showFamilyNotification(
          family: any(named: 'family'),
          key: any(named: 'key'),
          title: any(named: 'title'),
          body: any(named: 'body'),
          payload: any(named: 'payload'),
          muId: any(named: 'muId'),
        ));
  });

  test('ancien serveur (404) : demandes d\'ami et recommandations prennent '
      'le relais', () async {
    when(() => feed.fetchUnreadCount()).thenThrow(const ApiException(404));
    when(() => friends.getPendingRequests()).thenAnswer((_) async => [_request(1)]);
    when(() => sharing.getInbox()).thenAnswer((_) async => [_share(1)]);
    await service.refresh(); // référence

    when(() => friends.getPendingRequests())
        .thenAnswer((_) async => [_request(2), _request(1)]);
    when(() => sharing.getInbox()).thenAnswer((_) async => [_share(5), _share(1)]);
    await service.refresh();
    expect(shownKeys()..sort(), ['friendship:2', 'share:5']);
  });

  test('interrupteur coupé : la famille ne sonne pas', () async {
    SharedPreferences.setMockInitialValues({
      NotificationFamily.friendRequests.prefsKey: false,
    });
    stubFeed(0, []);
    await service.refresh();
    stubFeed(1, [_friendRequestItem('a', 1)]);
    await service.refresh();
    verifyNever(() => local.showFamilyNotification(
          family: any(named: 'family'),
          key: any(named: 'key'),
          title: any(named: 'title'),
          body: any(named: 'body'),
          payload: any(named: 'payload'),
          muId: any(named: 'muId'),
        ));
  });

  test('déconnexion : tout est oublié, nouvelle référence au compte suivant',
      () async {
    stubFeed(0, []);
    await service.refresh();
    service.reset();
    expect(service.lastCounts, NotificationCounts.zero);

    stubFeed(1, [_friendRequestItem('a', 1)]);
    await service.refresh(); // nouvelle référence : silencieuse
    verifyNever(() => local.showFamilyNotification(
          family: any(named: 'family'),
          key: any(named: 'key'),
          title: any(named: 'title'),
          body: any(named: 'body'),
          payload: any(named: 'payload'),
          muId: any(named: 'muId'),
        ));
    verify(() => sharing.clearCache()).called(1);
  });
}
