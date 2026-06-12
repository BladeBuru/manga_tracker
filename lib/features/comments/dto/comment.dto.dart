import 'package:mangatracker/core/utils/safe_display_name.dart';
/// Tri pour la liste des commentaires top-level.
enum CommentSort {
  recent('recent'),
  top('top');

  final String value;
  const CommentSort(this.value);
}

class CommentDto {
  final int id;
  final String content;
  final int? rating;
  final int authorId;
  final String authorUsername;
  final String? authorDisplayName;
  final String? authorAvatarUrl;
  final int? parentCommentId;
  final bool isDeleted;
  final int replyCount;
  final DateTime createdAt;
  final DateTime updatedAt;

  const CommentDto({
    required this.id,
    required this.content,
    this.rating,
    required this.authorId,
    required this.authorUsername,
    this.authorDisplayName,
    this.authorAvatarUrl,
    this.parentCommentId,
    required this.isDeleted,
    required this.replyCount,
    required this.createdAt,
    required this.updatedAt,
  });

  /// Helper : displayName avec fallback username. Passé par
  /// [stripEmailFormat] — jamais d'email affiché (RGPD, hotfix-v0-10-1).
  String get displayName => stripEmailFormat(
        (authorDisplayName?.isNotEmpty ?? false)
            ? authorDisplayName!
            : authorUsername,
      );

  factory CommentDto.fromJson(Map<String, dynamic> json) {
    return CommentDto(
      id: (json['id'] as num).toInt(),
      content: json['content'] as String? ?? '',
      rating: (json['rating'] as num?)?.toInt(),
      authorId: (json['authorId'] as num?)?.toInt() ?? 0,
      authorUsername: json['authorUsername'] as String? ?? '',
      authorDisplayName: json['authorDisplayName'] as String?,
      authorAvatarUrl: json['authorAvatarUrl'] as String?,
      parentCommentId: (json['parentCommentId'] as num?)?.toInt(),
      isDeleted: json['isDeleted'] as bool? ?? false,
      replyCount: (json['replyCount'] as num?)?.toInt() ?? 0,
      createdAt: DateTime.tryParse(json['createdAt'] as String? ?? '') ??
          DateTime.now(),
      updatedAt: DateTime.tryParse(json['updatedAt'] as String? ?? '') ??
          DateTime.now(),
    );
  }
}

/// Réponse paginée de `GET /mangas/:muId/comments`.
class CommentsPage {
  final List<CommentDto> items;
  final int page;
  final bool hasMore;

  const CommentsPage({
    required this.items,
    required this.page,
    required this.hasMore,
  });

  factory CommentsPage.fromJson(Map<String, dynamic> json) {
    return CommentsPage(
      items: (json['items'] as List<dynamic>? ?? [])
          .map((e) => CommentDto.fromJson(e as Map<String, dynamic>))
          .toList(),
      page: (json['page'] as num?)?.toInt() ?? 1,
      hasMore: json['hasMore'] as bool? ?? false,
    );
  }
}
