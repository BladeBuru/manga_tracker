import 'package:flutter/material.dart';
import 'package:mangatracker/core/components/app_empty_state.dart';
import 'package:mangatracker/core/components/app_error_state.dart';
import 'package:mangatracker/features/home/bloc/home_section_page_state.dart';
import 'package:mangatracker/features/home/helpers/home_layout_metrics.dart';
import 'package:mangatracker/features/home/widgets/home_section_grid.dart';
import 'package:mangatracker/l10n/app_localizations.dart';

/// Corps (sliver) de la page « Tout voir » selon l'etat du BLoC : squelette,
/// grille paginee, section vide, erreur reessayable ou section introuvable.
class HomeSectionPageBody extends StatelessWidget {
  final HomeSectionPageState state;
  final HomeLayoutMetrics metrics;
  final double availableWidth;
  final VoidCallback onRetry;
  final VoidCallback onRetryLoadMore;
  final VoidCallback onBack;

  const HomeSectionPageBody({
    super.key,
    required this.state,
    required this.metrics,
    required this.availableWidth,
    required this.onRetry,
    required this.onRetryLoadMore,
    required this.onBack,
  });

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final current = state;

    if (current is HomeSectionPageError) {
      return SliverFillRemaining(
        hasScrollBody: false,
        child: current.notFound
            ? AppEmptyState(
                icon: Icons.search_off_outlined,
                title: l10n.homeSectionNotFound,
                actionLabel: l10n.back,
                onAction: onBack,
              )
            : AppErrorState(
                message: l10n.homeSectionLoadError,
                retryLabel: l10n.retry,
                onRetry: onRetry,
              ),
      );
    }

    if (current is HomeSectionPageLoaded) {
      if (current.items.isEmpty) {
        return SliverFillRemaining(
          hasScrollBody: false,
          child: AppEmptyState(
            icon: Icons.auto_stories_outlined,
            title: l10n.homeSectionEmpty,
          ),
        );
      }
      return HomeSectionGrid(
        state: current,
        metrics: metrics,
        availableWidth: availableWidth,
        onRetryLoadMore: onRetryLoadMore,
      );
    }

    return HomeSectionGridSkeleton(
      metrics: metrics,
      availableWidth: availableWidth,
    );
  }
}
