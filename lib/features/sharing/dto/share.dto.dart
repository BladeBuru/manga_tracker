import 'package:mangatracker/core/utils/safe_display_name.dart';

/// Recommandation reçue d'un ami (`GET /sharing/inbox`).
class MangaShareDto {
  final int id;
  final int senderId;
  final String senderUsername;
  final String? senderAvatarUrl;
  final String mangaMuId;
  final String mangaTitle;
  final String? message;
  final DateTime createdAt;
  final DateTime? seenAt;

  const MangaShareDto({
    required this.id,
    required this.senderId,
    required this.senderUsername,
    this.senderAvatarUrl,
    required this.mangaMuId,
    required this.mangaTitle,
    this.message,
    required this.createdAt,
    this.seenAt,
  });

  bool get isNew => seenAt == null;

  /// Nom de l'expéditeur, jamais au format email (RGPD).
  String get senderName => stripEmailFormat(senderUsername);

  /// Message joint, `null` s'il est vide.
  String? get trimmedMessage {
    final value = message?.trim();
    return (value == null || value.isEmpty) ? null : value;
  }

  MangaShareDto markedSeen(DateTime at) => MangaShareDto(
        id: id,
        senderId: senderId,
        senderUsername: senderUsername,
        senderAvatarUrl: senderAvatarUrl,
        mangaMuId: mangaMuId,
        mangaTitle: mangaTitle,
        message: message,
        createdAt: createdAt,
        seenAt: seenAt ?? at,
      );

  /// Identifiants reçus en nombre ou en chaîne (le `muId` est un bigint
  /// côté serveur, sérialisé en chaîne).
  factory MangaShareDto.fromJson(Map<String, dynamic> json) {
    return MangaShareDto(
      id: _int(json['id']),
      senderId: _int(json['senderId']),
      senderUsername: json['senderUsername']?.toString() ?? '',
      senderAvatarUrl: json['senderAvatarUrl'] as String?,
      mangaMuId: json['mangaMuId']?.toString() ?? '',
      mangaTitle: json['mangaTitle']?.toString() ?? '',
      message: json['message'] as String?,
      createdAt: DateTime.tryParse(json['createdAt']?.toString() ?? '') ??
          DateTime.now(),
      seenAt: DateTime.tryParse(json['seenAt']?.toString() ?? ''),
    );
  }

  static int _int(Object? raw) {
    if (raw is num) return raw.toInt();
    return int.tryParse(raw?.toString() ?? '') ?? 0;
  }
}
