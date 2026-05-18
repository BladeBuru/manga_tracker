import 'package:flutter/material.dart';
import 'package:mangatracker/core/components/pastel_tile.dart';
import 'package:mangatracker/core/theme/app_colors.dart';
import 'package:mangatracker/l10n/app_localizations.dart';

// ╔═══════════════════════════════════════════════════════════════════════╗
// ║  StatsHeroCard — carte hero "Membre depuis X mois / Y mangas".        ║
// ║  Layout type screen-account.jsx Highlight (sparkles tile + texte +    ║
// ║  badge). Bg `surface` (blanc ou dsSurfaceDark), border hairline,      ║
// ║  radius 16, padding 14x16.                                            ║
// ╚═══════════════════════════════════════════════════════════════════════╝

/// Carte hero de la page Stats — affiche le nombre de mois depuis l'inscription
/// et la date exacte de création du compte.
class StatsHeroCard extends StatelessWidget {
  final DateTime accountCreatedAt;
  final String formattedDate;
  final int totalMangas;

  const StatsHeroCard({
    super.key,
    required this.accountCreatedAt,
    required this.formattedDate,
    required this.totalMangas,
  });

  int get _monthsSinceJoin {
    final now = DateTime.now();
    var months = (now.year - accountCreatedAt.year) * 12 +
        (now.month - accountCreatedAt.month);
    if (now.day < accountCreatedAt.day) months -= 1;
    return months < 0 ? 0 : months;
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final brightness = Theme.of(context).brightness;
    final isDark = brightness == Brightness.dark;
    final scheme = Theme.of(context).colorScheme;

    return Container(
      decoration: BoxDecoration(
        color: isDark ? AppColors.dsSurfaceDark : Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.primary, width: 1),
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
        children: [
          const PastelTile(
            icon: Icons.auto_awesome_outlined,
            color: PastelTileColor.red,
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  l10n.statsMonthsSinceJoin(_monthsSinceJoin),
                  style: TextStyle(
                    fontSize: 14.5,
                    fontWeight: FontWeight.w700,
                    color: scheme.onSurface,
                    letterSpacing: -0.05,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  formattedDate,
                  style: TextStyle(
                    fontFamily: 'JetBrainsMono',
                    fontFeatures: const [FontFeature.tabularFigures()],
                    fontSize: 11.5,
                    color: AppColors.dsText2(brightness),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 12),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 11, vertical: 5),
            decoration: BoxDecoration(
              color: AppColors.primary,
              borderRadius: BorderRadius.circular(999),
            ),
            child: Text(
              l10n.statsHeroBadge(totalMangas),
              style: const TextStyle(
                color: Colors.white,
                fontSize: 11.5,
                fontWeight: FontWeight.w700,
                letterSpacing: 0.23, // 0.02em
              ),
            ),
          ),
        ],
      ),
    );
  }
}
