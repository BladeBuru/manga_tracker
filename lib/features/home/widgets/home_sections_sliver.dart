import 'package:flutter/material.dart';
import 'package:mangatracker/core/components/app_empty_state.dart';
import 'package:mangatracker/core/components/app_error_state.dart';
import 'package:mangatracker/features/home/bloc/home_sections_state.dart';
import 'package:mangatracker/features/home/helpers/home_layout_metrics.dart';
import 'package:mangatracker/features/home/widgets/home_section_tile.dart';
import 'package:mangatracker/features/home/widgets/home_sections_skeleton.dart';
import 'package:mangatracker/l10n/app_localizations.dart';

/// Corps de l'accueil catalogue, sous forme de sliver : squelettes pendant
/// le chargement, liste verticale de sections quand elles sont la, etats
/// vide / erreur via les primitives du design system sinon.
class HomeSectionsSliver extends StatelessWidget {
  final HomeSectionsState state;
  final HomeLayoutMetrics metrics;
  final VoidCallback onRetry;

  const HomeSectionsSliver({
    super.key,
    required this.state,
    required this.metrics,
    required this.onRetry,
  });

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final current = state;

    if (current is HomeSectionsError) {
      return SliverToBoxAdapter(
        child: AppErrorState(
          message: l10n.homeSectionsLoadError,
          retryLabel: l10n.retry,
          onRetry: onRetry,
        ),
      );
    }

    if (current is HomeSectionsLoaded) {
      final sections = current.sections;
      if (sections.isEmpty) {
        return SliverToBoxAdapter(
          child: AppEmptyState(
            icon: Icons.auto_stories_outlined,
            title: l10n.homeSectionsEmptyTitle,
            subtitle: l10n.homeSectionsEmptySubtitle,
          ),
        );
      }
      return SliverList.builder(
        itemCount: sections.length,
        itemBuilder: (context, index) => HomeSectionTile(
          key: ValueKey('home-section-${sections[index].id}'),
          section: sections[index],
          metrics: metrics,
        ),
      );
    }

    // Initial / Loading : squelettes aux dimensions du contenu reel.
    return SliverToBoxAdapter(child: HomeSectionsSkeleton(metrics: metrics));
  }
}
