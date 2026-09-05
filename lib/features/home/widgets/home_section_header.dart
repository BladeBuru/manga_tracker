import 'package:flutter/material.dart';
import 'package:mangatracker/core/components/pastel_tile.dart';
import 'package:mangatracker/core/theme/app_spacing.dart';
import 'package:mangatracker/l10n/app_localizations.dart';

/// En-tete d'une section de l'accueil catalogue (et de sa page « Tout voir »).
///
/// Tile pastel + icone Material a gauche, titre traduit, puis a droite soit
/// le bouton « Tout voir » ([onSeeAll]), soit un [trailing] libre (compteur
/// sur la page complete). Aucun texte en dur : le libelle du bouton et son
/// annonce d'accessibilite viennent des ARB.
class HomeSectionHeader extends StatelessWidget {
  final IconData icon;
  final PastelTileColor tileColor;
  final String title;
  final VoidCallback? onSeeAll;
  final Widget? trailing;

  const HomeSectionHeader({
    super.key,
    required this.icon,
    required this.title,
    this.tileColor = PastelTileColor.red,
    this.onSeeAll,
    this.trailing,
  });

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final scheme = Theme.of(context).colorScheme;
    return Row(
      children: [
        PastelTile(
          icon: icon,
          color: tileColor,
          size: AppSpacing.xl,
          iconSize: AppSpacing.m + 2,
        ),
        const SizedBox(width: AppSpacing.s + AppSpacing.xs),
        Expanded(
          child: Text(
            title,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.w700,
                  color: scheme.onSurface,
                ),
          ),
        ),
        if (trailing != null) trailing!,
        if (onSeeAll != null)
          Semantics(
            button: true,
            label: l10n.homeSectionSeeAllAccessibility(title),
            child: TextButton.icon(
              onPressed: onSeeAll,
              style: TextButton.styleFrom(
                foregroundColor: scheme.primary,
                padding: const EdgeInsets.symmetric(horizontal: AppSpacing.s),
                minimumSize: const Size(0, AppSpacing.xl),
                tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                visualDensity: VisualDensity.compact,
              ),
              iconAlignment: IconAlignment.end,
              icon: const Icon(Icons.chevron_right, size: AppSpacing.m + 2),
              label: ExcludeSemantics(child: Text(l10n.homeSectionSeeAll)),
            ),
          ),
      ],
    );
  }
}
