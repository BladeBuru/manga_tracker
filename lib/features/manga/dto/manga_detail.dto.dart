
import 'package:mangatracker/features/manga/dto/author.dto.dart';

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

  const MangaDetailDto(
      {required this.muId,
      required this.title,
      required this.description,
      required this.year,
      this.mediumCoverUrl,
      this.largeCoverUrl,
      required this.rating,
      this.totalChapters,
      this.isCompleted,
      this.authors,
      this.genres});

  factory MangaDetailDto.fromJson(Map<String, dynamic> json) {

    final authorsJson = json['authors'] as List<dynamic>?;
    final authorsList = authorsJson
        ?.map((e) => AuthorDto.fromJson(e as Map<String, dynamic>))
        .toList();

    final genresJson = json['genres'] as List<dynamic>?;
    final genresList = genresJson
        ?.map((e) => (e as Map<String, dynamic>)['genre'] as String)
        .toList();

    MangaDetailDto o = MangaDetailDto(
        muId: num.parse(json['mu_id'].toString()),
        title: json['title'],
        description: json['description'],
        year: json['year'].toString(),
        mediumCoverUrl: json['small_cover_url:'],
        largeCoverUrl: json['medium_cover_url:'],
        rating: json['rating'] == null || json['rating'] == 0 ? 'N/A' : json['rating'].toString(),
        totalChapters: json['total_chapters'] ,
        isCompleted: json['completed'] as bool?,
        authors: authorsList,
        genres: genresList,
    );
    return o;
  }
}
