import 'package:mangatracker/features/manga/dto/author.dto.dart';
import 'package:mangatracker/features/manga/dto/season_chapter.dto.dart';

class MangaDetailDto {
  final num muId;
  final String title;
  final String? description;
  final String year;
  final String? mediumCoverUrl;
  final String? largeCoverUrl;
  final String rating;
  final num? totalChapters;
  final bool? isCompleted;
  final List<AuthorDto>? authors;
  final List<String>? genres;
  final String? customLink;
  final bool? inLibrary;
  final int? readChaptersCount;
  final List<String>? associatedTitles;
  final List<SeasonChapter>? seasonChapters;
  final List<SeasonChapter>? bonusChapters;

  const MangaDetailDto({
    required this.muId,
    required this.title,
    required this.description,
    required this.year,
    this.mediumCoverUrl,
    this.largeCoverUrl,
    required this.rating,
    this.totalChapters,
    this.isCompleted,
    this.authors,
    this.genres,
    this.customLink,
    this.inLibrary,
    this.readChaptersCount,
    this.associatedTitles,
    this.seasonChapters,
    this.bonusChapters,
  });

  factory MangaDetailDto.fromJson(Map<String, dynamic> json) {
    final authorsList = (json['authors'] is List)
        ? (json['authors'] as List)
        .whereType<Map>()
        .map((e) => AuthorDto.fromJson(e.cast<String, dynamic>()))
        .toList()
        : null;

    final genresList = (json['genres'] is List)
        ? (json['genres'] as List).map((e) => e.toString()).toList()
        : null;

    final associatedTitles = (json['associated'] is List)
        ? (json['associated'] as List).map((e) => e.toString()).toList()
        : null;

    final seasonChapters = (json['seasonChapters'] is List)
        ? (json['seasonChapters'] as List)
        .whereType<Map>()
        .map((e) => SeasonChapter.fromJson(e.cast<String, dynamic>()))
        .toList()
        : null;

    final bonusChapters = (json['bonusChapters'] is List)
        ? (json['bonusChapters'] as List)
        .whereType<Map>()
        .map((e) => SeasonChapter.fromJson(e.cast<String, dynamic>()))
        .toList()
        : null;

    return MangaDetailDto(
      muId: num.tryParse(json['muId']?.toString() ?? '') ?? 0,
      title: json['title']?.toString() ?? '',
      description: json['description']?.toString(),
      year: json['year']?.toString() ?? '',
      mediumCoverUrl: json['mediumCoverUrl']?.toString(),
      largeCoverUrl: json['smallCoverUrl ']?.toString(),
      rating: (json['rating'] == null || json['rating'] == 0) ? 'N/A' : json['rating'].toString(),
      totalChapters: (json['totalChapters'] is num) ? json['totalChapters'] as num : num.tryParse(json['totalChapters']?.toString() ?? ''),
      isCompleted: json['completed'] as bool?,
      authors: authorsList,
      genres: genresList,
      customLink: json['customLink']?.toString(),
      inLibrary: json['inLibrary'] as bool?,
      readChaptersCount: (json['readChaptersCount'] is int) ? json['readChaptersCount'] as int : int.tryParse(json['readChaptersCount']?.toString() ?? ''),
      associatedTitles: associatedTitles,
      seasonChapters: seasonChapters,
      bonusChapters: bonusChapters,
    );
  }

}
