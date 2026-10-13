import 'package:equatable/equatable.dart';
import 'package:mangatracker/core/utils/safe_display_name.dart';

/// Familles de notifications du centre (`GET /notifications`).
///
/// Un type inconnu du client (serveur plus récent) n'a PAS d'entrée ici : la
/// ligne est ignorée au parsing (cf. [AppNotificationDto.tryParse]), jamais
/// une erreur — même règle que les sections de l'accueil.
enum AppNotificationType {
  friendRequest('friend_request'),
  friendAccepted('friend_accepted'),
  mangaShare('manga_share'),
  readingGroupInvite('reading_group_invite'),
  newChapters('new_chapters');

  final String wire;
  const AppNotificationType(this.wire);

  static AppNotificationType? fromWire(Object? raw) {
    for (final type in values) {
      if (type.wire == raw) return type;
    }
    return null;
  }
}

/// Identifiant reçu en nombre OU en chaîne → toujours une chaîne.
String? parseId(Object? raw) {
  if (raw == null) return null;
  if (raw is num) return raw.toInt().toString();
  final value = raw.toString().trim();
  return value.isEmpty ? null : value;
}

/// Entier reçu en nombre OU en chaîne (`"201"`, `201`, `201.0`).
int? parseInt(Object? raw) {
  if (raw is num) return raw.toInt();
  if (raw is String) {
    return int.tryParse(raw.trim()) ?? double.tryParse(raw.trim())?.toInt();
  }
  return null;
}

/// Numéro de chapitre lisible : `201`, `201.5` (jamais `201.0`).
String? parseChapterLabel(Object? raw) {
  final value = raw is num ? raw : (raw is String ? num.tryParse(raw) : null);
  if (value == null) return null;
  return value == value.roundToDouble() ? value.toInt().toString() : '$value';
}

/// Auteur d'une notification (celui qui a agi).
class NotificationActor extends Equatable {
  final String id;
  final String username;
  final String? displayName;

  const NotificationActor({
    required this.id,
    required this.username,
    this.displayName,
  });

  /// Nom affiché ; passé par [stripEmailFormat] — jamais d'email (RGPD).
  String get name => stripEmailFormat(
        (displayName?.trim().isNotEmpty ?? false) ? displayName! : username,
      );

  static NotificationActor? tryParse(Object? raw) {
    if (raw is! Map) return null;
    final id = parseId(raw['id']);
    if (id == null) return null;
    return NotificationActor(
      id: id,
      username: raw['username']?.toString() ?? '',
      displayName: raw['displayName']?.toString(),
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'username': username,
        'displayName': displayName,
      };

  @override
  List<Object?> get props => [id, username, displayName];
}

/// Titre concerné par une notification.
class NotificationManga extends Equatable {
  final int muId;
  final String title;
  final String? coverUrl;

  const NotificationManga({
    required this.muId,
    required this.title,
    this.coverUrl,
  });

  static NotificationManga? tryParse(Object? raw) {
    if (raw is! Map) return null;
    final muId = parseInt(raw['muId']);
    if (muId == null || muId <= 0) return null;
    return NotificationManga(
      muId: muId,
      title: raw['title']?.toString() ?? '',
      coverUrl: raw['coverUrl']?.toString(),
    );
  }

  Map<String, dynamic> toJson() => {
        'muId': muId,
        'title': title,
        'coverUrl': coverUrl,
      };

  @override
  List<Object?> get props => [muId, title, coverUrl];
}

/// Une ligne du centre de notifications.
class AppNotificationDto extends Equatable {
  final String id;
  final AppNotificationType type;
  final DateTime createdAt;
  final DateTime? readAt;
  final NotificationActor? actor;
  final NotificationManga? manga;

  /// Champs propres au type (`friendshipId`, `shareId`, `groupId`…), lus par
  /// les accesseurs ci-dessous.
  final Map<String, dynamic> data;

  const AppNotificationDto({
    required this.id,
    required this.type,
    required this.createdAt,
    this.readAt,
    this.actor,
    this.manga,
    this.data = const {},
  });

