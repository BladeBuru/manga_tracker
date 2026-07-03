import 'manga_quick_view.dto.dart';

/// Une page de résultats renvoyée par `POST /mangas/search` (enveloppe
/// `{results, totalHits, page, perPage, hasMore}`), triée par pertinence
/// (classement MangaUpdates, identique au site).
class SearchResultsPageDto {
  final List<MangaQuickViewDto> results;
  final int totalHits;
  final int page;
  final int perPage;
  final bool hasMore;

  const SearchResultsPageDto({
    required this.results,
    required this.totalHits,
    required this.page,
    required this.perPage,
    required this.hasMore,
  });

  factory SearchResultsPageDto.fromJson(Map<String, dynamic> json) {
    final rawResults = json['results'] as List<dynamic>? ?? const [];
    final results = rawResults
        .map((e) => MangaQuickViewDto.fromJson(e as Map<String, dynamic>))
        .toList();
    return SearchResultsPageDto(
      results: results,
      totalHits: (json['totalHits'] as num?)?.toInt() ?? results.length,
      page: (json['page'] as num?)?.toInt() ?? 1,
      perPage: (json['perPage'] as num?)?.toInt() ?? results.length,
      hasMore: json['hasMore'] as bool? ?? false,
    );
  }
}
