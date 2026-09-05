import 'package:flutter/material.dart';
import 'package:mangatracker/core/theme/app_radius.dart';
import 'package:mangatracker/core/theme/app_spacing.dart';

/// Petite pastille posee sur une cover (type d'oeuvre, statut…).
///
/// Fond `surface` legerement translucide pour rester lisible sur n'importe
/// quelle image, texte `labelSmall` gras `onSurface`. A placer dans un
/// `Stack` au-dessus de l'image, en haut a gauche par defaut.
class CoverBadge extends StatelessWidget {
  final String label;
  final AlignmentGeometry alignment;

  const CoverBadge({
    super.key,
    required this.label,
    this.alignment = Alignment.topLeft,
  });

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Align(
      alignment: alignment,
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.s - 2),
        child: DecoratedBox(
          decoration: BoxDecoration(
            color: scheme.surface.withValues(alpha: 0.92),
            borderRadius: AppRadius.circularSm,
          ),
          child: Padding(
            padding: const EdgeInsets.symmetric(
              horizontal: AppSpacing.s - 2,
              vertical: AppSpacing.xs - 2,
            ),
            child: Text(
              label,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: Theme.of(context).textTheme.labelSmall?.copyWith(
                    color: scheme.onSurface,
                    fontWeight: FontWeight.w700,
                  ),
            ),
          ),
        ),
      ),
    );
  }
}
