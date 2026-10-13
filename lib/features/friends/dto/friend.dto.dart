import 'package:mangatracker/core/utils/safe_display_name.dart';
/// Statut d'une relation d'amitié — miroir de `FriendshipStatus` côté API.
enum FriendshipStatus {
  pending('pending'),
  accepted('accepted'),
  blocked('blocked');

  final String value;
  const FriendshipStatus(this.value);

  static FriendshipStatus fromString(String raw) {
    for (final s in FriendshipStatus.values) {
      if (s.value == raw) return s;
    }
    return FriendshipStatus.pending;
  }
}

/// Direction de la relation depuis le point de vue du user courant.
enum FriendshipDirection { sent, received }

class FriendshipDto {
  final int id;
  final FriendshipStatus status;
  final FriendshipDirection direction;
  final int otherUserId;
  final String otherUsername;
  final String? otherDisplayName;
  final String? otherAvatarUrl;
  final DateTime createdAt;
  final DateTime? acceptedAt;

  const FriendshipDto({
    required this.id,
    required this.status,
    required this.direction,
    required this.otherUserId,
    required this.otherUsername,
    this.otherDisplayName,
    this.otherAvatarUrl,
    required this.createdAt,
    this.acceptedAt,
  });

  /// Helper : nom à afficher (fallback username si pas de displayName).
  /// Passé par [stripEmailFormat] — jamais d'email affiché (RGPD).
  String get displayName => stripEmailFormat(
        (otherDisplayName?.isNotEmpty ?? false)
            ? otherDisplayName!
            : otherUsername,
      );

  /// Username sans format email pour les sous-titres `@username` (RGPD).
  String get safeOtherUsername => stripEmailFormat(otherUsername);

  factory FriendshipDto.fromJson(Map<String, dynamic> json) {
    return FriendshipDto(
      id: (json['id'] as num).toInt(),
      status: FriendshipStatus.fromString(json['status'] as String? ?? 'pending'),
      direction: (json['direction'] as String? ?? 'sent') == 'received'
          ? FriendshipDirection.received
          : FriendshipDirection.sent,
      otherUserId: (json['otherUserId'] as num).toInt(),
      otherUsername: json['otherUsername'] as String? ?? '',
      otherDisplayName: json['otherDisplayName'] as String?,
      otherAvatarUrl: json['otherAvatarUrl'] as String?,
      createdAt: DateTime.tryParse(json['createdAt'] as String? ?? '') ??
          DateTime.now(),
      acceptedAt: json['acceptedAt'] != null
          ? DateTime.tryParse(json['acceptedAt'] as String)
          : null,
    );
  }
}

/// Relation entre moi et un résultat de recherche (`relation` de
/// `GET /friends/search`). Absent sur un ancien serveur → [none] (il ne
/// renvoyait alors que des inconnus).
enum FriendRelation {
  none('none'),
  pendingSent('pending_sent'),
  pendingReceived('pending_received'),
  friends('friends');

  final String wire;
  const FriendRelation(this.wire);

  static FriendRelation fromWire(Object? raw) {
    for (final relation in values) {
      if (relation.wire == raw) return relation;
    }
    return FriendRelation.none;
  }
}

class UserSearchResultDto {
  final int id;
  final String username;
  final String? displayName;
  final String? avatarUrl;
  final FriendRelation relation;

  const UserSearchResultDto({
    required this.id,
    required this.username,
    this.displayName,
    this.avatarUrl,
    this.relation = FriendRelation.none,
  });

  String get effectiveDisplayName => stripEmailFormat(
        (displayName?.isNotEmpty ?? false) ? displayName! : username,
      );

  /// Username sans format email pour le sous-titre `@username` (RGPD).
  String get safeUsername => stripEmailFormat(username);

  UserSearchResultDto withRelation(FriendRelation value) => UserSearchResultDto(
        id: id,
        username: username,
        displayName: displayName,
        avatarUrl: avatarUrl,
        relation: value,
      );

  factory UserSearchResultDto.fromJson(Map<String, dynamic> json) {
    final rawId = json['id'];
    return UserSearchResultDto(
      id: rawId is num ? rawId.toInt() : int.tryParse('$rawId') ?? 0,
      username: json['username']?.toString() ?? '',
      displayName: json['displayName'] as String?,
      avatarUrl: json['avatarUrl'] as String?,
      relation: FriendRelation.fromWire(json['relation']),
    );
  }
}
