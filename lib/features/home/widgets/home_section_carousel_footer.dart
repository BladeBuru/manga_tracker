import 'package:flutter/material.dart';
import 'package:mangatracker/core/theme/app_spacing.dart';
import 'package:mangatracker/features/home/bloc/home_section_page_state.dart';
import 'package:mangatracker/l10n/app_localizations.dart';

/// Ce que le pied du carrousel a a dire, ou rien du tout.
enum CarouselFooterKind {
  /// La page suivante est en vol.
  loading,

  /// Elle a echoue : on propose de reessayer sans quitter le carrousel.
  retry,
}

/// Tuile de pied d'un carrousel horizontal de l'accueil.
///
/// Volontairement discrete : la largeur d'une demi-carte, centree sur la
/// hauteur de cover, jamais de texte long qui deplacerait les cartes.
/// L'information est portee par une icone Material + une annonce
/// d'accessibilite, jamais par la seule couleur.
class HomeSectionCarouselFooter extends StatelessWidget {
  final CarouselFooterKind kind;

  /// Hauteur de la cover : le pied s'aligne sur les couvertures, pas sur la
  /// carte entiere (titre + meta), pour rester optiquement centre.
  final double height;

  final VoidCallback onRetry;

  const HomeSectionCarouselFooter({
    super.key,
    required this.kind,
    required this.height,
    required this.onRetry,
  });

  /// Traduit l'etat de pagination en pied a afficher (`null` = aucun).
  static CarouselFooterKind? of(HomeSectionPageLoaded? state) {
    if (state == null) return null;
    if (state.isLoadingMore) return CarouselFooterKind.loading;
    if (state.loadMoreFailed) return CarouselFooterKind.retry;
    return null;
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final isLoading = kind == CarouselFooterKind.loading;
    return SizedBox(
      width: AppSpacing.jumbo,
      child: Align(
        alignment: Alignment.topCenter,
        child: SizedBox(
          height: height,
          child: Center(
            child: isLoading
                ? Semantics(
                    label: l10n.homeSectionLoadingMore,
                    liveRegion: true,
                    child: const SizedBox(
                      width: AppSpacing.l,
                      height: AppSpacing.l,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    ),
                  )
                : IconButton.filledTonal(
                    onPressed: onRetry,
                    tooltip: l10n.retry,
                    icon: const Icon(Icons.refresh, size: AppSpacing.m + 2),
                    constraints: const BoxConstraints.tightFor(
                      width: AppSpacing.xl + AppSpacing.s,
                      height: AppSpacing.xl + AppSpacing.s,
                    ),
                    padding: EdgeInsets.zero,
                  ),
          ),
        ),
      ),
    );
  }
}
