/// Œuvre recommandée depuis une fiche : « si vous avez aimé ce titre… ».
///
/// Les votes MangaUpdates et ceux des utilisateurs Manga Tracker sont
/// comptés séparément par l'API ; l'app affiche leur somme.
class CommunityRecommendationDto {
  final num muId;
  final String title;
  final int? year;
  final String? mediumCoverUrl;
  final double? rating;
  final String? type;
  final int muVotes;
  final int appVotes;
  final int totalVotes;
  final bool recommendedByMe;

  /// Suggestion calculée par MangaUpdates (sans votes) : listée pour que la
  /// liste existe pour presque tous les titres, et recommandable.
  final bool muSuggested;

  const CommunityRecommendationDto({
    required this.muId,
    required this.title,
    this.year,
    this.mediumCoverUrl,
    this.rating,
    this.type,
    this.muVotes = 0,
    this.appVotes = 0,
    this.totalVotes = 0,
    this.recommendedByMe = false,
    this.muSuggested = false,
  });

  factory CommunityRecommendationDto.fromJson(Map<String, dynamic> j) {
    int count(dynamic raw) => int.tryParse('${raw ?? 0}') ?? 0;
    return CommunityRecommendationDto(
      muId: num.tryParse('${j['muId']}') ?? 0,
      title: (j['title'] ?? '').toString(),
      year: int.tryParse('${j['year'] ?? ''}'),
      mediumCoverUrl: j['mediumCoverUrl']?.toString(),
      rating: double.tryParse('${j['rating'] ?? ''}'),
      type: j['type']?.toString(),
      muVotes: count(j['muVotes']),
      appVotes: count(j['appVotes']),
      totalVotes: count(j['totalVotes']),
      recommendedByMe: j['recommendedByMe'] == true,
      muSuggested: j['muSuggested'] == true,
    );
  }

  /// Chaîne de note au format des cartes (`'N/A'` si absente).
  String get ratingLabel => rating == null ? 'N/A' : rating!.toString();

  /// Année au format des cartes (vide si inconnue).
  String get yearLabel => year?.toString() ?? '';
}
