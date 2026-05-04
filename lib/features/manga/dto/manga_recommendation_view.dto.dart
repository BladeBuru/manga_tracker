import 'package:mangatracker/features/manga/dto/reading_status.enum.dart';

class MangaRecommendationView {
  final num muId;
  final String title;
  final String year;
  final String? smallCoverUrl;
  final String? mediumCoverUrl;
  final String rating;
  final ReadingStatus? readingStatus;
  final bool inLibrary;

  const MangaRecommendationView({
    required this.muId,
    required this.title,
    required this.year,
    this.smallCoverUrl,
    this.mediumCoverUrl,
    required this.rating,
    this.readingStatus,
    this.inLibrary = false,
  });

  factory MangaRecommendationView.fromJson(Map<String, dynamic> json) {
    final rawMuId = json['muId'];
    final rawRating = json['rating'];
    return MangaRecommendationView(
      muId: rawMuId != null ? num.parse(rawMuId.toString()) : 0,
      title: (json['title'] as String?) ?? '',
      year: json['year']?.toString() ?? '',
      smallCoverUrl: json['smallCoverUrl'] as String?,
      mediumCoverUrl: json['mediumCoverUrl'] as String?,
      rating: rawRating == null || rawRating == 0
          ? 'N/A'
          : rawRating.toString(),
      readingStatus: json['readingStatus'] != null
          ? ReadingStatusExtension.fromValue(json['readingStatus'])
          : ReadingStatus.readLater,
      inLibrary: json['inLibrary'] as bool? ?? false,
    );
  }
}