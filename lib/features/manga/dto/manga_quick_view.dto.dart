

import 'package:mangatracker/core/network/uri_builder.dart';
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

  /// Total EFFECTIF de chapitres = `max(total officiel MU, signalement user)`
  /// (chantier A). L'UI se débloque au-delà du total officiel sans logique
  /// supplémentaire.
  final num? totalChapters;

  /// Total « plus de chapitres » signalé par l'utilisateur (chantier A).
  /// Renvoyé par `/library/all` uniquement si le report dépasse encore le
  /// total officiel — sinon `null`. Informatif : le total officiel exact
  /// n'est pas dérivable de la seule quick view quand un report est actif
  /// (cf. `MangaDetailDto.officialTotalChapters` côté détail).
  final num? userReportedTotalChapters;
  final List<String>? associated;
  final bool hasNewChapters;

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
    this.userReportedTotalChapters,
    this.associated,
    this.hasNewChapters = false,
  });

  /// URL proxy stable côté API (Phase 4) — auto-refresh côté serveur si
  /// MangaUpdates retourne 404. Préférer cette URL à `mediumCoverUrl` /
  /// `smallCoverUrl` dans tous les widgets : zéro placeholder, cache CDN
  /// 30j via NPMplus, et un seul endpoint à invalider en cas de problème.
  ///
  /// [size] : `small` (thumb) ou `medium` (full size, défaut).
  String coverProxyUrl({String size = 'medium'}) =>
      buildApiUri('/mangas/$muId/cover', {'size': size}).toString();

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
        totalChapters: json['totalChapters'],
        userReportedTotalChapters: json['userReportedTotalChapters'] ??
            json['user_reported_total_chapters'],
        associated: (json['associated'] as List?)?.map((e) => e is Map ? (e['title'] ?? e.values.first).toString() : e.toString()).cast<String>().toList(),
        hasNewChapters: json['hasNewChapters'] as bool? ?? false,
    );
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
      'userReportedTotalChapters': userReportedTotalChapters,
      'associated': associated,
      'hasNewChapters': hasNewChapters,
    };
  }
}
