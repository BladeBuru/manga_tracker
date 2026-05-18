import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:mangatracker/core/theme/app_colors.dart';
import 'package:mangatracker/core/theme/app_spacing.dart';
import 'package:mangatracker/l10n/app_localizations.dart';

// ╔═══════════════════════════════════════════════════════════════════════╗
// ║  V1 « Refined Classic » — Segmented toggle pour les recos.            ║
// ║                                                                       ║
// ║  Remplace l'ancien `IconButton(Icons.category_outlined)` dans l'AppBar║
// ║  qui était "nul" (commentaire user). Pattern : 2 pill chips côte à    ║
// ║  côte ("Tout" / "Par genre"), actif = bg `dsRedSoft` + border primary ║
// ║  + texte primary + ✓ check, inactif = bg surface + hairline border.   ║
// ║                                                                       ║
// ║  Le tap navigue via `go_router` vers la route correspondante.         ║
// ╚═══════════════════════════════════════════════════════════════════════╝

/// Quel mode de recommandation est actuellement affiché.
enum RecommendationsMode { all, byGenre }

class RecommendationsSegmentedToggle extends StatelessWidget {
  final RecommendationsMode current;

  const RecommendationsSegmentedToggle({super.key, required this.current});

  void _navigate(BuildContext context, RecommendationsMode target) {
    if (target == current) return;
    switch (target) {
      case RecommendationsMode.all:
        context.go('/recommendations');
      case RecommendationsMode.byGenre:
        context.go('/recommendations/by-genre');
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return Padding(
      padding: const EdgeInsets.fromLTRB(
        AppSpacing.m,
        AppSpacing.s,
        AppSpacing.m,
        AppSpacing.s,
      ),
      child: Row(
        children: [
          Expanded(
            child: _SegChip(
              label: l10n?.recommendationsTabAll ?? 'Tout',
              selected: current == RecommendationsMode.all,
              onTap: () => _navigate(context, RecommendationsMode.all),
            ),
          ),
          const SizedBox(width: AppSpacing.s),
          Expanded(
            child: _SegChip(
              label: l10n?.recommendationsTabByGenre ?? 'Par genre',
              selected: current == RecommendationsMode.byGenre,
              onTap: () => _navigate(context, RecommendationsMode.byGenre),
            ),
          ),
        ],
      ),
    );
  }
}

class _SegChip extends StatelessWidget {
  final String label;
  final bool selected;
  final VoidCallback onTap;

  const _SegChip({
    required this.label,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final brightness = Theme.of(context).brightness;
    final scheme = Theme.of(context).colorScheme;
    final isDark = brightness == Brightness.dark;
    final bg = selected
        ? AppColors.dsRedSoft(brightness)
        : (isDark ? AppColors.dsSurfaceDark : Colors.white);
    final borderColor =
        selected ? scheme.primary : AppColors.dsBorder(brightness);
    final fg = selected ? scheme.primary : AppColors.dsText2(brightness);

    return Material(
      color: Colors.transparent,
      borderRadius: BorderRadius.circular(999),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(999),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 150),
          height: 38,
          padding: const EdgeInsets.symmetric(horizontal: 14),
          decoration: BoxDecoration(
            color: bg,
            borderRadius: BorderRadius.circular(999),
            border: Border.all(color: borderColor, width: 1.2),
          ),
          alignment: Alignment.center,
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            mainAxisSize: MainAxisSize.min,
            children: [
              if (selected) ...[
                Icon(Icons.check, size: 15, color: scheme.primary),
                const SizedBox(width: 6),
              ],
              Text(
                label,
                style: TextStyle(
                  fontSize: 13.5,
                  fontWeight:
                      selected ? FontWeight.w600 : FontWeight.w500,
                  color: fg,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
