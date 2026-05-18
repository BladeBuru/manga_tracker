import 'package:flutter/material.dart';

import 'package:mangatracker/core/components/pastel_tile.dart';
import 'package:mangatracker/core/theme/app_colors.dart';
import 'package:mangatracker/core/theme/app_radius.dart';
import 'package:mangatracker/core/theme/app_spacing.dart';

// ╔═══════════════════════════════════════════════════════════════════════╗
// ║  ProfileDialogShell — squelette commun des dialogs Profile (V1).      ║
// ║                                                                       ║
// ║  Visuel : AlertDialog 16px radius, fond off-white (ou dsSurfaceDark   ║
// ║  en mode sombre), surfaceTintColor neutralisé (kill Material 3       ║
// ║  tint), bordure hairline.                                            ║
// ║                                                                       ║
// ║  Structure :                                                          ║
// ║    [PastelTile 56x56 centré]                                          ║
// ║    [Title 17 / w700]                                                  ║
// ║    [Subtitle 14 / w500 dsText2]                                       ║
// ║    [Optional child (form...)]                                         ║
// ║    [Actions row]                                                      ║
// ╚═══════════════════════════════════════════════════════════════════════╝

class ProfileDialogShell extends StatelessWidget {
  /// L'icône centrale dans le PastelTile en haut du dialog.
  final IconData icon;

  /// Variante de couleur du PastelTile.
  final PastelTileColor iconColor;

  /// Titre du dialog (l10n).
  final String title;

  /// Sous-titre du dialog (l10n).
  final String? subtitle;

  /// Contenu additionnel optionnel (formulaire, options...).
  final Widget? child;

  /// Boutons d'action (Annuler + Confirmer typiquement).
  final List<Widget> actions;

  /// Force une bordure rouge plus marquée (utilisée pour le dialog
  /// "Supprimer le compte" pour signaler une action dangereuse).
  final bool danger;

  const ProfileDialogShell({
    super.key,
    required this.icon,
    required this.iconColor,
    required this.title,
    this.subtitle,
    this.child,
    required this.actions,
    this.danger = false,
  });

  @override
  Widget build(BuildContext context) {
    final brightness = Theme.of(context).brightness;
    final isDark = brightness == Brightness.dark;
    final scheme = Theme.of(context).colorScheme;

    final Color borderColor = danger
        ? scheme.primary.withValues(alpha: 0.6)
        : AppColors.dsHairline(brightness);
    final double borderWidth = danger ? 1.5 : 1;

    return AlertDialog(
      backgroundColor: isDark ? AppColors.dsSurfaceDark : Colors.white,
      surfaceTintColor: Colors.transparent,
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppRadius.xxxl),
        side: BorderSide(color: borderColor, width: borderWidth),
      ),
      contentPadding: const EdgeInsets.fromLTRB(24, 28, 24, 16),
      actionsPadding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
      actionsAlignment: MainAxisAlignment.end,
      content: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 360),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Center(
              child: PastelTile(
                icon: icon,
                color: iconColor,
                size: 56,
                iconSize: 28,
              ),
            ),
            const SizedBox(height: AppSpacing.m),
            Text(
              title,
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 17,
                fontWeight: FontWeight.w700,
                letterSpacing: -0.2,
                color: scheme.onSurface,
              ),
            ),
            if (subtitle != null) ...[
              const SizedBox(height: AppSpacing.s),
              Text(
                subtitle!,
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                  height: 1.4,
                  color: AppColors.dsText2(brightness),
                ),
              ),
            ],
            if (child != null) ...[
              const SizedBox(height: AppSpacing.l),
              child!,
            ],
          ],
        ),
      ),
      actions: actions,
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Boutons standardisés pour les dialogs Profile.
// ─────────────────────────────────────────────────────────────────────────────

/// Bouton "Annuler" — TextButton avec texte dsText2.
class ProfileDialogCancelButton extends StatelessWidget {
  final String label;
  final VoidCallback onPressed;

  const ProfileDialogCancelButton({
    super.key,
    required this.label,
    required this.onPressed,
  });

  @override
  Widget build(BuildContext context) {
    final brightness = Theme.of(context).brightness;
    return TextButton(
      onPressed: onPressed,
      style: TextButton.styleFrom(
        foregroundColor: AppColors.dsText2(brightness),
        textStyle: const TextStyle(
          fontSize: 15,
          fontWeight: FontWeight.w600,
        ),
        padding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.m,
          vertical: AppSpacing.s + 2,
        ),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppRadius.xl),
        ),
      ),
      child: Text(label),
    );
  }
}

/// Bouton de confirmation — FilledButton rouge primary (action principale).
class ProfileDialogConfirmButton extends StatelessWidget {
  final String label;
  final VoidCallback? onPressed;

  const ProfileDialogConfirmButton({
    super.key,
    required this.label,
    required this.onPressed,
  });

  @override
  Widget build(BuildContext context) {
    return FilledButton(
      onPressed: onPressed,
      style: FilledButton.styleFrom(
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.white,
        disabledBackgroundColor: AppColors.primary.withValues(alpha: 0.35),
        disabledForegroundColor: Colors.white.withValues(alpha: 0.7),
        textStyle: const TextStyle(
          fontSize: 15,
          fontWeight: FontWeight.w600,
          letterSpacing: -0.1,
        ),
        padding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.l,
          vertical: AppSpacing.s + 4,
        ),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppRadius.xl),
        ),
      ),
      child: Text(label),
    );
  }
}
