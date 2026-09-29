import 'package:flutter/material.dart';
import 'package:mangatracker/core/theme/app_spacing.dart';
import 'package:mangatracker/features/library/bloc/library_bloc.dart';
import 'package:mangatracker/features/library/bloc/library_event.dart';
import 'package:mangatracker/features/library/widgets/library_section.dart';
import 'package:mangatracker/features/manga/dto/manga_quick_view.dto.dart';
import 'package:mangatracker/features/manga/dto/reading_status.enum.dart';
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
  final LibraryBloc libraryBloc;
  final String Function(MangaQuickViewDto manga) displayNameOf;

  const LibraryListView({
    super.key,
    required this.grouped,
    required this.isExpanded,
    required this.onToggleSection,
    required this.searchQuery,
    required this.showDownloadedOnly,
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

    final sections = grouped.entries.toList(growable: false);
    // `ListView.builder` + clés stables : une frappe dans la recherche ou un
    // rechargement ne recrée plus les sections ni les lignes (et donc plus
    // les images de couverture, dont le rechargement faisait « clignoter »
    // toute la page).
    return ListView.builder(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.m,
        vertical: AppSpacing.s,
      ),
      itemCount: sections.length,
      itemBuilder: (context, index) {
        final status = sections[index].key;
        final items = sections[index].value;
        final expanded = isExpanded[status] ?? true;

        return Padding(
          key: ValueKey(status),
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
              libraryBloc: libraryBloc,
            ),
          ),
        );
      },
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
  final LibraryBloc libraryBloc;

  const _LibrarySectionRows({
    required this.items,
    required this.displayNameOf,
    required this.showDownloadedOnly,
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
          // Le nombre de nouveaux chapitres est calculé une fois par
          // chargement (`LibraryBloc`) : un `FutureBuilder` par ligne
          // relisait les préférences à CHAQUE reconstruction et faisait
          // disparaître puis réapparaître la pastille.
          for (final manga in items)
            MangaRow(
              key: ValueKey(manga.muId),
              muId: manga.muId.toString(),
              mangaName: displayNameOf(manga),
              mangaAuthor: manga.year,
              lastChapter: manga.totalChapters,
              readChapter: manga.readChapters,
              mediumImgPath: manga.mediumCoverUrl,
              rating: manga.rating,
              hasNewChapters: manga.hasNewChapters,
              newChaptersCount:
                  manga.newChaptersCount > 0 ? manga.newChaptersCount : null,
              showDownloadedOnly: showDownloadedOnly,
              onDetailReturn: () => libraryBloc.add(const RefreshLibrary()),
              // V1 : progress bar à la place de la pill
              showProgressBar: true,
            ),
        ],
      ),
    );
  }
}
