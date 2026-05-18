import 'package:flutter/material.dart';
import 'package:mangatracker/core/components/pastel_tile.dart';
import 'package:mangatracker/core/theme/app_colors.dart';

// ╔═══════════════════════════════════════════════════════════════════════╗
// ║  StatsSectionRow — ligne de stat dans une `ProfileEditSection`.       ║
// ║  Layout : padding 14×16, label gauche (15px / w600), valeur droite    ║
// ║  (mono tabular nums, 15px / dsText2). Une pastel tile optionnelle     ║
// ║  peut précéder le label pour la variété visuelle.                     ║
// ║                                                                       ║
// ║  Source design : screen-account.jsx + profile-v1.jsx (V1 Refined      ║
// ║  Classic — sections groupées en cards avec rows hairline-séparées).   ║
// ╚═══════════════════════════════════════════════════════════════════════╝

/// Ligne de statistique alignée label/valeur, avec pastel tile facultatif.
///
/// Utilisée à l'intérieur d'une `ProfileEditSection` qui gère elle-même les
/// hairlines entre rows. Ne pas mettre de Divider à l'intérieur.
class StatsSectionRow extends StatelessWidget {
  final String label;
  final String value;
  final IconData? icon;
  final PastelTileColor tileColor;

  const StatsSectionRow({
    super.key,
    required this.label,
    required this.value,
    this.icon,
    this.tileColor = PastelTileColor.red,
  });

  @override
  Widget build(BuildContext context) {
    final brightness = Theme.of(context).brightness;
    final scheme = Theme.of(context).colorScheme;
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      child: Row(
        children: [
          if (icon != null) ...[
            PastelTile(icon: icon!, color: tileColor, size: 32, iconSize: 17),
            const SizedBox(width: 12),
          ],
          Expanded(
            child: Text(
              label,
              style: TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.w600,
                color: scheme.onSurface,
                letterSpacing: -0.075,
              ),
            ),
          ),
          const SizedBox(width: 12),
          Text(
            value,
            textAlign: TextAlign.right,
            style: TextStyle(
              fontFamily: 'JetBrainsMono',
              fontFeatures: const [FontFeature.tabularFigures()],
              fontSize: 14.5,
              fontWeight: FontWeight.w600,
              color: AppColors.dsText2(brightness),
            ),
          ),
        ],
      ),
    );
  }
}
