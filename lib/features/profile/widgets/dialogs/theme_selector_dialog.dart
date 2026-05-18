import 'package:flutter/material.dart';

import 'package:mangatracker/core/components/pastel_tile.dart';
import 'package:mangatracker/core/theme/app_colors.dart';
import 'package:mangatracker/core/theme/app_radius.dart';
import 'package:mangatracker/core/theme/app_spacing.dart';
import 'package:mangatracker/features/profile/widgets/dialogs/profile_dialog_shell.dart';
import 'package:mangatracker/l10n/app_localizations.dart';

/// Sélecteur de thème — clair / sombre / système (Design V1).
///
/// Tap sur une option applique immédiatement + ferme. Retourne le `ThemeMode`
/// choisi ou `null` si l'utilisateur a annulé via le bouton.
Future<ThemeMode?> showThemeSelectorDialog({
  required BuildContext context,
  required ThemeMode currentMode,
}) async {
  final l10n = AppLocalizations.of(context)!;
  return showDialog<ThemeMode>(
    context: context,
    builder: (context) => ProfileDialogShell(
      icon: Icons.brightness_6_outlined,
      iconColor: PastelTileColor.purple,
      title: l10n.theme,
      actions: [
        ProfileDialogCancelButton(
          label: l10n.cancel,
          onPressed: () => Navigator.of(context).pop(),
        ),
      ],
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          _ThemeOptionRow(
            mode: ThemeMode.light,
            currentMode: currentMode,
            icon: Icons.light_mode_outlined,
            title: l10n.lightMode,
          ),
          const SizedBox(height: AppSpacing.s),
          _ThemeOptionRow(
            mode: ThemeMode.dark,
            currentMode: currentMode,
            icon: Icons.dark_mode_outlined,
            title: l10n.darkMode,
          ),
          const SizedBox(height: AppSpacing.s),
          _ThemeOptionRow(
            mode: ThemeMode.system,
            currentMode: currentMode,
            icon: Icons.brightness_auto_outlined,
            title: l10n.systemMode,
          ),
        ],
      ),
    ),
  );
}

// ─────────────────────────────────────────────────────────────────────────────
// Ligne d'option du sélecteur de thème.
// Reprend le pattern "focused" de `ProfileEditField` : bg insetté + barre
// verticale rouge à gauche quand sélectionné.
// ─────────────────────────────────────────────────────────────────────────────

class _ThemeOptionRow extends StatelessWidget {
  final ThemeMode mode;
  final ThemeMode currentMode;
  final IconData icon;
  final String title;

  const _ThemeOptionRow({
    required this.mode,
    required this.currentMode,
    required this.icon,
    required this.title,
  });

  @override
  Widget build(BuildContext context) {
    final brightness = Theme.of(context).brightness;
    final scheme = Theme.of(context).colorScheme;
    final isSelected = mode == currentMode;

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: () => Navigator.of(context).pop(mode),
        borderRadius: BorderRadius.circular(AppRadius.xl),
        child: Stack(
          children: [
            if (isSelected)
              Positioned(
                top: 8,
                bottom: 8,
                left: 0,
                child: Container(
                  width: 3,
                  decoration: BoxDecoration(
                    color: scheme.primary,
                    borderRadius: BorderRadius.circular(999),
                  ),
                ),
              ),
            Container(
              padding: const EdgeInsets.symmetric(
                horizontal: AppSpacing.m,
                vertical: AppSpacing.s + 4,
              ),
              decoration: BoxDecoration(
                color: isSelected
                    ? AppColors.dsBgInset(brightness)
                    : Colors.transparent,
                borderRadius: BorderRadius.circular(AppRadius.xl),
                border: Border.all(
                  color: AppColors.dsHairline(brightness),
                  width: 1,
                ),
              ),
              child: Row(
                children: [
                  Icon(
                    icon,
                    size: 20,
                    color: isSelected
                        ? scheme.primary
                        : AppColors.dsText2(brightness),
                  ),
                  const SizedBox(width: AppSpacing.m),
                  Expanded(
                    child: Text(
                      title,
                      style: TextStyle(
                        fontSize: 15,
                        fontWeight:
                            isSelected ? FontWeight.w600 : FontWeight.w500,
                        letterSpacing: -0.1,
                        color: scheme.onSurface,
                      ),
                    ),
                  ),
                  if (isSelected)
                    Icon(
                      Icons.check_circle,
                      color: scheme.primary,
                      size: 20,
                    ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
