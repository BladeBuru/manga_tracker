import 'package:mangatracker/features/notifications/dto/app_notification.dto.dart';

/// Tranche de jour d'une notification, relative à l'heure locale.
enum NotificationDay { today, yesterday, earlier }

/// Élément de la liste aplatie du centre : un en-tête de jour ou une ligne.
/// Aplatie pour un seul `ListView.builder` (défilement infini).
sealed class NotificationListEntry {
  const NotificationListEntry();
}

class NotificationDayHeader extends NotificationListEntry {
  final NotificationDay day;
  const NotificationDayHeader(this.day);
}

class NotificationItemEntry extends NotificationListEntry {
  final AppNotificationDto notification;
  const NotificationItemEntry(this.notification);
}

/// Regroupement « Aujourd'hui / Hier / Plus tôt ». Pur, testé seul.
class NotificationGrouping {
  const NotificationGrouping._();

  static NotificationDay dayOf(DateTime createdAt, DateTime now) {
    final local = createdAt.toLocal();
    final startOfToday = DateTime(now.year, now.month, now.day);
    if (!local.isBefore(startOfToday)) return NotificationDay.today;
    final startOfYesterday = DateTime(now.year, now.month, now.day - 1);
    if (!local.isBefore(startOfYesterday)) return NotificationDay.yesterday;
    return NotificationDay.earlier;
  }

  /// Liste aplatie, ordre du serveur conservé (plus récentes d'abord), un
  /// en-tête à chaque changement de tranche.
  static List<NotificationListEntry> flatten(
    List<AppNotificationDto> items,
    DateTime now,
  ) {
    final entries = <NotificationListEntry>[];
    NotificationDay? current;
    for (final n in items) {
      final day = dayOf(n.createdAt, now);
      if (day != current) {
        entries.add(NotificationDayHeader(day));
        current = day;
      }
      entries.add(NotificationItemEntry(n));
    }
    return entries;
  }
}
