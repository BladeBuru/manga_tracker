import 'package:flutter/material.dart';

import 'package:mangatracker/core/components/pastel_tile.dart';
import 'package:mangatracker/core/theme/app_colors.dart';

// ╔═══════════════════════════════════════════════════════════════════════╗
// ║  ProfileMenuRow — ligne d'option type "Mon compte".                   ║
// ║  Structure : PastelTile (leading) + Titre + Sous-titre (optionnel) +  ║
// ║  trailing custom OU chevron par défaut.                               ║
// ║                                                                       ║
// ║  Source design : `.claude-design/manga-tracker/project/shared.jsx`    ║
// ║                  (`MenuRow` component).                               ║
// ╚═══════════════════════════════════════════════════════════════════════╝

class ProfileMenuRow extends StatelessWidget {
  /// Tuile pastel à gauche.
  final PastelTile leading;

  /// Titre principal (15px weight 600).
  final String title;

  /// Sous-titre optionnel (12.5px text-2).
  final String? subtitle;

  /// Widget de fin custom (par défaut : chevron). Mettre `Switch` pour
  /// la ligne biométrie par exemple.
  final Widget? trailing;

  /// Action déclenchée au tap. Si `null`, la ligne reste inerte.
  final VoidCallback? onTap;

  /// Si vrai, le titre s'affiche en rouge (action destructive).
  final bool danger;

  const ProfileMenuRow({
    super.key,
    required this.leading,
    required this.title,
    this.subtitle,
    this.trailing,
    this.onTap,
    this.danger = false,
  });

  @override
  Widget build(BuildContext context) {
    final brightness = Theme.of(context).brightness;
    final scheme = Theme.of(context).colorScheme;
    final titleColor = danger ? AppColors.primary : scheme.onSurface;

    return InkWell(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            leading,
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    title,
                    style: TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w600,
                      letterSpacing: -0.075,
                      color: titleColor,
                    ),
                  ),
                  if (subtitle != null && subtitle!.isNotEmpty) ...[
                    const SizedBox(height: 2),
                    Text(
                      subtitle!,
                      style: TextStyle(
                        fontSize: 12.5,
                        height: 1.3,
                        color: AppColors.dsText2(brightness),
                      ),
                    ),
                  ],
                ],
              ),
            ),
            const SizedBox(width: 8),
            trailing ??
                Icon(
                  Icons.chevron_right,
                  size: 18,
                  color: AppColors.dsText3(brightness),
                ),
          ],
        ),
      ),
    );
  }
}
