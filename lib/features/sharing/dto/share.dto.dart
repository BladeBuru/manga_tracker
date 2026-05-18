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

  factory MangaShareDto.fromJson(Map<String, dynamic> json) {
    return MangaShareDto(
      id: (json['id'] as num).toInt(),
      senderId: (json['senderId'] as num).toInt(),
      senderUsername: json['senderUsername'] as String? ?? '',
      senderAvatarUrl: json['senderAvatarUrl'] as String?,
      mangaMuId: json['mangaMuId'] as String? ?? '',
      mangaTitle: json['mangaTitle'] as String? ?? '',
      message: json['message'] as String?,
      createdAt: DateTime.tryParse(json['createdAt'] as String? ?? '') ??
          DateTime.now(),
      seenAt: json['seenAt'] != null
          ? DateTime.tryParse(json['seenAt'] as String)
          : null,
    );
  }
}
