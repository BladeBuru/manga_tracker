/// Miroir de `ChapterLogEntryDto` côté API (Phase 5).
///
/// Représente une session de lecture additive (replay, skip, bonus,
/// scroll position) — n'altère PAS le compteur de progression principal
/// `userMangaReadChapters` géré séparément par l'endpoint
/// `PUT /library/chapter`.
class ChapterLogDto {
  final int id;
  final num chapterNumber;
  final bool isSkipped;
  final bool isBonus;
  final int? scrollPosition;
  final DateTime readAt;

  const ChapterLogDto({
    required this.id,
    required this.chapterNumber,
    required this.isSkipped,
    required this.isBonus,
    required this.scrollPosition,
    required this.readAt,
  });

  factory ChapterLogDto.fromJson(Map<String, dynamic> json) {
    return ChapterLogDto(
      id: (json['id'] as num).toInt(),
      chapterNumber: (json['chapterNumber'] as num),
      isSkipped: json['isSkipped'] as bool? ?? false,
      isBonus: json['isBonus'] as bool? ?? false,
      scrollPosition: (json['scrollPosition'] as num?)?.toInt(),
      readAt: DateTime.tryParse(json['readAt'] as String? ?? '') ??
          DateTime.now(),
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'chapterNumber': chapterNumber,
        'isSkipped': isSkipped,
        'isBonus': isBonus,
        if (scrollPosition != null) 'scrollPosition': scrollPosition,
        'readAt': readAt.toIso8601String(),
      };
}
