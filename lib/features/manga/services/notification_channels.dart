import 'package:mangatracker/features/manga/services/notification_preferences_service.dart';

/// Canal Android d'une famille de notifications + base de sa plage
/// d'identifiants (évite les collisions entre canaux).
///
/// Libellés en français : ils s'affichent dans les réglages du système, pas
/// dans l'application, et sont figés à la création du canal. Dette connue
/// (cf. `known-issues.md`), pas une raison d'en ajouter d'autres en dur.
class NotificationChannel {
  final String id;
  final String label;
  final String description;
  final int idBase;

  const NotificationChannel._(this.id, this.label, this.description, this.idBase);

  /// Taille de chaque plage d'identifiants.
  static const int idRange = 100000;

  static const NotificationChannel newChapters = NotificationChannel._(
    'new_chapters',
    'Nouveaux chapitres',
    'Notifications pour les nouveaux chapitres de manga',
    0,
  );

  static const NotificationChannel friendRequests = NotificationChannel._(
    'friend_requests',
    "Demandes d'ami",
    "Notifications quand quelqu'un vous envoie une demande d'ami",
    1000000,
  );

  static const NotificationChannel sharesReceived = NotificationChannel._(
    'shares_received',
    'Recommandations reçues',
    'Notifications quand un ami vous partage un manga',
    2000000,
  );

  static const NotificationChannel readingGroups = NotificationChannel._(
    'reading_groups',
    'Lectures partagées',
    'Notifications quand un ami vous ajoute à une lecture partagée',
    3000000,
  );

  /// Les demandes acceptées partagent le canal des demandes d'ami.
  static NotificationChannel forFamily(NotificationFamily family) {
    switch (family) {
      case NotificationFamily.newChapters:
        return newChapters;
      case NotificationFamily.friendRequests:
      case NotificationFamily.friendAccepted:
        return friendRequests;
      case NotificationFamily.sharesReceived:
        return sharesReceived;
      case NotificationFamily.readingGroups:
        return readingGroups;
    }
  }

  /// Identifiant stable dans la plage du canal, dérivé d'une clé.
  int idFor(String key) => idBase + (key.hashCode.abs() % idRange);
}
