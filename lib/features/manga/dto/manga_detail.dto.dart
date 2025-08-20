import 'package:mangatracker/features/manga/dto/author.dto.dart';

class MangaDetailDto {
  final num muId;
  final String title;
  final String? description;
  final String status;
  final String publicationStatus;
  final String year;
  final String? smallCoverUrl;
  final String? mediumCoverUrl;
  final String rating;
  final int totalChapters;
  final bool? isCompleted;
  final List<AuthorDto>? authors;
  final List<String>? genres;
  final List<dynamic> seasonChapters;
  final List<dynamic> bonusChapters;
  final List<String>? associated;
  final List<int>? recommendations;
  final String type;
  final bool inLibrary;

  const MangaDetailDto({
    required this.muId,
    required this.title,
    this.description,
    required this.status,
    required this.publicationStatus,
    required this.year,
    this.smallCoverUrl,
    this.mediumCoverUrl,
    required this.rating,
    required this.totalChapters,
    this.isCompleted,
    this.authors,
    this.genres,
    required this.seasonChapters,
    required this.bonusChapters,
    this.associated,
    this.recommendations,
    required this.type,
    this.inLibrary = false,
  });

  factory MangaDetailDto.fromJson(Map<String, dynamic> json) {
    return MangaDetailDto(
      muId: num.tryParse(json['muId'].toString()) ?? 0,
      title: json['title']?.toString() ?? '',
      description: json['description']?.toString(),
      status: json['status']?.toString() ?? '',
      publicationStatus: json['publicationStatus']?.toString() ?? '',
      year: json['year']?.toString() ?? '',
      rating:
          (json['rating'] == null || json['rating'] == 0)
              ? 'N/A'
              : json['rating'].toString(),
      totalChapters: (json['totalChapters'] as int?) ?? 0,
      isCompleted: json['completed'] as bool?,
      smallCoverUrl: json['smallCoverUrl']?.toString(),
      mediumCoverUrl: json['mediumCoverUrl']?.toString(),
      authors:
          (json['authors'] as List<dynamic>?)
              ?.map((e) => AuthorDto.fromJson(e as Map<String, dynamic>))
              .toList(),
      genres:
          (json['genres'] as List<dynamic>?)?.map((e) => e.toString()).toList(),
      seasonChapters: (json['seasonChapters'] as List<dynamic>?) ?? [],
      bonusChapters: (json['bonusChapters'] as List<dynamic>?) ?? [],
      associated:
          (json['associated'] as List<dynamic>?)
              ?.map((e) => e.toString())
              .toList(),
      recommendations:
          (json['recommendations'] as List<dynamic>?)
              ?.map((e) => int.tryParse(e.toString()) ?? 0)
              .toList(),
      type: json['type']?.toString() ?? '',
      inLibrary: json['inLibrary'] as bool? ?? false,
    );
  }
}
