import 'package:flutter/material.dart';
import 'package:mangatracker/core/theme/app_breakpoints.dart';
import 'package:mangatracker/core/theme/app_spacing.dart';
import 'package:mangatracker/features/library/widgets/library_section.dart';
import 'package:mangatracker/features/manga/dto/manga_quick_view.dto.dart';
import 'package:mangatracker/features/manga/dto/reading_status.enum.dart';
import 'package:mangatracker/features/manga/widgets/manga_card.dart';
import 'package:mangatracker/l10n/app_localizations.dart';

/// Vue grille de la bibliothèque (mode "card").
///
/// Section style V1 (hairline, plus de border rouge) ; MangaCard inchangé.
class LibraryGridView extends StatelessWidget {
  final Map<ReadingStatus, List<MangaQuickViewDto>> grouped;
  final Map<ReadingStatus, bool> isExpanded;
  final ValueChanged<ReadingStatus> onToggleSection;
  final String searchQuery;
  final bool showDownloadedOnly;
  final String Function(MangaQuickViewDto manga) displayNameOf;

  const LibraryGridView({
    super.key,
    required this.grouped,
    required this.isExpanded,
    required this.onToggleSection,
    required this.searchQuery,
    required this.showDownloadedOnly,
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

    // Responsive (audit 2026-06-12) : 3 colonnes était hardcodé → cards
    // gigantesques sur desktop. Colonnes standard AppBreakpoints (3/4/5/6).
    return LayoutBuilder(
      builder: (context, constraints) {
        final bp = AppBreakpoints.of(constraints.maxWidth);
        final sections = grouped.entries.toList(growable: false);
        return ListView.builder(
          padding: const EdgeInsets.symmetric(
            horizontal: AppSpacing.m,
            vertical: AppSpacing.s,
          ),
          itemCount: sections.length,
          itemBuilder: (context, sectionIndex) {
            final status = sections[sectionIndex].key;
            final items = sections[sectionIndex].value;
            final expanded = isExpanded[status] ?? true;

            return Padding(
              key: ValueKey(status),
              padding: const EdgeInsets.only(bottom: 14),
              child: LibrarySection(
                label: status.getLabel(context),
                count: items.length,
                isExpanded: expanded,
                onExpansionChanged: (_) => onToggleSection(status),
                child: Padding(
                  padding: const EdgeInsets.all(AppSpacing.m),
                  child: GridView.builder(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                      crossAxisCount: bp.gridColumns,
                      crossAxisSpacing: 12.0,
                      mainAxisSpacing: 8.0,
                      childAspectRatio: 0.52,
                    ),
                    itemCount: items.length,
                    itemBuilder: (context, index) {
                      final manga = items[index];
                      return MangaCard(
                        // Clé stable : filtrer ne réattribue pas la couverture
                        // d'une carte à un autre titre (rechargement d'image).
                        key: ValueKey(manga.muId),
                        muId: manga.muId.toString(),
                        mangaTitle: displayNameOf(manga),
                        mangaAuthor: manga.year,
                        mediumImgPath: manga.mediumCoverUrl,
                        rating: manga.rating,
                        lastChapter: manga.totalChapters,
                        readChapter: manga.readChapters,
                        showDownloadedOnly: showDownloadedOnly,
                        // V1 mode compact : progression sur la cover en blanc,
                        // pas d'année ni de rating (focus visuel = cover + titre)
                        compactLibrary: true,
                      );
                    },
                  ),
                ),
              ),
            );
          },
        );
      },
    );
  }
}
