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
    return MangaRecommendationView(
      muId: num.parse(json['muId'].toString()),
      title: json['title'],
      year: json['year'].toString(),
      smallCoverUrl: json['smallCoverUrl'],
      mediumCoverUrl: json['mediumCoverUrl'],
      rating:
      json['rating'] == null || json['rating'] == 0
          ? 'N/A'
          : json['rating'].toString(),
      readingStatus:
      json['readingStatus'] != null
          ? ReadingStatusExtension.fromValue(json['readingStatus'])
          : ReadingStatus.readLater,
      inLibrary: json['inLibrary'] as bool? ?? false,
    );
  }
}