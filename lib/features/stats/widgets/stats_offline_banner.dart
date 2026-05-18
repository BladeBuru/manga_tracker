import 'package:flutter/material.dart';
import 'package:mangatracker/core/theme/app_colors.dart';
import 'package:mangatracker/l10n/app_localizations.dart';

// ╔═══════════════════════════════════════════════════════════════════════╗
// ║  StatsOfflineBanner — pill discret signalant `isOffline = true`.      ║
// ║  Reprend le pattern V1 : fond `dsBgInset`, hairline border, icône     ║
// ║  cloud_off + texte tertiaire. Pas d'orange agressif.                  ║
// ╚═══════════════════════════════════════════════════════════════════════╝

/// Banner offline pour la page Stats.
///
/// S'affiche uniquement quand `StatsLoaded.isOffline == true` (cache servi).
class StatsOfflineBanner extends StatelessWidget {
  const StatsOfflineBanner({super.key});

  @override
  Widget build(BuildContext context) {
    final brightness = Theme.of(context).brightness;
    final l10n = AppLocalizations.of(context)!;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: AppColors.dsBgInset(brightness),
        borderRadius: BorderRadius.circular(999),
        border: Border.all(
          color: AppColors.dsHairline(brightness),
          width: 1,
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            Icons.cloud_off_outlined,
            size: 14,
            color: AppColors.dsText3(brightness),
          ),
          const SizedBox(width: 6),
          Text(
            l10n.offlineMode,
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: AppColors.dsText2(brightness),
              letterSpacing: 0.24, // 0.02em
            ),
          ),
        ],
      ),
    );
  }
}
