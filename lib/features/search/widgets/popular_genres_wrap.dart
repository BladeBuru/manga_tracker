import 'package:flutter/material.dart';
import 'package:mangatracker/core/theme/app_colors.dart';
import 'package:mangatracker/core/theme/app_spacing.dart';
import 'package:mangatracker/l10n/app_localizations.dart';

/// Section "Genres populaires" — header petit gris + Wrap de chips pilule.
///
/// Source : `.claude-design/manga-tracker/project/screen-search.jsx`.
/// Style chip aligné sur `ProfileEditGenderChips` du design V1 (hauteur 32 ici,
/// radius 999, border hairline, font 12.5).
class PopularGenresWrap extends StatelessWidget {
  final List<String> genres;
  final ValueChanged<String> onSelectGenre;

  const PopularGenresWrap({
    super.key,
    required this.genres,
    required this.onSelectGenre,
  });

  @override
  Widget build(BuildContext context) {
    final brightness = Theme.of(context).brightness;
    final l10n = AppLocalizations.of(context)!;
    return Padding(
      padding: const EdgeInsets.fromLTRB(
        AppSpacing.m,
        AppSpacing.l,
        AppSpacing.m,
        AppSpacing.m,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            l10n.searchPopularGenres,
            style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w700,
              letterSpacing: -0.065, // -0.005em * 13
              color: AppColors.dsText2(brightness),
            ),
          ),
          const SizedBox(height: 10),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: genres
                .map(
                  (g) => _GenreChip(
                    label: g,
                    onTap: () => onSelectGenre(g),
                  ),
                )
                .toList(),
          ),
        ],
      ),
    );
  }
}

class _GenreChip extends StatelessWidget {
  final String label;
  final VoidCallback onTap;

  const _GenreChip({required this.label, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final brightness = Theme.of(context).brightness;
    final isDark = brightness == Brightness.dark;
    final bg = isDark ? AppColors.dsSurfaceDark : Colors.white;
    // **2026-05-18 fix** : pas d'`alignment: Alignment.center` ici. Flutter
    // expand un Container à toute la largeur disponible dès qu'on met une
    // alignment non-null avec des contraintes loose horizontales — donc
    // chaque chip prenait 100 % de la largeur du parent au lieu de se
    // dimensionner sur le texte. Le `Wrap` parent passe des contraintes
    // loose, on laisse le Container size-to-content.
    return GestureDetector(
      onTap: onTap,
      child: Container(
        height: 32,
        padding: const EdgeInsets.symmetric(horizontal: 14),
        decoration: BoxDecoration(
          color: bg,
          borderRadius: BorderRadius.circular(999),
          border: Border.all(
            color: AppColors.dsBorder(brightness),
            width: 1,
          ),
        ),
        child: Center(
          // Center juste vertical (largeur intrinsèque)
          widthFactor: 1,
          child: Text(
            label,
            style: TextStyle(
              fontSize: 12.5,
              fontWeight: FontWeight.w500,
              color: AppColors.dsText2(brightness),
            ),
          ),
        ),
      ),
    );
  }
}
