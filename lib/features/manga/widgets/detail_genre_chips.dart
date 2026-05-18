import 'package:flutter/material.dart';
import 'package:mangatracker/core/theme/app_colors.dart';
import 'package:mangatracker/core/theme/app_spacing.dart';

// ╔═══════════════════════════════════════════════════════════════════════╗
// ║  V1 « Refined Classic » — Genre chips horizontaux.                    ║
// ║  Style pill : hairline border, bg surface (light) ou surfaceDark,     ║
// ║  text-2, 12-13px / w500, padding horizontal 12-14, radius 999.        ║
// ║  Source : profile-v1.jsx + screen-detail.jsx.                          ║
// ╚═══════════════════════════════════════════════════════════════════════╝

/// Liste horizontale de pills V1 pour afficher les genres d'un manga.
///
/// Pas tappables par défaut (display only). Si un `onTap` est fourni, la pill
/// devient interactive (filtre par genre par exemple).
class DetailGenreChips extends StatelessWidget {
  final List<String> genres;
  final ValueChanged<String>? onGenreTap;

  /// Si `true` (default), affiche la liste en scroll horizontal.
  /// Si `false`, fait un wrap multi-lignes.
  final bool scrollable;

  const DetailGenreChips({
    super.key,
    required this.genres,
    this.onGenreTap,
    this.scrollable = true,
  });

  @override
  Widget build(BuildContext context) {
    if (genres.isEmpty) return const SizedBox.shrink();
    if (scrollable) {
      return SizedBox(
        height: 32,
        child: ListView.separated(
          scrollDirection: Axis.horizontal,
          itemCount: genres.length,
          separatorBuilder: (_, __) => const SizedBox(width: AppSpacing.s),
          itemBuilder: (context, index) => _GenrePill(
            label: genres[index],
            onTap: onGenreTap == null
                ? null
                : () => onGenreTap!(genres[index]),
          ),
        ),
      );
    }
    return Wrap(
      spacing: AppSpacing.s,
      runSpacing: AppSpacing.s,
      children: genres
          .map((g) => _GenrePill(
                label: g,
                onTap: onGenreTap == null ? null : () => onGenreTap!(g),
              ))
          .toList(),
    );
  }
}

class _GenrePill extends StatelessWidget {
  final String label;
  final VoidCallback? onTap;

  const _GenrePill({required this.label, this.onTap});

  @override
  Widget build(BuildContext context) {
    final brightness = Theme.of(context).brightness;
    final isDark = brightness == Brightness.dark;
    final bg = isDark ? AppColors.dsSurfaceDark : Colors.white;
    final borderColor = AppColors.dsBorder(brightness);
    final textColor = AppColors.dsText2(brightness);

    final pill = Container(
      height: 30,
      padding: const EdgeInsets.symmetric(horizontal: 13),
      alignment: Alignment.center,
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: borderColor, width: 1),
      ),
      child: Text(
        label,
        style: TextStyle(
          fontSize: 12.5,
          fontWeight: FontWeight.w500,
          color: textColor,
        ),
      ),
    );

    if (onTap == null) return pill;
    return InkWell(
      borderRadius: BorderRadius.circular(999),
      onTap: onTap,
      child: pill,
    );
  }
}
