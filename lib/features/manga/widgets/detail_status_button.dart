import 'package:flutter/material.dart';
import 'package:mangatracker/core/theme/app_colors.dart';
import 'package:mangatracker/core/theme/app_spacing.dart';
import 'package:mangatracker/features/manga/dto/reading_status.enum.dart';
import 'package:mangatracker/l10n/app_localizations.dart';

// ╔═══════════════════════════════════════════════════════════════════════╗
// ║  V1 « Refined Classic » — bouton compact "Changer le statut".         ║
// ║                                                                       ║
// ║  Remplace `DetailStatusSelector` (chips horizontales inline ~80px de  ║
// ║  haut) par une rangée unique ~46px qui ouvre la sheet de gestion.     ║
// ║  Réutilise la sheet existante (`_showManageLibrarySheet`) qui propose ║
// ║  les 4 statuts + retirer de la bibliothèque.                          ║
// ╚═══════════════════════════════════════════════════════════════════════╝

/// Bouton compact d'accès à la sheet de changement de statut.
///
/// Layout : `[icône statut · STATUT · "En cours" · chevron]`
/// - Icône à gauche (icône de bookmarking selon le statut courant)
/// - Label uppercase tracké "STATUT" (style V1 field label)
/// - Valeur du statut (`En cours` / `Terminé` etc.) en w500
/// - Chevron right à droite
///
/// Tap → callback parent qui montre la sheet via [onTap].
class DetailStatusButton extends StatelessWidget {
  final ReadingStatus status;
  final VoidCallback onTap;

  const DetailStatusButton({
    super.key,
    required this.status,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final brightness = Theme.of(context).brightness;
    final scheme = Theme.of(context).colorScheme;
    final l10n = AppLocalizations.of(context)!;
    final isDark = brightness == Brightness.dark;
    final bg = isDark ? AppColors.dsSurfaceDark : Colors.white;

    return Padding(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.m,
        vertical: AppSpacing.xs,
      ),
      child: Material(
        color: bg,
        borderRadius: BorderRadius.circular(14),
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(14),
          child: Container(
            padding: const EdgeInsets.symmetric(
              horizontal: 14,
              vertical: 12,
            ),
            decoration: BoxDecoration(
              border: Border.all(
                color: AppColors.dsHairline(brightness),
                width: 1,
              ),
              borderRadius: BorderRadius.circular(14),
            ),
            child: Row(
              children: [
                Icon(status.icon, size: 18, color: scheme.primary),
                const SizedBox(width: 10),
                Text(
                  l10n.changeStatus.toUpperCase(),
                  style: TextStyle(
                    fontSize: 10.5,
                    fontWeight: FontWeight.w600,
                    letterSpacing: 0.63,
                    color: AppColors.dsText3(brightness),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    status.getLabel(context),
                    style: TextStyle(
                      fontSize: 14.5,
                      fontWeight: FontWeight.w600,
                      color: scheme.onSurface,
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                Icon(
                  Icons.chevron_right,
                  size: 20,
                  color: AppColors.dsText3(brightness),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
