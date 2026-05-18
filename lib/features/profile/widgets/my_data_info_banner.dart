import 'package:flutter/material.dart';

import 'package:mangatracker/core/components/pastel_tile.dart';
import 'package:mangatracker/core/theme/app_colors.dart';
import 'package:mangatracker/core/theme/app_radius.dart';
import 'package:mangatracker/l10n/app_localizations.dart';

// ╔═══════════════════════════════════════════════════════════════════════╗
// ║  MyDataInfoBanner — bandeau RGPD en haut de la page « Mes données ». ║
// ║  Carte hairline + PastelTile bleu (info) + texte explicatif court.    ║
// ║  Style V1 « Refined Classic ».                                        ║
// ╚═══════════════════════════════════════════════════════════════════════╝

class MyDataInfoBanner extends StatelessWidget {
  const MyDataInfoBanner({super.key});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final brightness = Theme.of(context).brightness;
    final isDark = brightness == Brightness.dark;
    return Container(
      decoration: BoxDecoration(
        color: isDark ? AppColors.dsSurfaceDark : Colors.white,
        borderRadius: AppRadius.circularXxxl,
        border: Border.all(
          color: AppColors.dsHairline(brightness),
          width: 1,
        ),
        boxShadow: isDark
            ? null
            : const [
                BoxShadow(
                  color: Color(0x0A140A0A),
                  blurRadius: 2,
                  offset: Offset(0, 1),
                ),
              ],
      ),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const PastelTile(
            icon: Icons.shield_outlined,
            color: PastelTileColor.blue,
            size: 32,
            iconSize: 18,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              l10n.myDataInfoBanner,
              style: TextStyle(
                fontSize: 13,
                height: 1.45,
                color: AppColors.dsText2(brightness),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
