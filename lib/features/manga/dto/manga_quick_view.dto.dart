

import 'package:mangatracker/features/manga/dto/reading_status.enum.dart';

class MangaQuickViewDto {
  final num muId;
  final String title;
  final String year;
  final String? smallCoverUrl;
  final String? mediumCoverUrl;
  final String rating;
  final ReadingStatus? readingStatus ;
  final num? readChapters;
  final num? totalChapters;

  const MangaQuickViewDto({
    required this.muId,
    required this.title,
    required this.year,
    this.smallCoverUrl,
    this.mediumCoverUrl,
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
        smallCoverUrl: json['smallCoverUrl'],
        mediumCoverUrl: json['mediumCoverUrl'],
        rating: json['rating'] == null || json['rating'] == 0
            ? 'N/A'
            : json['rating'].toString(),
        readingStatus: json['readingStatus'] != null
            ? ReadingStatusExtension.fromValue(json['readingStatus'])
            : ReadingStatus.readLater,
        readChapters: json['readChapters'],
        totalChapters: json['totalChapters']);
  }
  
  Map<String, dynamic> toJson() {
    return {
      'muId': muId,
      'title': title,
      'year': year,
      'smallCoverUrl': smallCoverUrl,
      'mediumCoverUrl': mediumCoverUrl,
      'rating': rating,
      'readingStatus': readingStatus?.name,
      'readChapters': readChapters,
      'totalChapters': totalChapters,
    };
  }
}
