import 'package:mangatracker/features/manga/dto/manga_quick_view.dto.dart';

/// Fiche auteur / dessinateur (`GET /authors/:authorId`) : mini bio issue de
/// MangaUpdates et liste de ses œuvres.
class AuthorDetailsDto {
  final int id;
  final String name;
  final String? actualName;
  final List<String> associatedNames;
  final String? imageUrl;
  final String? bio;
  final String? birthday;
  final String? birthplace;
  final List<String> genres;
  final String? officialSite;
  final List<MangaQuickViewDto> works;

  /// `false` : la liste des œuvres n'a pas pu être chargée entièrement.
  final bool worksComplete;

  const AuthorDetailsDto({
    required this.id,
    required this.name,
    this.actualName,
    this.associatedNames = const [],
    this.imageUrl,
    this.bio,
    this.birthday,
    this.birthplace,
    this.genres = const [],
    this.officialSite,
    this.works = const [],
    this.worksComplete = true,
  });

  static List<String> _strings(dynamic raw) =>
      (raw as List?)?.map((e) => e.toString()).toList() ?? const [];

  static String? _text(dynamic raw) {
    final value = raw?.toString().trim();
    return value == null || value.isEmpty ? null : value;
  }

  factory AuthorDetailsDto.fromJson(Map<String, dynamic> j) {
    final works =
        (j['works'] as List? ?? const [])
            .whereType<Map>()
            .map((w) => w.cast<String, dynamic>())
            .map(
              (w) => MangaQuickViewDto(
                muId: num.tryParse('${w['muId']}') ?? 0,
                title: (w['title'] ?? '').toString(),
                year: w['year'] == null ? '' : '${w['year']}',
                mediumCoverUrl: _text(w['mediumCoverUrl']),
                rating: w['rating'] == null ? 'N/A' : '${w['rating']}',
                type: _text(w['type']),
                genres: _strings(w['genres']),
              ),
            )
            .where((w) => w.muId > 0)
            .toList();
    return AuthorDetailsDto(
      id: int.tryParse('${j['id']}') ?? 0,
      name: (j['name'] ?? '').toString(),
      actualName: _text(j['actualName']),
      associatedNames: _strings(j['associatedNames']),
      imageUrl: _text(j['imageUrl']),
      bio: _text(j['bio']),
      birthday: _text(j['birthday']),
      birthplace: _text(j['birthplace']),
      genres: _strings(j['genres']),
      officialSite: _text(j['officialSite']),
      works: works,
      worksComplete: j['worksComplete'] != false,
    );
  }
}