  bool get isUnread => readAt == null;

  String? get friendshipId => parseId(data['friendshipId']);
  String? get shareId => parseId(data['shareId']);
  String? get groupId => parseId(data['groupId']);

  String? get shareMessage {
    final message = data['message']?.toString().trim();
    return (message == null || message.isEmpty) ? null : message;
  }

  String? get groupName {
    final name = data['groupName']?.toString().trim();
    return (name == null || name.isEmpty) ? null : name;
  }

  /// Dernier chapitre paru (libellé lisible).
  String? get latestChapterLabel => parseChapterLabel(data['latestChapter']);

  /// Nombre de chapitres parus depuis le dernier total connu (au moins 1).
  int get newChaptersCount {
    final latest = parseInt(data['latestChapter']);
    final previous = parseInt(data['previousTotal']);
    if (latest == null || previous == null) return 1;
    final diff = latest - previous;
    return diff < 1 ? 1 : diff;
  }

  /// `null` si la ligne est illisible ou d'un type inconnu : elle est ignorée.
  static AppNotificationDto? tryParse(Object? raw) {
    if (raw is! Map) return null;
    final type = AppNotificationType.fromWire(raw['type']);
    final id = parseId(raw['id']);
    final createdAt = DateTime.tryParse(raw['createdAt']?.toString() ?? '');
    if (type == null || id == null || createdAt == null) return null;
    final data = raw['data'];
    return AppNotificationDto(
      id: id,
      type: type,
      createdAt: createdAt,
      readAt: DateTime.tryParse(raw['readAt']?.toString() ?? ''),
      actor: NotificationActor.tryParse(raw['actor']),
      manga: NotificationManga.tryParse(raw['manga']),
      data: data is Map ? Map<String, dynamic>.from(data) : const {},
    );
  }

  AppNotificationDto markedRead(DateTime at) => AppNotificationDto(
        id: id,
        type: type,
        createdAt: createdAt,
        readAt: readAt ?? at,
        actor: actor,
        manga: manga,
        data: data,
      );

  /// Rétablit la ligne non lue (échec d'une lecture optimiste).
  AppNotificationDto markedUnread() => AppNotificationDto(
        id: id,
        type: type,
        createdAt: createdAt,
        actor: actor,
        manga: manga,
        data: data,
      );

  Map<String, dynamic> toJson() => {
        'id': id,
        'type': type.wire,
        'createdAt': createdAt.toIso8601String(),
        'readAt': readAt?.toIso8601String(),
        'actor': actor?.toJson(),
        'manga': manga?.toJson(),
        'data': data,
      };

  @override
  List<Object?> get props => [id, type, createdAt, readAt, actor, manga, data];
}

/// Une page de `GET /notifications`.
class NotificationsPageDto extends Equatable {
  final List<AppNotificationDto> items;
  final int unreadCount;

  /// Curseur de la page suivante (`before`), `null` en fin de liste.
  final String? nextBefore;

  const NotificationsPageDto({
    required this.items,
    required this.unreadCount,
    this.nextBefore,
  });

  static const NotificationsPageDto empty =
      NotificationsPageDto(items: [], unreadCount: 0);

  factory NotificationsPageDto.fromJson(Object? raw) {
    if (raw is! Map) return empty;
    final rawItems = raw['items'];
    final items = rawItems is List
        ? rawItems
            .map(AppNotificationDto.tryParse)
            .whereType<AppNotificationDto>()
            .toList()
        : <AppNotificationDto>[];
    final unread = parseInt(raw['unreadCount']);
    final next = raw['nextBefore']?.toString();
    return NotificationsPageDto(
      items: items,
      unreadCount: unread ?? items.where((n) => n.isUnread).length,
      nextBefore: (next == null || next.isEmpty) ? null : next,
    );
  }

  Map<String, dynamic> toJson() => {
        'items': [for (final n in items) n.toJson()],
        'unreadCount': unreadCount,
        'nextBefore': nextBefore,
      };

  @override
  List<Object?> get props => [items, unreadCount, nextBefore];
}
