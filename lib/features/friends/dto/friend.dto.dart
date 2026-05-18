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
  String get displayName =>
      (otherDisplayName?.isNotEmpty ?? false)
          ? otherDisplayName!
          : otherUsername;

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

class UserSearchResultDto {
  final int id;
  final String username;
  final String? displayName;
  final String? avatarUrl;

  const UserSearchResultDto({
    required this.id,
    required this.username,
    this.displayName,
    this.avatarUrl,
  });

  String get effectiveDisplayName =>
      (displayName?.isNotEmpty ?? false) ? displayName! : username;

  factory UserSearchResultDto.fromJson(Map<String, dynamic> json) {
    return UserSearchResultDto(
      id: (json['id'] as num).toInt(),
      username: json['username'] as String? ?? '',
      displayName: json['displayName'] as String?,
      avatarUrl: json['avatarUrl'] as String?,
    );
  }
}
