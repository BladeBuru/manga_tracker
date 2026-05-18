import 'package:flutter/material.dart';

import 'package:mangatracker/core/theme/app_colors.dart';

// ╔═══════════════════════════════════════════════════════════════════════╗
// ║  PastelTile — composant signature du design system V1.                ║
// ║  Carré arrondi 38×38 (radius 10) avec un fond pastel coloré et une    ║
// ║  icône colorée centrée. 7 variantes de couleur (red, yellow, blue,    ║
// ║  green, purple, pink, teal). Les variantes ont une version light et   ║
// ║  une version dark (palette issue de `tokens.css`).                    ║
// ║                                                                       ║
// ║  Source design : `.claude-design/manga-tracker/project/icons.jsx`     ║
// ║                  (`Tile` component) + `.css` (`.mt-tile.<color>`).    ║
// ╚═══════════════════════════════════════════════════════════════════════╝

/// Variantes de couleur du `PastelTile`.
enum PastelTileColor { red, yellow, blue, green, purple, pink, teal }

class PastelTile extends StatelessWidget {
  /// L'icône à afficher au centre. Préférer les icônes outlined Material 3.
  final IconData icon;

  /// La couleur du tile (détermine bg + couleur icône).
  final PastelTileColor color;

  /// Taille du carré (par défaut 38, comme dans le design).
  final double size;

  /// Taille de l'icône (par défaut 20, ratio ~0.5 du tile).
  final double iconSize;

  const PastelTile({
    super.key,
    required this.icon,
    this.color = PastelTileColor.red,
    this.size = 38,
    this.iconSize = 20,
  });

  @override
  Widget build(BuildContext context) {
    final brightness = Theme.of(context).brightness;
    final palette = _resolvePalette(brightness);

    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        color: palette.background,
        borderRadius: BorderRadius.circular(10),
      ),
      alignment: Alignment.center,
      child: Icon(icon, size: iconSize, color: palette.foreground),
    );
  }

  _PastelPalette _resolvePalette(Brightness b) {
    final isDark = b == Brightness.dark;
    switch (color) {
      case PastelTileColor.red:
        // red utilise les tokens existants `dsRedSoft` + `colorScheme.primary`
        // pour rester cohérent avec la palette principale.
        return _PastelPalette(
          background: AppColors.dsRedSoft(b),
          foreground: AppColors.primary,
        );
      case PastelTileColor.yellow:
        return _PastelPalette(
          background: isDark ? const Color(0xFF3D2E1A) : const Color(0xFFFCEBC2),
          foreground: isDark ? const Color(0xFFE8B530) : const Color(0xFFC8950A),
        );
      case PastelTileColor.blue:
        return _PastelPalette(
          background: isDark ? const Color(0xFF1A2F45) : const Color(0xFFD5E5F5),
          foreground: isDark ? const Color(0xFF65B5FF) : const Color(0xFF2C7BD4),
        );
      case PastelTileColor.green:
        return _PastelPalette(
          background: isDark ? const Color(0xFF1A332F) : const Color(0xFFD0E8E4),
          foreground: isDark ? const Color(0xFF54C9A4) : const Color(0xFF329C7B),
        );
      case PastelTileColor.purple:
        return _PastelPalette(
          background: isDark ? const Color(0xFF2A1F40) : const Color(0xFFE5D9F0),
          foreground: isDark ? const Color(0xFFB488FF) : const Color(0xFF7E45D4),
        );
      case PastelTileColor.pink:
        return _PastelPalette(
          background: isDark ? const Color(0xFF3D1F25) : const Color(0xFFF5D5DD),
          foreground: isDark ? const Color(0xFFFF7A98) : const Color(0xFFD74B6E),
        );
      case PastelTileColor.teal:
        return _PastelPalette(
          background: isDark ? const Color(0xFF1A3535) : const Color(0xFFD0E5E5),
          foreground: isDark ? const Color(0xFF5BCACA) : const Color(0xFF359999),
        );
    }
  }
}

class _PastelPalette {
  final Color background;
  final Color foreground;
  const _PastelPalette({required this.background, required this.foreground});
}
