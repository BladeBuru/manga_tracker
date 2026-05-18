import 'package:flutter/material.dart';
import 'package:mangatracker/core/theme/app_spacing.dart';
import 'package:mangatracker/features/library/bloc/library_bloc.dart';
import 'package:mangatracker/features/library/bloc/library_event.dart';
import 'package:mangatracker/features/library/widgets/library_section.dart';
import 'package:mangatracker/features/manga/dto/manga_quick_view.dto.dart';
import 'package:mangatracker/features/manga/dto/reading_status.enum.dart';
import 'package:mangatracker/features/manga/services/new_chapter_service.dart';
import 'package:mangatracker/features/manga/widgets/manga_row.dart';
import 'package:mangatracker/l10n/app_localizations.dart';

/// Vue liste de la bibliothèque (mode "row").
///
/// **V1 « Refined Classic »** : chaque statut est rendu dans une
/// `LibrarySection` (card hairline, plus aucune border rouge). Les rows
/// utilisent `MangaRow(showProgressBar: true)` → barre de progression à
/// la place de la pill "X / Y chapitres".
class LibraryListView extends StatelessWidget {
  final Map<ReadingStatus, List<MangaQuickViewDto>> grouped;
  final Map<ReadingStatus, bool> isExpanded;
  final ValueChanged<ReadingStatus> onToggleSection;
  final String searchQuery;
  final bool showDownloadedOnly;
  final NewChapterService newChapterService;
  final LibraryBloc libraryBloc;
  final String Function(MangaQuickViewDto manga) displayNameOf;

  const LibraryListView({
    super.key,
    required this.grouped,
    required this.isExpanded,
    required this.onToggleSection,
    required this.searchQuery,
    required this.showDownloadedOnly,
    required this.newChapterService,
    required this.libraryBloc,
    required this.displayNameOf,
  });

  @override
  Widget build(BuildContext context) {
    if (grouped.isEmpty && searchQuery.isNotEmpty) {
      return Center(
        child: Text(
          AppLocalizations.of(context)?.noData ?? 'Aucun résultat trouvé.',
        ),
      );
    }

    return ListView(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.m,
        vertical: AppSpacing.s,
      ),
      children: grouped.entries.map((entry) {
        final status = entry.key;
        final items = entry.value;
        final expanded = isExpanded[status] ?? true;

        return Padding(
          padding: const EdgeInsets.only(bottom: 14),
          child: LibrarySection(
            label: status.getLabel(context),
            count: items.length,
            isExpanded: expanded,
            onExpansionChanged: (_) => onToggleSection(status),
            child: _LibrarySectionRows(
              items: items,
              displayNameOf: displayNameOf,
              showDownloadedOnly: showDownloadedOnly,
              newChapterService: newChapterService,
              libraryBloc: libraryBloc,
            ),
          ),
        );
      }).toList(),
    );
  }
}

/// Liste verticale de `MangaRow` pour une section.
///
/// **Fix 2026-05-18** : retrait des hairline dividers entre rows. Chaque
/// `MangaRow` a déjà sa propre bordure hairline + radius 16 (refactor V1)
/// → ajouter un divider créait une double séparation visuellement parasite.
/// L'espace vertical entre rows (`bottom: 10` interne au MangaRow) suffit.
class _LibrarySectionRows extends StatelessWidget {
  final List<MangaQuickViewDto> items;
  final String Function(MangaQuickViewDto manga) displayNameOf;
  final bool showDownloadedOnly;
  final NewChapterService newChapterService;
  final LibraryBloc libraryBloc;

  const _LibrarySectionRows({
    required this.items,
    required this.displayNameOf,
    required this.showDownloadedOnly,
    required this.newChapterService,
    required this.libraryBloc,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      // Padding global pour la liste (au lieu de padding par-row), avec un
      // peu plus de top que bottom pour respirer après le header hairline.
      padding: const EdgeInsets.fromLTRB(
        AppSpacing.s,
        AppSpacing.m,
        AppSpacing.s,
        AppSpacing.s,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          for (final manga in items)
            FutureBuilder<int>(
              future: newChapterService.getNewChaptersCount(manga.muId.toInt()),
              builder: (context, snapshot) {
                final newChaptersCount = snapshot.data ?? 0;
                return MangaRow(
                  muId: manga.muId.toString(),
                  mangaName: displayNameOf(manga),
                  mangaAuthor: manga.year,
                  lastChapter: manga.totalChapters,
                  readChapter: manga.readChapters,
                  mediumImgPath: manga.mediumCoverUrl,
                  rating: manga.rating,
                  hasNewChapters: manga.hasNewChapters,
                  newChaptersCount:
                      newChaptersCount > 0 ? newChaptersCount : null,
                  showDownloadedOnly: showDownloadedOnly,
                  onDetailReturn: () =>
                      libraryBloc.add(const RefreshLibrary()),
                  // V1 : progress bar à la place de la pill
                  showProgressBar: true,
                );
              },
            ),
        ],
      ),
    );
  }
}
