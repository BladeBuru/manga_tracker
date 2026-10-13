import 'package:mangatracker/features/manga/services/notification_payload.dart';
import 'package:mangatracker/features/notifications/dto/app_notification.dto.dart';
import 'package:mangatracker/l10n/app_localizations.dart';

/// Ce qu'on dit et où l'on va pour une notification. Pur (ni Flutter, ni
/// GetIt) : partagé par le centre de notifications et les notifications
/// locales, testé seul.
class NotificationPresenter {
  const NotificationPresenter._();

  /// Phrase affichée : « Léa vous a envoyé une demande d'ami »,
  /// « 3 nouveaux chapitres de Solo Leveling (ch. 201) »…
  static String text(AppNotificationDto n, AppLocalizations l10n) {
    final name = n.actor?.name ?? l10n.notificationsSomeone;
    final title = (n.manga?.title.trim().isNotEmpty ?? false)
        ? n.manga!.title
        : l10n.notificationsSomeTitle;
    switch (n.type) {
      case AppNotificationType.friendRequest:
        return l10n.notifItemFriendRequest(name);
      case AppNotificationType.friendAccepted:
        return l10n.notifItemFriendAccepted(name);
      case AppNotificationType.mangaShare:
        return l10n.notifItemMangaShare(name, title);
      case AppNotificationType.readingGroupInvite:
        final group = n.groupName;
        return group != null
            ? l10n.notifItemReadingGroupNamed(name, group)
            : l10n.notifItemReadingGroup(name, title);
      case AppNotificationType.newChapters:
        return l10n.notifItemNewChapters(
          n.newChaptersCount,
          title,
          n.latestChapterLabel ?? '?',
        );
    }
  }

  /// Titre de la notification système correspondante.
  static String pushTitle(AppNotificationDto n, AppLocalizations l10n) {
    switch (n.type) {
      case AppNotificationType.friendRequest:
        return l10n.pushNotifFriendRequestTitle;
      case AppNotificationType.friendAccepted:
        return l10n.pushNotifFriendAcceptedTitle;
      case AppNotificationType.mangaShare:
        return l10n.pushNotifShareTitle;
      case AppNotificationType.readingGroupInvite:
        return l10n.pushNotifReadingGroupTitle;
      case AppNotificationType.newChapters:
        return l10n.pushNotifNewChaptersTitle;
    }
  }

  /// Écran ouvert au toucher d'une ligne du centre, ou `null` si la ligne ne
  /// mène nulle part (données incomplètes).
  static String? route(AppNotificationDto n) {
    switch (n.type) {
      case AppNotificationType.friendRequest:
        return '/friends?tab=pending';
      case AppNotificationType.friendAccepted:
        final userId = n.actor?.id;
        return userId != null ? '/friends/$userId' : '/friends';
      case AppNotificationType.mangaShare:
        final muId = n.manga?.muId;
        return muId != null ? '/manga/$muId' : '/inbox';
      case AppNotificationType.readingGroupInvite:
        final groupId = n.groupId;
        return groupId != null ? '/reading-groups/$groupId' : '/reading-groups';
      case AppNotificationType.newChapters:
        final muId = n.manga?.muId;
        return muId != null ? '/manga/$muId' : null;
    }
  }

  /// Contenu de la notification système (cf. [NotificationPayload]).
  ///
  /// Les recommandations ouvrent « Recommandations reçues », comme avant :
  /// c'est cet écran qui les marque comme vues (et, côté serveur, la ligne
  /// du centre comme lue).
  static String payload(AppNotificationDto n) {
    switch (n.type) {
      case AppNotificationType.friendRequest:
        return NotificationPayload.friendRequest;
      case AppNotificationType.friendAccepted:
        final userId = n.actor?.id;
        return userId != null
            ? NotificationPayload.friend(userId)
            : NotificationPayload.centre;
      case AppNotificationType.mangaShare:
        return NotificationPayload.share('${n.manga?.muId ?? ''}');
      case AppNotificationType.readingGroupInvite:
        final groupId = n.groupId;
        return groupId != null
            ? NotificationPayload.readingGroup(groupId)
            : NotificationPayload.centre;
      case AppNotificationType.newChapters:
        final muId = n.manga?.muId;
        return muId != null
            ? NotificationPayload.chapter('$muId')
            : NotificationPayload.centre;
    }
  }

  /// Clé anti-doublon commune à TOUS les chemins de notification locale
  /// (centre, boîte de réception, demandes en attente) : une même demande
  /// d'ami ou une même recommandation ne sonne qu'une fois.
  static String dedupeKey(AppNotificationDto n) {
    switch (n.type) {
      case AppNotificationType.friendRequest:
        return friendshipKey(n.friendshipId ?? 'n${n.id}');
      case AppNotificationType.mangaShare:
        return shareKey(n.shareId ?? 'n${n.id}');
      default:
        return 'notif:${n.id}';
    }
  }

  static String friendshipKey(Object friendshipId) => 'friendship:$friendshipId';
  static String shareKey(Object shareId) => 'share:$shareId';
}
