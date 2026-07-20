import 'package:mangatracker/features/manga/dto/author.dto.dart';
import 'package:mangatracker/features/manga/dto/season_chapter.dto.dart';
import 'package:mangatracker/features/manga/dto/reading_status.enum.dart';

class MangaDetailDto {
  final num muId;
  final String title;
  final String? description;

  /// Description traduite côté serveur (header Accept-Language).
  /// Absente si la langue est `en` ou non supportée — `description` reste
  /// TOUJOURS l'original anglais.
  final String? translatedDescription;
  final String? status;
  final String? publicationStatus;
  final String year;
  final String? smallCoverUrl;
  final String? mediumCoverUrl;
  final String? largeCoverUrl;
  final String rating;

  /// Total EFFECTIF de chapitres = `max(total officiel, signalement user)`
  /// (chantier A). C'est la valeur affichée (débloque l'UI au-delà du total
  /// officiel).
  final int totalChapters;

  /// Total OFFICIEL de chapitres (MangaUpdates), AVANT application du
  /// signalement utilisateur. Le serveur valide un nouveau signalement contre
  /// `officiel + 200` (chantier A) — c'est cette borne que le dialog doit
  /// utiliser, pas le total effectif. `null` si inconnu (manga hors
  /// bibliothèque / détail non enrichi) → le dialog retombe sur le total
  /// effectif. Renseigné par `DetailBloc._enrichWithLibraryInfo`.
  final int? officialTotalChapters;
  final bool? isCompleted;
  final List<AuthorDto>? authors;
  final List<String>? genres;
  final String? customLink;
  final bool inLibrary;
  final int? readChaptersCount;
  final ReadingStatus? readingStatus;
  final List<String>? associated;
  final List<int>? recommendations;
  final String? type;
  final List<SeasonChapter>? seasonChapters;
  final List<SeasonChapter>? bonusChapters;

  /// Note personnelle de l'utilisateur connecté (0-10, 0 = pas de note).
  final int userRating;

  /// Moyenne des notes des utilisateurs Manga Tracker (null si aucun votant local).
  final double? communityRating;

  /// Nombre d'utilisateurs locaux ayant noté ce manga.
  final int communityRatingCount;

  /// Note agrégée Bayesian (combine la note globale MU et la note communautaire locale).
  final double? aggregatedRating;

  const MangaDetailDto({
    required this.muId,
    required this.title,
    this.description,
    this.translatedDescription,
    this.status,
    this.publicationStatus,
    required this.year,
    this.smallCoverUrl,
    this.mediumCoverUrl,
    this.largeCoverUrl,
    required this.rating,
    required this.totalChapters,
    this.officialTotalChapters,
    this.isCompleted,
    this.authors,
    this.genres,
    this.customLink,
    this.inLibrary = false,
    this.readChaptersCount,
    this.readingStatus,
    this.associated,
    this.recommendations,
    this.type,
    this.seasonChapters,
    this.bonusChapters,
    this.userRating = 0,
    this.communityRating,
    this.communityRatingCount = 0,
    this.aggregatedRating,
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
      translatedDescription:
          (j['translatedDescription'] ?? j['translated_description'])
              ?.toString(),
      status: j['status']?.toString(),
      publicationStatus: (j['publicationStatus'] ?? j['publication_status'])?.toString(),
      year: (j['year'] ?? '').toString(),
      smallCoverUrl: (j['smallCoverUrl'] ?? j['small_cover_url'])?.toString(),
      mediumCoverUrl: (j['mediumCoverUrl'] ?? j['medium_cover_url'])?.toString(),
      largeCoverUrl: (j['largeCoverUrl'] ?? j['large_cover_url'])?.toString(),
      rating: ratingStr,
      totalChapters: int.tryParse((j['totalChapters'] ?? j['total_chapters'] ?? 0).toString()) ?? 0,
      officialTotalChapters: (j['officialTotalChapters'] ?? j['official_total_chapters']) == null
          ? null
          : int.tryParse((j['officialTotalChapters'] ?? j['official_total_chapters']).toString()),
      isCompleted: (j['completed'] ?? j['isCompleted']) as bool?,
      authors: authors,
      genres: genres,
      customLink: (j['customLink'] ?? j['custom_link'])?.toString(),
      inLibrary: (j['inLibrary'] ?? j['in_library'] ?? false) as bool,
      readChaptersCount: int.tryParse((j['readChaptersCount'] ?? j['read_chapters_count'] ?? '').toString()),
      readingStatus: (j['readingStatus'] ?? j['reading_status']) != null 
          ? ReadingStatusExtension.fromValue((j['readingStatus'] ?? j['reading_status']).toString())
          : null,
      associated: (j['associated'] as List?)?.map((e) => e is Map ? (e['title'] ?? e.values.first).toString() : e.toString()).cast<String>().toList(),
      recommendations: (j['recommendations'] as List?)?.map((e) => int.tryParse(e.toString()) ?? 0).toList(),
      type: (j['type'] ?? j['kind'])?.toString(),
      seasonChapters: seasons,
      bonusChapters: bonus,
      userRating: int.tryParse(
            (j['userRating'] ?? j['user_rating'] ?? 0).toString(),
          ) ??
          0,
      communityRating: (j['communityRating'] ?? j['community_rating']) == null
          ? null
          : double.tryParse(
              (j['communityRating'] ?? j['community_rating']).toString(),
            ),
      communityRatingCount: int.tryParse(
            (j['communityRatingCount'] ??
                    j['community_rating_count'] ??
                    0)
                .toString(),
          ) ??
          0,
      aggregatedRating: (j['aggregatedRating'] ?? j['aggregated_rating']) == null
          ? null
          : double.tryParse(
              (j['aggregatedRating'] ?? j['aggregated_rating']).toString(),
            ),
    );
  }

