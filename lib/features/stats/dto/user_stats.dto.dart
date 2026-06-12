/// DTO miroir de `UserStatsDto` côté API (Phase 2).
///
/// Toutes les valeurs sont calculées côté serveur — pas de logique
/// d'agrégation côté Flutter pour garantir la cohérence offline (cache 1h).
class UserStatsDto {
  /// Compteurs par statut de lecture. Clés possibles : `readLater`,
  /// `reading`, `caughtUp`, `completed`. Garanti non-null (initialisé
  /// côté serveur à 0 pour les statuts absents).
  final Map<String, int> mangasByStatus;

  /// Total des chapitres lus sur toute la biblio.
  final int totalChaptersRead;

  /// Temps de lecture estimé en minutes (chapitres × 4 min en moyenne).
  final int estimatedReadingTimeMinutes;

  /// Top 5 des genres les plus présents dans la biblio.
  final List<String> topGenres;

  /// Date de dernière mise à jour d'un manga — null si biblio vide.
  final DateTime? lastReadAt;

  /// Taux de complétion 0-1.
  final double completionRate;

  /// Date de création du compte.
  final DateTime accountCreatedAt;

  /// Nombre total de mangas dans la biblio.
  final int totalMangas;

  /// Stats v2 — genres avec compteurs (top 10), pour le graphique barres.
  final List<GenreCountDto> genreCounts;

  /// Stats v2 — dernières sessions de lecture (journal, max 20).
  final List<ReadingHistoryEntryDto> readingHistory;

  /// Stats v2 — sessions par semaine (clé = lundi yyyy-MM-dd, 8 semaines).
  final Map<String, int> chaptersPerWeek;

  const UserStatsDto({
    required this.mangasByStatus,
    required this.totalChaptersRead,
    required this.estimatedReadingTimeMinutes,
    required this.topGenres,
    required this.lastReadAt,
    required this.completionRate,
    required this.accountCreatedAt,
    required this.totalMangas,
    this.genreCounts = const [],
    this.readingHistory = const [],
    this.chaptersPerWeek = const {},
  });

  factory UserStatsDto.fromJson(Map<String, dynamic> json) {
    final rawStatus = json['mangasByStatus'] as Map<String, dynamic>? ?? {};
    return UserStatsDto(
      mangasByStatus:
          rawStatus.map((k, v) => MapEntry(k, (v as num?)?.toInt() ?? 0)),
      totalChaptersRead: (json['totalChaptersRead'] as num?)?.toInt() ?? 0,
      estimatedReadingTimeMinutes:
          (json['estimatedReadingTimeMinutes'] as num?)?.toInt() ?? 0,
      topGenres: (json['topGenres'] as List<dynamic>? ?? [])
          .map((e) => e.toString())
          .toList(),
      lastReadAt: json['lastReadAt'] != null
          ? DateTime.tryParse(json['lastReadAt'] as String)
          : null,
      completionRate: (json['completionRate'] as num?)?.toDouble() ?? 0.0,
      accountCreatedAt: DateTime.tryParse(
            json['accountCreatedAt'] as String? ?? '',
          ) ??
          DateTime.now(),
      totalMangas: (json['totalMangas'] as num?)?.toInt() ?? 0,
      genreCounts: (json['genreCounts'] as List<dynamic>? ?? [])
          .map((e) => GenreCountDto.fromJson(e as Map<String, dynamic>))
          .toList(),
      readingHistory: (json['readingHistory'] as List<dynamic>? ?? [])
          .map((e) =>
              ReadingHistoryEntryDto.fromJson(e as Map<String, dynamic>))
          .toList(),
      chaptersPerWeek:
          (json['chaptersPerWeek'] as Map<String, dynamic>? ?? {})
              .map((k, v) => MapEntry(k, (v as num?)?.toInt() ?? 0)),
    );
  }

  Map<String, dynamic> toJson() => {
        'mangasByStatus': mangasByStatus,
        'totalChaptersRead': totalChaptersRead,
        'estimatedReadingTimeMinutes': estimatedReadingTimeMinutes,
        'topGenres': topGenres,
        'lastReadAt': lastReadAt?.toIso8601String(),
        'completionRate': completionRate,
        'accountCreatedAt': accountCreatedAt.toIso8601String(),
        'totalMangas': totalMangas,
        'genreCounts': genreCounts.map((g) => g.toJson()).toList(),
        'readingHistory': readingHistory.map((h) => h.toJson()).toList(),
        'chaptersPerWeek': chaptersPerWeek,
      };
}

/// Genre + nombre de mangas de la biblio dans ce genre (Stats v2).
class GenreCountDto {
  final String genre;
  final int count;

  const GenreCountDto({required this.genre, required this.count});

  factory GenreCountDto.fromJson(Map<String, dynamic> json) => GenreCountDto(
        genre: json['genre'] as String? ?? '',
        count: (json['count'] as num?)?.toInt() ?? 0,
      );

  Map<String, dynamic> toJson() => {'genre': genre, 'count': count};
}

/// Session de lecture du journal (Stats v2 — historique).
class ReadingHistoryEntryDto {
  final int muId;
  final String mangaTitle;
  final num chapterNumber;
  final bool isBonus;
  final DateTime readAt;

  const ReadingHistoryEntryDto({
    required this.muId,
    required this.mangaTitle,
    required this.chapterNumber,
    required this.isBonus,
    required this.readAt,
  });

  factory ReadingHistoryEntryDto.fromJson(Map<String, dynamic> json) =>
      ReadingHistoryEntryDto(
        muId: (json['muId'] as num?)?.toInt() ?? 0,
        mangaTitle: json['mangaTitle'] as String? ?? '',
        chapterNumber: json['chapterNumber'] as num? ?? 0,
        isBonus: json['isBonus'] as bool? ?? false,
        readAt: DateTime.tryParse(json['readAt'] as String? ?? '') ??
            DateTime.now(),
      );

  Map<String, dynamic> toJson() => {
        'muId': muId,
        'mangaTitle': mangaTitle,
        'chapterNumber': chapterNumber,
        'isBonus': isBonus,
        'readAt': readAt.toIso8601String(),
      };
}
