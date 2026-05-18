import 'package:flutter/material.dart';
import 'package:mangatracker/core/components/pastel_tile.dart';
import 'package:mangatracker/core/theme/app_colors.dart';

// ╔═══════════════════════════════════════════════════════════════════════╗
// ║  ReadingGroupActionRow — row d'action V1 type "MenuRow" : pastel tile  ║
// ║  + titre + sous-titre + chevron. Variante `danger` qui passe le titre  ║
// ║  en rouge (pour Quitter / Supprimer).                                 ║
// ║                                                                       ║
// ║  Conçu pour vivre dans un ProfileEditSection (hairline divider auto). ║
// ╚═══════════════════════════════════════════════════════════════════════╝

class ReadingGroupActionRow extends StatelessWidget {
  final IconData icon;
  final PastelTileColor color;
  final String title;
  final String? subtitle;
  final VoidCallback? onTap;
  final bool danger;

  const ReadingGroupActionRow({
    super.key,
    required this.icon,
    required this.color,
    required this.title,
    this.subtitle,
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
            PastelTile(icon: icon, color: color),
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
