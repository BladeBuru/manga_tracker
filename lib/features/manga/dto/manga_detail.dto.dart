import 'package:mangatracker/features/manga/dto/author.dto.dart';
import 'package:mangatracker/features/manga/dto/season_chapter.dto.dart';

class MangaDetailDto {
  final num muId;
  final String title;
  final String? description;
  final String? status;
  final String? publicationStatus;
  final String year;
  final String? smallCoverUrl;
  final String? mediumCoverUrl;
  final String? largeCoverUrl;
  final String rating;
  final int totalChapters;
  final bool? isCompleted;
  final List<AuthorDto>? authors;
  final List<String>? genres;
  final String? customLink;
  final bool inLibrary;
  final int? readChaptersCount;
  final List<String>? associated;
  final List<int>? recommendations;
  final String? type;
  final List<SeasonChapter>? seasonChapters;
  final List<SeasonChapter>? bonusChapters;

  const MangaDetailDto({
    required this.muId,
    required this.title,
    this.description,
    this.status,
    this.publicationStatus,
    required this.year,
    this.smallCoverUrl,
    this.mediumCoverUrl,
    this.largeCoverUrl,
    required this.rating,
    required this.totalChapters,
    this.isCompleted,
    this.authors,
    this.genres,
    this.customLink,
    this.inLibrary = false,
    this.readChaptersCount,
    this.associated,
    this.recommendations,
    this.type,
    this.seasonChapters,
    this.bonusChapters,
  });

  factory MangaDetailDto.fromJson(Map<String, dynamic> j) {
    final authors = (j['authors'] as List?)
        ?.map((e) => e is Map<String, dynamic> ? AuthorDto.fromJson(e) : AuthorDto(name: e.toString(), authorId: 0, type: 'Author'))
        .toList();

    final genres = (j['genres'] as List?)
        ?.map((e) => e is Map ? (e['genre'] ?? e['name'] ?? e).toString() : e.toString())
        .cast<String>()
        .toList();

    final seasons = (j['seasonChapters'] as List?)
        ?.whereType<Map>()
        .map((e) => SeasonChapter.fromJson(e.cast<String, dynamic>()))
        .toList();

    final bonus = (j['bonusChapters'] as List?)
        ?.whereType<Map>()
        .map((e) => SeasonChapter.fromJson(e.cast<String, dynamic>()))
        .toList();

    final ratingRaw = j['rating'];
    final ratingStr = (ratingRaw == null || (ratingRaw is num && ratingRaw == 0)) ? 'N/A' : ratingRaw.toString();

    return MangaDetailDto(
      muId: num.parse((j['muId'] ?? j['mu_id'] ?? 0).toString()),
      title: (j['title'] ?? '').toString(),
      description: (j['description'] ?? j['desc'])?.toString(),
      status: j['status']?.toString(),
      publicationStatus: (j['publicationStatus'] ?? j['publication_status'])?.toString(),
      year: (j['year'] ?? '').toString(),
      smallCoverUrl: (j['smallCoverUrl'] ?? j['small_cover_url'])?.toString(),
      mediumCoverUrl: (j['mediumCoverUrl'] ?? j['medium_cover_url'])?.toString(),
      largeCoverUrl: (j['largeCoverUrl'] ?? j['large_cover_url'])?.toString(),
      rating: ratingStr,
      totalChapters: int.tryParse((j['totalChapters'] ?? j['total_chapters'] ?? 0).toString()) ?? 0,
      isCompleted: (j['completed'] ?? j['isCompleted']) as bool?,
      authors: authors,
      genres: genres,
      customLink: (j['customLink'] ?? j['custom_link'])?.toString(),
      inLibrary: (j['inLibrary'] ?? j['in_library'] ?? false) as bool,
      readChaptersCount: int.tryParse((j['readChaptersCount'] ?? j['read_chapters_count'] ?? '').toString()),
      associated: (j['associated'] as List?)?.map((e) => e is Map ? (e['title'] ?? e.values.first).toString() : e.toString()).cast<String>().toList(),
      recommendations: (j['recommendations'] as List?)?.map((e) => int.tryParse(e.toString()) ?? 0).toList(),
      type: (j['type'] ?? j['kind'])?.toString(),
      seasonChapters: seasons,
      bonusChapters: bonus,
    );
  }
}
