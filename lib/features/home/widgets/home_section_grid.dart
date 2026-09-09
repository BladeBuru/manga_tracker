import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:mangatracker/core/components/app_skeleton_box.dart';
import 'package:mangatracker/core/components/library_owned_ids_builder.dart';
import 'package:mangatracker/core/theme/app_breakpoints.dart';
import 'package:mangatracker/core/theme/app_radius.dart';
import 'package:mangatracker/core/theme/app_spacing.dart';
import 'package:mangatracker/features/home/bloc/home_section_page_state.dart';
import 'package:mangatracker/features/home/helpers/home_layout_metrics.dart';
import 'package:mangatracker/features/home/widgets/home_section_card.dart';
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
    final contentWidth = _gridContentWidth(metrics, availableWidth);
    final coverHeight = metrics.gridCoverHeight(contentWidth);
    return SliverMainAxisGroup(
      slivers: [
        SliverPadding(
          padding: EdgeInsets.symmetric(horizontal: metrics.horizontalPadding),
          // `LibraryOwnedIdsBuilder` est un widget de composition : il est
          // transparent dans l'arbre, donc il peut envelopper un sliver.
          sliver: LibraryOwnedIdsBuilder(
            builder: (context, ownedMuIds) => SliverGrid(
              gridDelegate: _gridDelegate(metrics, contentWidth),
              delegate: SliverChildBuilderDelegate(
                (context, index) {
                  final manga = state.items[index];
                  return HomeSectionCard(
                    key: ValueKey('section-card-${manga.muId}'),
                    manga: manga,
                    coverHeight: coverHeight,
                    inLibrary: ownedMuIds.contains(manga.muId.toInt()),
                  );
                },
                childCount: state.items.length,
              ),
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
