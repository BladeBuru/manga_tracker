

import 'package:mangatracker/features/manga/dto/reading_status.enum.dart';

class MangaQuickViewDto {
  final num muId;
  final String title;
  final String year;
  final String? mediumCoverUrl;
  final String? largeCoverUrl;
  final String rating;
  final ReadingStatus? readingStatus ;
  final num? readChapters;
  final num? totalChapters;

  const MangaQuickViewDto({
    required this.muId,
    required this.title,
    required this.year,
    this.mediumCoverUrl,
    this.largeCoverUrl,
    required this.rating,
    this.readingStatus,
    this.readChapters,
    this.totalChapters,
  });

  factory MangaQuickViewDto.fromJson(Map<String, dynamic> json) {
    return MangaQuickViewDto(
        muId: num.parse(json['muId'].toString()),
        title: json['title'],
        year: json['year'].toString(),
        mediumCoverUrl: json['mediumCoverUrl'],
        largeCoverUrl: json['largeCoverUrl'],
        rating: json['rating'] == null || json['rating'] == 0
            ? 'N/A'
            : json['rating'].toString(),
        readingStatus: json['readingStatus'] != null
            ? ReadingStatusExtension.fromValue(json['readingStatus'])
            : ReadingStatus.readLater,
        readChapters: json['readChapters'],
        totalChapters: json['totalChapters']);
  }
}
