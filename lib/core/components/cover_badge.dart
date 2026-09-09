import 'package:flutter/material.dart';
import 'package:mangatracker/core/theme/app_radius.dart';
import 'package:mangatracker/core/theme/app_spacing.dart';

/// Petite pastille posee sur une cover (type d'oeuvre, appartenance a la
/// bibliotheque…). A placer dans un `Stack` au-dessus de l'image.
///
/// Deux variantes, un seul composant — pour ne pas multiplier les motifs de
/// pastille dans l'application :
/// - [CoverBadge] : texte court, fond `surface` translucide, haut gauche ;
/// - [CoverBadge.icon] : icone Material seule, fond `primary`, haut droit.
///   Reservee aux informations binaires ou le texte serait de trop sur une
///   vignette de 120 px. L'information n'est jamais portee par la seule
///   couleur : la forme (icone) la porte aussi, et [semanticsLabel] l'annonce
///   aux lecteurs d'ecran.
class CoverBadge extends StatelessWidget {
  final String? label;
  final IconData? icon;
  final String? semanticsLabel;
  final AlignmentGeometry alignment;

  const CoverBadge({
    super.key,
    required String this.label,
    this.alignment = Alignment.topLeft,
  })  : icon = null,
        semanticsLabel = null;

  const CoverBadge.icon({
    super.key,
    required IconData this.icon,
    required String this.semanticsLabel,
    this.alignment = Alignment.topRight,
  }) : label = null;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final isIcon = icon != null;
    final Widget pill = DecoratedBox(
      decoration: BoxDecoration(
        color:
            isIcon ? scheme.primary : scheme.surface.withValues(alpha: 0.92),
        borderRadius: isIcon ? AppRadius.circularFull : AppRadius.circularSm,
      ),
      child: Padding(
        padding: EdgeInsets.symmetric(
          horizontal: isIcon ? AppSpacing.xs - 1 : AppSpacing.s - 2,
          vertical: isIcon ? AppSpacing.xs - 1 : AppSpacing.xs - 2,
        ),
        child: isIcon
            ? Icon(icon, size: AppSpacing.m - 2, color: scheme.onPrimary)
            : Text(
                label!,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: Theme.of(context).textTheme.labelSmall?.copyWith(
                      color: scheme.onSurface,
                      fontWeight: FontWeight.w700,
                    ),
              ),
      ),
    );

    return Align(
      alignment: alignment,
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.s - 2),
        // Le texte se lit tout seul ; l'icone, elle, n'a de sens que si un
        // lecteur d'ecran peut l'annoncer.
        child: semanticsLabel == null
            ? pill
            : Semantics(label: semanticsLabel, child: pill),
      ),
    );
  }
}
