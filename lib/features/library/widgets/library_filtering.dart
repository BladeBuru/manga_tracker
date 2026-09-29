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
    Set<int>? downloadedMuIds;
    if (showDownloadedOnly) {
      final downloadedChapters =
          await downloadManager.getAllDownloadedChapters();
      downloadedMuIds = downloadedChapters.keys.toSet();
    }
    return apply(
      mangas: mangas,
      searchQuery: searchQuery,
      downloadedMuIds: downloadedMuIds,
    );
  }

  /// Version synchrone de [filter] : aucun accès disque, utilisable pendant
  /// le rendu. [downloadedMuIds] à `null` = pas de filtre « téléchargés ».
  ///
  /// C'est elle que la vue appelle : filtrer via un `Future` créé pendant
  /// le rendu remplaçait toute la liste par un indicateur de chargement à
  /// chaque reconstruction (frappe, clavier, geste retour) — la page
  /// « clignotait ».
  static List<MangaQuickViewDto> apply({
    required List<MangaQuickViewDto> mangas,
    required String searchQuery,
    Set<int>? downloadedMuIds,
  }) {
    List<MangaQuickViewDto> filtered = mangas;

    if (downloadedMuIds != null) {
      filtered =
          filtered
              .where((manga) => downloadedMuIds.contains(manga.muId.toInt()))
              .toList();
    }

    if (searchQuery.isEmpty) return filtered;

    final scored =
        filtered
            .map((manga) {
              final titleMatch = manga.title.toLowerCase().contains(
                searchQuery,
              );
              final associatedMatch =
                  manga.associated?.any(
                    (name) => name.toLowerCase().contains(searchQuery),
                  ) ??
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

/// Mémorise le dernier regroupement calculé pour la vue bibliothèque.
///
/// La vue se reconstruit pour des raisons étrangères aux données (focus de
/// la barre de recherche, ouverture du clavier, geste retour prédictif) :
/// tant que la liste, la recherche et le filtre « téléchargés » n'ont pas
/// changé, le même résultat — la même instance — est rendu.
class LibraryGroupingCache {
  List<MangaQuickViewDto>? _mangas;
  String? _query;
  Set<int>? _downloaded;
  Map<ReadingStatus, List<MangaQuickViewDto>>? _grouped;

  Map<ReadingStatus, List<MangaQuickViewDto>> resolve({
    required List<MangaQuickViewDto> mangas,
    required String searchQuery,
    Set<int>? downloadedMuIds,
  }) {
    final cached = _grouped;
    if (cached != null &&
        identical(mangas, _mangas) &&
        searchQuery == _query &&
        identical(downloadedMuIds, _downloaded)) {
      return cached;
    }
    final filtered = LibraryFiltering.apply(
      mangas: mangas,
      searchQuery: searchQuery,
      downloadedMuIds: downloadedMuIds,
    );
    _mangas = mangas;
    _query = searchQuery;
    _downloaded = downloadedMuIds;
    return _grouped = LibraryFiltering.groupAndSortByStatus(
      filtered,
      searchQuery,
    );
  }
}
