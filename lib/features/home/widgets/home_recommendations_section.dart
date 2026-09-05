import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:mangatracker/core/components/pastel_tile.dart';
import 'package:mangatracker/core/theme/app_spacing.dart';
import 'package:mangatracker/features/home/bloc/homepage_state.dart';
import 'package:mangatracker/features/home/helpers/home_layout_metrics.dart';
import 'package:mangatracker/features/home/widgets/home_section_header.dart';
import 'package:mangatracker/features/home/widgets/home_sections_skeleton.dart';
import 'package:mangatracker/features/recommendations/widgets/dismissible_recommendation_card.dart';
import 'package:mangatracker/l10n/app_localizations.dart';

/// Section « Recommandes pour vous » de l'accueil, alimentee par
/// `HomePageBloc`. Meme en-tete que les sections catalogue, cartes avec le
/// geste de rejet (appui long) conserve. Masquee hors ligne si aucune
/// recommandation n'est en cache — un message decourageant serait faux.
class HomeRecommendationsSection extends StatelessWidget {
  final HomePageState state;
  final HomeLayoutMetrics metrics;
  final ValueChanged<num> onDismissed;
  final ValueChanged<num> onRestored;

  const HomeRecommendationsSection({
    super.key,
    required this.state,
    required this.metrics,
    required this.onDismissed,
    required this.onRestored,
  });

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final current = state;

    if (current is HomePageLoading || current is HomePageInitial) {
      return HomeSectionsSkeleton(metrics: metrics, sectionCount: 1);
    }
    if (current is! HomePageLoaded) return const SizedBox.shrink();

    final recos = current.recommendations.take(10).toList();
    if (recos.isEmpty && current.isOffline) return const SizedBox.shrink();

    final hPad = metrics.horizontalPadding;
    return Padding(
      padding: const EdgeInsets.only(bottom: HomeLayoutMetrics.sectionGap),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: EdgeInsets.symmetric(horizontal: hPad),
            child: HomeSectionHeader(
              icon: Icons.auto_awesome_outlined,
              tileColor: PastelTileColor.purple,
              title: l10n.recommendedForYouHome,
              onSeeAll:
                  recos.isEmpty ? null : () => context.push('/recommendations'),
            ),
          ),
          const SizedBox(height: AppSpacing.s + AppSpacing.xs),
          if (recos.isEmpty)
            Padding(
              padding: EdgeInsets.symmetric(horizontal: hPad),
              child: Text(
                l10n.recommendedForYouEmpty,
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: Theme.of(context).colorScheme.onSurfaceVariant,
                    ),
              ),
            )
          else
            SizedBox(
              height: metrics.cardHeight,
              child: ListView.builder(
                scrollDirection: Axis.horizontal,
                itemCount: recos.length,
                padding: EdgeInsets.symmetric(horizontal: hPad),
                itemBuilder: (context, index) => Padding(
                  padding: EdgeInsets.only(
                    right: index == recos.length - 1
                        ? 0
                        : HomeLayoutMetrics.cardGap,
                  ),
                  child: SizedBox(
                    width: metrics.cardWidth,
                    child: DismissibleRecommendationCard(
                      manga: recos[index],
                      onDismissed: onDismissed,
                      onRestored: onRestored,
                    ),
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}
