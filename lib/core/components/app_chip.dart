import 'package:flutter/material.dart';
import 'package:mangatracker/core/theme/app_radius.dart';

/// Pastille / chip du design system (style "Google look").
///
/// Trois variantes :
///  - `AppChip` (default) : `secondaryContainer` + border `outlineVariant`
///    — pour tags, genres, statuts neutres
///  - `AppChip.primary` : `primaryContainer` + border off — pour mise en avant
///  - `AppChip.outlined` : surface + border `outlineVariant` seul
///
/// Densité M3 standard, radius `xl` (12px) pour le "pill look".
class AppChip extends StatelessWidget {
  final String label;
  final IconData? icon;
  final VoidCallback? onTap;
  final Color? backgroundColor;
  final Color? foregroundColor;
  final BorderSide? border;

  const AppChip({
    super.key,
    required this.label,
    this.icon,
    this.onTap,
    this.backgroundColor,
    this.foregroundColor,
    this.border,
  });

  /// Variante "primary" (mise en avant). Static builder (Dart n'autorise
  /// pas qu'un factory retourne un sous-type private).
  static Widget primary({
    Key? key,
    required String label,
    IconData? icon,
    VoidCallback? onTap,
  }) {
    return _AppChipPrimary(key: key, label: label, icon: icon, onTap: onTap);
  }

  /// Variante "outlined" (border seul, fond surface).
  static Widget outlined({
    Key? key,
    required String label,
    IconData? icon,
    VoidCallback? onTap,
  }) {
    return _AppChipOutlined(key: key, label: label, icon: icon, onTap: onTap);
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    // **Refactor 2026-05-18** : default = `surfaceContainerHigh` (gris
    // tonal neutre) au lieu de `secondaryContainer` qui était orange
    // (le theme déclare `secondary: accent` orange Material). Le user
    // trouvait les chips genres "vraiment moches en orange". Maintenant
    // les chips inactifs sont blanc/gris subtil, les chips actifs (via
    // `AppChip.primary`) sont rouge tonal — c'est lisible et cohérent.
    final bg = backgroundColor ?? scheme.surfaceContainerHigh;
    final fg = foregroundColor ?? scheme.onSurface;
    final side = border ?? BorderSide(color: scheme.outlineVariant);

    final chip = Material(
      color: bg,
      shape: RoundedRectangleBorder(
        borderRadius: AppRadius.circularXl,
        side: side,
      ),
      child: Padding(
        padding: EdgeInsets.symmetric(
          horizontal: icon != null ? 10 : 12,
          vertical: 6,
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (icon != null) ...[
              Icon(icon, size: 14, color: fg),
              const SizedBox(width: 4),
            ],
            Text(
              label,
              style: TextStyle(
                color: fg,
                fontSize: 12,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      ),
    );

    if (onTap == null) return chip;
    return InkWell(
      borderRadius: AppRadius.circularXl,
      onTap: onTap,
      child: chip,
    );
  }
}

class _AppChipPrimary extends StatelessWidget {
  final String label;
  final IconData? icon;
  final VoidCallback? onTap;
  const _AppChipPrimary({
    super.key,
    required this.label,
    this.icon,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return AppChip(
      label: label,
      icon: icon,
      onTap: onTap,
      backgroundColor: scheme.primaryContainer,
      foregroundColor: scheme.onPrimaryContainer,
      border: BorderSide.none,
    );
  }
}

class _AppChipOutlined extends StatelessWidget {
  final String label;
  final IconData? icon;
  final VoidCallback? onTap;
  const _AppChipOutlined({
    super.key,
    required this.label,
    this.icon,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return AppChip(
      label: label,
      icon: icon,
      onTap: onTap,
      backgroundColor: scheme.surface,
      foregroundColor: scheme.onSurface,
    );
  }
}
