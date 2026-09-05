import 'package:equatable/equatable.dart';
import 'package:mangatracker/features/home/dto/home_section_kind.dart';
import 'package:mangatracker/features/manga/dto/manga_quick_view.dto.dart';

/// Parametres d'une section (`params` du contrat). Seuls les trois champs
/// connus sont types ; le reste du JSON est ignore.
class HomeSectionParams extends Equatable {
  final String? genre;
  final String? type;
  final int? year;

  const HomeSectionParams({this.genre, this.type, this.year});

  static const HomeSectionParams none = HomeSectionParams();

  factory HomeSectionParams.fromJson(Map<String, dynamic>? json) {
    if (json == null) return none;
    return HomeSectionParams(
      genre: _string(json['genre']),
      type: _string(json['type']),
      year: _int(json['year']),
    );
  }

  Map<String, dynamic> toJson() => {
        if (genre != null) 'genre': genre,
        if (type != null) 'type': type,
        if (year != null) 'year': year,
      };

  static String? _string(dynamic raw) {
    if (raw == null) return null;
    final value = raw.toString().trim();
    return value.isEmpty ? null : value;
  }

  /// L'annee arrive en nombre dans le contrat, mais on tolere une chaine.
  static int? _int(dynamic raw) {
    if (raw is int) return raw;
    if (raw is num) return raw.toInt();
    if (raw is String) return int.tryParse(raw);
    return null;
  }

  @override
  List<Object?> get props => [genre, type, year];
}

/// Une section de l'accueil : identifiant stable (`latest`, `type:Manhwa`,
/// `year:2014`…), nature, parametres et apercu d'items.
class HomeSectionDto extends Equatable {
  final String id;
  final HomeSectionKind kind;
  final HomeSectionParams params;
  final List<MangaQuickViewDto> items;

  const HomeSectionDto({
    required this.id,
    required this.kind,
    this.params = HomeSectionParams.none,
    this.items = const [],
  });

  /// `null` si le `kind` est inconnu (a ignorer) ou si l'`id` manque.
  static HomeSectionDto? tryFromJson(Map<String, dynamic> json) {
    final kind = HomeSectionKind.tryParse(json['kind']);
    final id = json['id'];
    if (kind == null || id is! String || id.isEmpty) return null;
    return HomeSectionDto(
      id: id,
      kind: kind,
      params: HomeSectionParams.fromJson(json['params'] as Map<String, dynamic>?),
      items: parseItems(json['items']),
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'kind': kind.wireValue,
        'params': params.toJson(),
        'items': items.map((m) => m.toJson()).toList(),
      };

  /// Un item mal forme n'entraine pas toute la section : il est saute.
  static List<MangaQuickViewDto> parseItems(dynamic raw) {
    if (raw is! List) return const [];
    final items = <MangaQuickViewDto>[];
    for (final entry in raw) {
      if (entry is! Map<String, dynamic>) continue;
      try {
        items.add(MangaQuickViewDto.fromJson(entry));
      } catch (_) {
        // Item ignore : le contrat garantit le format, mais une ligne
        // corrompue ne doit pas faire disparaitre la section entiere.
      }
    }
    return items;
  }

  @override
  List<Object?> get props => [id, kind, params, items];
}

/// Reponse complete de `GET /mangas/home/sections`, dans l'ordre du serveur.
class HomeSectionsDto extends Equatable {
  final DateTime? generatedAt;
  final List<HomeSectionDto> sections;

  const HomeSectionsDto({this.generatedAt, this.sections = const []});

  factory HomeSectionsDto.fromJson(Map<String, dynamic> json) {
    final raw = json['sections'];
    final sections = <HomeSectionDto>[];
    if (raw is List) {
      for (final entry in raw) {
        if (entry is! Map<String, dynamic>) continue;
        final section = HomeSectionDto.tryFromJson(entry);
        if (section != null) sections.add(section);
      }
    }
    final generatedAt = json['generatedAt'];
    return HomeSectionsDto(
      generatedAt:
          generatedAt is String ? DateTime.tryParse(generatedAt) : null,
      sections: sections,
    );
  }

  Map<String, dynamic> toJson() => {
        'generatedAt': generatedAt?.toIso8601String(),
        'sections': sections.map((s) => s.toJson()).toList(),
      };

  /// Sections qui ont au moins un item a montrer.
  List<HomeSectionDto> get nonEmptySections =>
      sections.where((s) => s.items.isNotEmpty).toList();

  bool get isEmpty => nonEmptySections.isEmpty;

  @override
  List<Object?> get props => [generatedAt, sections];
}

/// Une page de `GET /mangas/home/sections/:id?page&limit`.
class HomeSectionsPageDto extends Equatable {
  final String id;

  /// `null` si le serveur renvoie un `kind` inconnu : la page reste
  /// affichable, seul le titre retombe sur l'identifiant brut.
  final HomeSectionKind? kind;
  final HomeSectionParams params;
  final int page;
  final int limit;
  final int total;
  final List<MangaQuickViewDto> items;

  const HomeSectionsPageDto({
    required this.id,
    required this.kind,
    this.params = HomeSectionParams.none,
    required this.page,
    required this.limit,
    required this.total,
    this.items = const [],
  });

  factory HomeSectionsPageDto.fromJson(Map<String, dynamic> json) {
    return HomeSectionsPageDto(
      id: json['id']?.toString() ?? '',
      kind: HomeSectionKind.tryParse(json['kind']),
      params: HomeSectionParams.fromJson(json['params'] as Map<String, dynamic>?),
      page: HomeSectionParams._int(json['page']) ?? 1,
      limit: HomeSectionParams._int(json['limit']) ?? 0,
      total: HomeSectionParams._int(json['total']) ?? 0,
      items: HomeSectionDto.parseItems(json['items']),
    );
  }

  /// Vrai s'il reste des pages a charger apres celle-ci.
  ///
  /// Le `total` fait foi ; a defaut (0), une page pleine laisse supposer une
  /// suite, une page incomplete signe la fin.
  bool get hasMore {
    if (total > 0) return page * limit < total;
    return limit > 0 && items.length >= limit;
  }

  @override
  List<Object?> get props => [id, kind, params, page, limit, total, items];
}