  /// Crée une copie avec un sous-ensemble de champs modifiés.
  /// Utilisé par le DetailBloc pour mettre à jour le DTO sans tout remapper.
  MangaDetailDto copyWith({
    int? userRating,
    double? communityRating,
    int? communityRatingCount,
    double? aggregatedRating,
    bool? inLibrary,
    int? readChaptersCount,
    ReadingStatus? readingStatus,
    String? customLink,
    int? totalChapters,
    int? officialTotalChapters,
    String? translatedDescription,
  }) {
    return MangaDetailDto(
      muId: muId,
      title: title,
      description: description,
      translatedDescription:
          translatedDescription ?? this.translatedDescription,
      status: status,
      publicationStatus: publicationStatus,
      year: year,
      smallCoverUrl: smallCoverUrl,
      mediumCoverUrl: mediumCoverUrl,
      largeCoverUrl: largeCoverUrl,
      rating: rating,
      totalChapters: totalChapters ?? this.totalChapters,
      officialTotalChapters:
          officialTotalChapters ?? this.officialTotalChapters,
      isCompleted: isCompleted,
      authors: authors,
      genres: genres,
      customLink: customLink ?? this.customLink,
      inLibrary: inLibrary ?? this.inLibrary,
      readChaptersCount: readChaptersCount ?? this.readChaptersCount,
      readingStatus: readingStatus ?? this.readingStatus,
      associated: associated,
      recommendations: recommendations,
      type: type,
      seasonChapters: seasonChapters,
      bonusChapters: bonusChapters,
      userRating: userRating ?? this.userRating,
      communityRating: communityRating ?? this.communityRating,
      communityRatingCount: communityRatingCount ?? this.communityRatingCount,
      aggregatedRating: aggregatedRating ?? this.aggregatedRating,
    );
  }
  
  Map<String, dynamic> toJson() {
    return {
      'muId': muId,
      'title': title,
      'description': description,
      'translatedDescription': translatedDescription,
      'status': status,
      'publicationStatus': publicationStatus,
      'year': year,
      'smallCoverUrl': smallCoverUrl,
      'mediumCoverUrl': mediumCoverUrl,
      'largeCoverUrl': largeCoverUrl,
      'rating': rating,
      'totalChapters': totalChapters,
      'officialTotalChapters': officialTotalChapters,
      'isCompleted': isCompleted,
      'authors': authors?.map((e) => e.toJson()).toList(),
      'genres': genres,
      'customLink': customLink,
      'inLibrary': inLibrary,
      'readChaptersCount': readChaptersCount,
      'readingStatus': readingStatus?.name,
      'associated': associated,
      'recommendations': recommendations,
      'type': type,
      'seasonChapters': seasonChapters?.map((e) => e.toJson()).toList(),
      'bonusChapters': bonusChapters?.map((e) => e.toJson()).toList(),
      'userRating': userRating,
      'communityRating': communityRating,
      'communityRatingCount': communityRatingCount,
      'aggregatedRating': aggregatedRating,
    };
  }
}
