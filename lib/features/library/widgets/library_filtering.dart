import 'package:mangatracker/features/download/services/download_manager_service.dart';
import 'package:mangatracker/features/manga/dto/manga_quick_view.dto.dart';
import 'package:mangatracker/features/manga/dto/reading_status.enum.dart';

/// Helpers de filtrage / scoring / regroupement de la bibliothèque, extraits
/// de `library_bloc_view.dart` pour respecter la limite des 400 lignes.
///
/// Pure logique métier — ne dépend pas de BuildContext.
class LibraryFiltering {
  LibraryFiltering._();

  /// Score de pertinence d'un manga pour une recherche.
  static int calculateMatchScore(MangaQuickViewDto manga, String query) {
    if (query.isEmpty) return 0;

    final queryLower = query.toLowerCase();
    int maxScore = 0;

    final titleLower = manga.title.toLowerCase();
    if (titleLower == queryLower) {
      maxScore = 1000;
    } else if (titleLower.startsWith(queryLower)) {
      maxScore = 500;
    } else if (titleLower.contains(queryLower)) {
      maxScore = 100;
    }

    final associated = manga.associated;
    if (associated != null) {
      for (final name in associated) {
        final nameLower = name.toLowerCase();
        int score = 0;
        if (nameLower == queryLower) {
          score = 900;
        } else if (nameLower.startsWith(queryLower)) {
          score = 450;
        } else if (nameLower.contains(queryLower)) {
          score = 90;
        }
        if (score > maxScore) maxScore = score;
      }
    }
    return maxScore;
  }

  /// Filtre par recherche + downloaded-only, puis trie par score.
  static Future<List<MangaQuickViewDto>> filter({
    required List<MangaQuickViewDto> mangas,
    required String searchQuery,
    required bool showDownloadedOnly,
    required DownloadManagerService downloadManager,
  }) async {
    List<MangaQuickViewDto> filtered = mangas;

    if (showDownloadedOnly) {
      final downloadedChapters =
          await downloadManager.getAllDownloadedChapters();
      final downloadedMuIds = downloadedChapters.keys.toSet();
      filtered = filtered
          .where((manga) => downloadedMuIds.contains(manga.muId.toInt()))
          .toList();
    }

    if (searchQuery.isEmpty) return filtered;

    final scored = filtered
        .map((manga) {
          final titleMatch = manga.title.toLowerCase().contains(searchQuery);
          final associatedMatch = manga.associated?.any(
                  (name) => name.toLowerCase().contains(searchQuery)) ??
              false;
          if (titleMatch || associatedMatch) {
            return MapEntry(manga, calculateMatchScore(manga, searchQuery));
          }
          return null;
        })
        .whereType<MapEntry<MangaQuickViewDto, int>>()
        .toList();

    scored.sort((a, b) => b.value.compareTo(a.value));
    return scored.map((e) => e.key).toList();
  }

  /// Retourne le titre alternatif qui matche la query, sinon le titre principal.
  static String displayNameOf(MangaQuickViewDto manga, String searchQuery) {
    if (searchQuery.isEmpty) return manga.title;
    final queryLower = searchQuery.toLowerCase();
    final titleLower = manga.title.toLowerCase();
    if (titleLower.contains(queryLower)) return manga.title;
    final associated = manga.associated;
    if (associated != null) {
      for (final name in associated) {
        if (name.toLowerCase().contains(queryLower)) return name;
      }
    }
    return manga.title;
  }

  /// Groupe par statut + tri par pertinence si recherche active.
  static Map<ReadingStatus, List<MangaQuickViewDto>> groupAndSortByStatus(
    List<MangaQuickViewDto> mangas,
    String searchQuery,
  ) {
    final grouped = <ReadingStatus, List<MangaQuickViewDto>>{};
    for (final status in ReadingStatus.values) {
      final statusMangas =
          mangas.where((m) => m.readingStatus == status).toList();
      if (searchQuery.isNotEmpty) {
        statusMangas.sort((a, b) {
          final scoreA = calculateMatchScore(a, searchQuery);
          final scoreB = calculateMatchScore(b, searchQuery);
          return scoreB.compareTo(scoreA);
        });
      }
      if (statusMangas.isNotEmpty) {
        grouped[status] = statusMangas;
      }
    }
    return grouped;
  }
}
