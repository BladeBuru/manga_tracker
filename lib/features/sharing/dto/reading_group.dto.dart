import 'package:mangatracker/core/utils/safe_display_name.dart';
/// Membre d'un groupe avec sa progression sur le manga partagé (Phase 8.3).
class ReadingGroupMemberDto {
  final int userId;
  final String username;
  final String? displayName;
  final String? avatarUrl;

  /// Chapitres lus par ce membre. Null = pas encore commencé / pas dans
  /// sa bibliothèque.
  final int? readChapters;

  /// URL de lecture custom (site scanlation) configurée par ce membre pour
  /// ce manga. Null si pas défini. **Utilisé pour la feature "copier le
  /// lien du chapitre d'un ami"** : l'app substitue le numéro de chapitre
  /// dans cette URL par celui de l'user courant via
  /// `ChapterLinkResolver.buildUrlForChapter`.
  final String? customLink;

  final DateTime joinedAt;

  const ReadingGroupMemberDto({
    required this.userId,
    required this.username,
    this.displayName,
    this.avatarUrl,
    this.readChapters,
    this.customLink,
    required this.joinedAt,
  });

  // Jamais d'email affiché (RGPD, hotfix-v0-10-1 US-3).
  String get effectiveDisplayName => stripEmailFormat(
        (displayName?.isNotEmpty ?? false) ? displayName! : username,
      );

  factory ReadingGroupMemberDto.fromJson(Map<String, dynamic> json) {
    return ReadingGroupMemberDto(
      userId: (json['userId'] as num).toInt(),
      username: json['username'] as String? ?? '',
      displayName: json['displayName'] as String?,
      avatarUrl: json['avatarUrl'] as String?,
      readChapters: (json['readChapters'] as num?)?.toInt(),
      customLink: json['customLink'] as String?,
      joinedAt: DateTime.tryParse(json['joinedAt'] as String? ?? '') ??
          DateTime.now(),
    );
  }
}

class ReadingGroupDto {
  final int id;
  final int ownerId;
  final String mangaMuId;
  final String mangaTitle;
  final String? name;
  final DateTime createdAt;
  final List<ReadingGroupMemberDto> members;

  const ReadingGroupDto({
    required this.id,
    required this.ownerId,
    required this.mangaMuId,
    required this.mangaTitle,
    this.name,
    required this.createdAt,
    required this.members,
  });

  /// Helper : le nom affiché du groupe (fallback titre du manga).
  String get effectiveName =>
      (name?.isNotEmpty ?? false) ? name! : mangaTitle;

  factory ReadingGroupDto.fromJson(Map<String, dynamic> json) {
    return ReadingGroupDto(
      id: (json['id'] as num).toInt(),
      ownerId: (json['ownerId'] as num).toInt(),
      mangaMuId: json['mangaMuId'] as String? ?? '',
      mangaTitle: json['mangaTitle'] as String? ?? '',
      name: json['name'] as String?,
      createdAt: DateTime.tryParse(json['createdAt'] as String? ?? '') ??
          DateTime.now(),
      members: (json['members'] as List<dynamic>? ?? [])
          .map((m) => ReadingGroupMemberDto.fromJson(m as Map<String, dynamic>))
          .toList(),
    );
  }
}
