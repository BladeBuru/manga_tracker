import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:mangatracker/core/components/app_skeleton_box.dart';
import 'package:mangatracker/core/theme/app_breakpoints.dart';
import 'package:mangatracker/core/theme/app_radius.dart';
import 'package:mangatracker/core/theme/app_spacing.dart';
import 'package:mangatracker/features/home/bloc/home_section_page_state.dart';
import 'package:mangatracker/features/home/helpers/home_layout_metrics.dart';
import 'package:mangatracker/features/home/helpers/home_section_l10n.dart';
import 'package:mangatracker/features/manga/widgets/manga_card.dart';
import 'package:mangatracker/l10n/app_localizations.dart';

/// Largeur utile de la grille : contenu centre (max `contentMaxWidth`) moins
/// le padding horizontal des deux cotes.
double _gridContentWidth(HomeLayoutMetrics metrics, double availableWidth) =>
    math.min(availableWidth, AppBreakpoints.contentMaxWidth) -
    2 * metrics.horizontalPadding;

SliverGridDelegate _gridDelegate(HomeLayoutMetrics metrics, double contentWidth) =>
    SliverGridDelegateWithFixedCrossAxisCount(
      crossAxisCount: metrics.gridColumns,
      crossAxisSpacing: HomeLayoutMetrics.cardGap,
      mainAxisSpacing: AppSpacing.m,
      childAspectRatio: metrics.gridAspectRatio(contentWidth),
    );

/// Grille paginee de la page « Tout voir » + pied de liste (chargement de
/// la page suivante, reessai, ou fin de liste). Slivers, a inserer dans le
/// `CustomScrollView` de la page.
class HomeSectionGrid extends StatelessWidget {
  final HomeSectionPageLoaded state;
  final HomeLayoutMetrics metrics;
  final double availableWidth;
  final VoidCallback onRetryLoadMore;

  const HomeSectionGrid({
    super.key,
    required this.state,
    required this.metrics,
    required this.availableWidth,
    required this.onRetryLoadMore,
  });

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final contentWidth = _gridContentWidth(metrics, availableWidth);
    final coverHeight = metrics.gridCoverHeight(contentWidth);
    return SliverMainAxisGroup(
      slivers: [
        SliverPadding(
          padding: EdgeInsets.symmetric(horizontal: metrics.horizontalPadding),
          sliver: SliverGrid(
            gridDelegate: _gridDelegate(metrics, contentWidth),
            delegate: SliverChildBuilderDelegate(
              (context, index) {
                final manga = state.items[index];
                final rating = manga.rating;
                final type = manga.type;
                return MangaCard(
                  key: ValueKey('section-card-${manga.muId}'),
                  muId: manga.muId.toString(),
                  mangaTitle: manga.title,
                  mangaAuthor: manga.year,
                  mediumImgPath: manga.mediumCoverUrl,
                  rating: rating != 'N/A' && rating.isNotEmpty ? rating : null,
                  coverHeight: coverHeight,
                  badgeLabel: type == null
                      ? null
                      : HomeSectionL10n.mangaType(l10n, type),
                );
              },
              childCount: state.items.length,
            ),
          ),
        ),
        SliverToBoxAdapter(
          child: _GridFooter(state: state, onRetry: onRetryLoadMore),
        ),
      ],
    );
  }
}

class _GridFooter extends StatelessWidget {
  final HomeSectionPageLoaded state;
  final VoidCallback onRetry;

  const _GridFooter({required this.state, required this.onRetry});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final scheme = Theme.of(context).colorScheme;
    final Widget child;
    if (state.isLoadingMore) {
      child = const Center(child: CircularProgressIndicator());
    } else if (state.loadMoreFailed) {
      child = Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            l10n.homeSectionLoadMoreFailed,
            textAlign: TextAlign.center,
            style: Theme.of(context).textTheme.bodySmall,
          ),
          const SizedBox(height: AppSpacing.s),
          FilledButton.tonal(
            onPressed: onRetry,
            style: FilledButton.styleFrom(
              backgroundColor: scheme.primaryContainer,
              foregroundColor: scheme.onPrimaryContainer,
            ),
            child: Text(l10n.retry),
          ),
        ],
      );
    } else if (!state.hasMore) {
      child = Text(
        l10n.homeSectionEndOfList,
        textAlign: TextAlign.center,
        style: Theme.of(context).textTheme.bodySmall?.copyWith(
              color: scheme.onSurfaceVariant,
            ),
      );
    } else {
      return const SizedBox(height: AppSpacing.l);
    }
    return Padding(padding: const EdgeInsets.all(AppSpacing.l), child: child);
  }
}

/// Squelette de la grille pendant le premier chargement de la page.
class HomeSectionGridSkeleton extends StatelessWidget {
  final HomeLayoutMetrics metrics;
  final double availableWidth;

  const HomeSectionGridSkeleton({
    super.key,
    required this.metrics,
    required this.availableWidth,
  });

  @override
  Widget build(BuildContext context) {
    final contentWidth = _gridContentWidth(metrics, availableWidth);
    final coverHeight = metrics.gridCoverHeight(contentWidth);
    return SliverPadding(
      padding: EdgeInsets.symmetric(horizontal: metrics.horizontalPadding),
      sliver: SliverGrid(
        gridDelegate: _gridDelegate(metrics, contentWidth),
        delegate: SliverChildBuilderDelegate(
          (context, index) => Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              AppSkeletonBox(
                width: double.infinity,
                height: coverHeight,
                borderRadius: AppRadius.circularXl,
              ),
              const SizedBox(height: AppSpacing.s),
              const AppSkeletonBox(width: double.infinity, height: AppSpacing.m - 4),
            ],
          ),
          childCount: metrics.gridColumns * 3,
        ),
      ),
    );
  }
}
