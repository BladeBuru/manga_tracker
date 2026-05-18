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

  const UserStatsDto({
    required this.mangasByStatus,
    required this.totalChaptersRead,
    required this.estimatedReadingTimeMinutes,
    required this.topGenres,
    required this.lastReadAt,
    required this.completionRate,
    required this.accountCreatedAt,
    required this.totalMangas,
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
      };
}
