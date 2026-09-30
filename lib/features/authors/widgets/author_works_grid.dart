import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:mangatracker/core/components/library_owned_ids_builder.dart';
import 'package:mangatracker/core/theme/app_breakpoints.dart';
import 'package:mangatracker/core/theme/app_spacing.dart';
import 'package:mangatracker/features/home/helpers/home_layout_metrics.dart';
import 'package:mangatracker/features/home/widgets/home_section_card.dart';
import 'package:mangatracker/features/manga/dto/manga_quick_view.dto.dart';

/// Grille des œuvres d'un auteur (sliver). Mêmes cartes que les pages
/// « Tout voir » de l'accueil : couverture, note, type, pastille « déjà
/// dans ma bibliothèque » ; un appui ouvre la fiche.
class AuthorWorksGrid extends StatelessWidget {
  final List<MangaQuickViewDto> works;
  final HomeLayoutMetrics metrics;
  final double availableWidth;

  const AuthorWorksGrid({
    super.key,
    required this.works,
    required this.metrics,
    required this.availableWidth,
  });

  @override
  Widget build(BuildContext context) {
    final contentWidth =
        math.min(availableWidth, AppBreakpoints.contentMaxWidth) -
        2 * metrics.horizontalPadding;
    final coverHeight = metrics.gridCoverHeight(contentWidth);
    return SliverPadding(
      padding: EdgeInsets.symmetric(horizontal: metrics.horizontalPadding),
      sliver: LibraryOwnedIdsBuilder(
        builder:
            (context, ownedMuIds) => SliverGrid(
              gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: metrics.gridColumns,
                crossAxisSpacing: HomeLayoutMetrics.cardGap,
                mainAxisSpacing: AppSpacing.m,
                childAspectRatio: metrics.gridAspectRatio(contentWidth),
              ),
              delegate: SliverChildBuilderDelegate((context, index) {
                final manga = works[index];
                return HomeSectionCard(
                  key: ValueKey('author-work-${manga.muId}'),
                  manga: manga,
                  coverHeight: coverHeight,
                  inLibrary: ownedMuIds.contains(manga.muId.toInt()),
                );
              }, childCount: works.length),
            ),
      ),
    );
  }
}
