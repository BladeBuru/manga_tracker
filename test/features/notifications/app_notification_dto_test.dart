import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mangatracker/features/notifications/dto/app_notification.dto.dart';
import 'package:mangatracker/features/notifications/helpers/notification_grouping.dart';
import 'package:mangatracker/features/notifications/helpers/notification_presenter.dart';
import 'package:mangatracker/l10n/app_localizations.dart';

Map<String, dynamic> _raw(
  String type, {
  Object id = 1,
  Object? actor,
  Object? manga,
  Map<String, dynamic> data = const {},
  String? readAt,
}) =>
    {
      'id': id,
      'type': type,
      'createdAt': '2026-10-13T10:00:00.000Z',
      'readAt': readAt,
      'actor': actor,
      'manga': manga,
      'data': data,
    };

const _lea = {'id': 42, 'username': 'lea', 'displayName': 'Léa'};
const _solo = {'muId': '12345', 'title': 'Solo Leveling', 'coverUrl': null};

void main() {
  final l10n = lookupAppLocalizations(const Locale('fr'));

  group('AppNotificationDto.tryParse', () {
    test('les cinq types connus sont lus', () {
      final types = {
        'friend_request': AppNotificationType.friendRequest,
        'friend_accepted': AppNotificationType.friendAccepted,
        'manga_share': AppNotificationType.mangaShare,
        'reading_group_invite': AppNotificationType.readingGroupInvite,
        'new_chapters': AppNotificationType.newChapters,
      };
      for (final entry in types.entries) {
        final n = AppNotificationDto.tryParse(_raw(entry.key, actor: _lea));
        expect(n?.type, entry.value, reason: entry.key);
      }
    });

    test('type inconnu ou ligne illisible → ignorée, sans erreur', () {
      expect(AppNotificationDto.tryParse(_raw('badge_unlocked')), isNull);
      expect(AppNotificationDto.tryParse({'type': 'friend_request'}), isNull);
      expect(AppNotificationDto.tryParse('pas un objet'), isNull);

      final page = NotificationsPageDto.fromJson({
        'items': [
          _raw('friend_request', id: 1, actor: _lea),
          _raw('badge_unlocked', id: 2),
          42,
        ],
        'unreadCount': 3,
        'nextBefore': '2026-10-12T00:00:00.000Z',
      });
      expect(page.items.map((n) => n.id), ['1']);
      expect(page.unreadCount, 3);
      expect(page.nextBefore, '2026-10-12T00:00:00.000Z');
    });

    test('identifiants en nombre OU en chaîne → toujours une chaîne ; muId '
        'entier depuis une chaîne', () {
      final asInt = AppNotificationDto.tryParse(
        _raw('manga_share', id: 7, actor: _lea, manga: _solo,
            data: {'shareId': 99}),
      )!;
      final asString = AppNotificationDto.tryParse(
        _raw('manga_share', id: '7', actor: {'id': '42', 'username': 'lea'},
            manga: {'muId': 12345, 'title': 'Solo Leveling'},
            data: {'shareId': '99'}),
      )!;
      expect(asInt.id, '7');
      expect(asString.id, '7');
      expect(asInt.actor!.id, '42');
      expect(asString.actor!.id, '42');
      expect(asInt.manga!.muId, 12345);
      expect(asString.manga!.muId, 12345);
      expect(asInt.shareId, '99');
      expect(asString.shareId, '99');
    });

    test('données propres au type', () {
      final group = AppNotificationDto.tryParse(_raw('reading_group_invite',
          actor: _lea, data: {'groupId': 5, 'groupName': 'Berserk avec Léa'}))!;
      expect(group.groupId, '5');
      expect(group.groupName, 'Berserk avec Léa');

      final chapters = AppNotificationDto.tryParse(_raw('new_chapters',
          manga: _solo,
          data: {'latestChapter': 201, 'previousTotal': 198, 'readChapters': 190}))!;
      expect(chapters.newChaptersCount, 3);
      expect(chapters.latestChapterLabel, '201');

      final share = AppNotificationDto.tryParse(_raw('manga_share',
          actor: _lea, manga: _solo, data: {'shareId': 1, 'message': '  '}))!;
      expect(share.shareMessage, isNull, reason: 'message vide = pas de message');
    });

    test('lu / non lu et aller-retour du cache', () {
      final n = AppNotificationDto.tryParse(_raw('friend_request', actor: _lea))!;
      expect(n.isUnread, isTrue);
      final read = n.markedRead(DateTime(2026, 10, 13));
      expect(read.isUnread, isFalse);
      expect(read.markedUnread().isUnread, isTrue);
      expect(AppNotificationDto.tryParse(read.toJson()), read);
    });
  });

  group('NotificationPresenter', () {
    AppNotificationDto parse(String type,
            {Object? manga, Map<String, dynamic> data = const {}}) =>
        AppNotificationDto.tryParse(_raw(type, actor: _lea, manga: manga, data: data))!;

    test('phrases', () {
      expect(NotificationPresenter.text(parse('friend_request'), l10n),
          "Léa vous a envoyé une demande d'ami");
      expect(NotificationPresenter.text(parse('friend_accepted'), l10n),
          "Léa a accepté votre demande d'ami");
      expect(
          NotificationPresenter.text(parse('manga_share', manga: _solo), l10n),
          'Léa vous recommande Solo Leveling');
      expect(
          NotificationPresenter.text(
              parse('reading_group_invite', data: {'groupName': 'Duo'}), l10n),
          'Léa vous a ajouté à la lecture partagée « Duo »');
      expect(
          NotificationPresenter.text(
              parse('new_chapters', manga: _solo,
                  data: {'latestChapter': 201, 'previousTotal': 198}),
              l10n),
          '3 nouveaux chapitres de Solo Leveling (ch. 201)');
    });

    test('destinations', () {
      expect(NotificationPresenter.route(parse('friend_request')),
          '/friends?tab=pending');
      expect(NotificationPresenter.route(parse('friend_accepted')), '/friends/42');
      expect(NotificationPresenter.route(parse('manga_share', manga: _solo)),
          '/manga/12345');
      expect(NotificationPresenter.route(parse('new_chapters', manga: _solo)),
          '/manga/12345');
      expect(
          NotificationPresenter.route(
              parse('reading_group_invite', data: {'groupId': 5})),
          '/reading-groups/5');
    });

    test('clé anti-doublon partagée avec la boîte de réception et les demandes',
        () {
      expect(
          NotificationPresenter.dedupeKey(
              parse('manga_share', data: {'shareId': 99})),
          NotificationPresenter.shareKey(99));
      expect(
          NotificationPresenter.dedupeKey(
              parse('friend_request', data: {'friendshipId': '12'})),
          NotificationPresenter.friendshipKey(12));
    });
  });

  test('regroupement Aujourd\'hui / Hier / Plus tôt', () {
    final now = DateTime(2026, 10, 13, 15);
    AppNotificationDto at(String id, DateTime createdAt) => AppNotificationDto(
          id: id,
          type: AppNotificationType.friendRequest,
          createdAt: createdAt,
        );
    final entries = NotificationGrouping.flatten([
      at('a', DateTime(2026, 10, 13, 9)),
      at('b', DateTime(2026, 10, 12, 23)),
      at('c', DateTime(2026, 10, 12, 1)),
      at('d', DateTime(2026, 9, 1)),
    ], now);
    final days = entries.whereType<NotificationDayHeader>().map((h) => h.day);
    expect(days, [
      NotificationDay.today,
      NotificationDay.yesterday,
      NotificationDay.earlier,
    ]);
    expect(entries.length, 7);
  });
}
