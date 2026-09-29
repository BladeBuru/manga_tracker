/// Synthèse des notes d'une œuvre (`GET /mangas/:muId/ratings`) : note
/// globale (MangaUpdates + Manga Tracker) et total des votes.
class RatingSummaryDto {
  final double? muRating;
  final int? muRatingVotes;
  final double? communityRating;
  final int communityRatingCount;
  final double? aggregatedRating;
  final int totalRatingVotes;

  const RatingSummaryDto({
    this.muRating,
    this.muRatingVotes,
    this.communityRating,
    this.communityRatingCount = 0,
    this.aggregatedRating,
    this.totalRatingVotes = 0,
  });

  static double? _double(dynamic raw) =>
      raw == null ? null : double.tryParse(raw.toString());
  static int? _int(dynamic raw) =>
      raw == null ? null : int.tryParse(raw.toString());

  factory RatingSummaryDto.fromJson(Map<String, dynamic> j) => RatingSummaryDto(
    muRating: _double(j['mu_rating']),
    muRatingVotes: _int(j['mu_rating_votes']),
    communityRating: _double(j['community_rating']),
    communityRatingCount: _int(j['community_rating_count']) ?? 0,
    aggregatedRating: _double(j['aggregated_rating']),
    totalRatingVotes: _int(j['total_rating_votes']) ?? 0,
  );
}
