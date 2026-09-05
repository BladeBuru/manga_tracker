import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:mangatracker/core/router/app_router.dart';
import 'package:mangatracker/core/theme/app_spacing.dart';
import 'package:mangatracker/features/home/dto/home_section.dto.dart';
import 'package:mangatracker/features/home/helpers/home_layout_metrics.dart';
import 'package:mangatracker/features/home/helpers/home_section_l10n.dart';
import 'package:mangatracker/features/home/widgets/home_section_carousel.dart';
import 'package:mangatracker/features/home/widgets/home_section_header.dart';
import 'package:mangatracker/l10n/app_localizations.dart';

/// Une section complete de l'accueil : en-tete (icone + titre traduit +
/// « Tout voir ») puis carrousel. Se masque si la section n'a aucun item.
class HomeSectionTile extends StatelessWidget {
  final HomeSectionDto section;
  final HomeLayoutMetrics metrics;

  const HomeSectionTile({
    super.key,
    required this.section,
    required this.metrics,
  });

  void _openSection(BuildContext context) {
    context.push(
      '/home/section/${Uri.encodeComponent(section.id)}',
      extra: HomeSectionExtras(kind: section.kind, params: section.params),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (section.items.isEmpty) return const SizedBox.shrink();
    final l10n = AppLocalizations.of(context)!;
    return Padding(
      padding: const EdgeInsets.only(bottom: HomeLayoutMetrics.sectionGap),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: EdgeInsets.symmetric(horizontal: metrics.horizontalPadding),
            child: HomeSectionHeader(
              icon: HomeSectionL10n.icon(section.kind),
              tileColor: HomeSectionL10n.tileColor(section.kind),
              title: HomeSectionL10n.titleOf(l10n, section),
              onSeeAll: () => _openSection(context),
            ),
          ),
          const SizedBox(height: AppSpacing.s + AppSpacing.xs),
          HomeSectionCarousel(items: section.items, metrics: metrics),
        ],
      ),
    );
  }
}
