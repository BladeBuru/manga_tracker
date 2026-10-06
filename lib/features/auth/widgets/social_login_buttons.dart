import 'package:flutter/material.dart';
import 'package:mangatracker/core/theme/app_colors.dart';
import 'package:mangatracker/core/theme/app_spacing.dart';

/// Rangée de boutons de login social (Google + Apple).
///
/// V1 : 2 boutons outlined côte-à-côte, height 52px, radius 14px,
/// logo + label. Bordure hairline, fond surface. Empilés quand les
/// libellés ne tiennent pas côte à côte.
class SocialLoginButtons extends StatelessWidget {
  final String googleLabel;
  final String appleLabel;
  final Future<void> Function()? onGoogle;
  final VoidCallback? onApple;
  final bool disabled;

  const SocialLoginButtons({
    super.key,
    required this.googleLabel,
    required this.appleLabel,
    required this.onGoogle,
    required this.onApple,
    this.disabled = false,
  });

  @override
  Widget build(BuildContext context) {
    final google = _SocialButton(
      assetPath: 'assets/images/google_logo.png',
      label: googleLabel,
      onTap: disabled || onGoogle == null ? null : () => onGoogle!(),
    );
    final apple = _SocialButton(
      assetPath: 'assets/images/apple_logo.png',
      label: appleLabel,
      onTap: disabled ? null : onApple,
    );
    // Côte à côte seulement si les deux libellés tiennent en entier (petit
    // écran, texte agrandi, allemand…) ; sinon empilés, pleine largeur —
    // plutôt que « Se con… ».
    return LayoutBuilder(
      builder: (context, constraints) {
        final halfWidth = (constraints.maxWidth - AppSpacing.m) / 2;
        final sideBySide = constraints.maxWidth.isFinite &&
            _SocialButton.fitsIn(context, googleLabel, halfWidth) &&
            _SocialButton.fitsIn(context, appleLabel, halfWidth);
        if (!sideBySide) {
          return Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              google,
              const SizedBox(height: AppSpacing.s + AppSpacing.xs),
              apple,
            ],
          );
        }
        return Row(
          children: [
            Expanded(child: google),
            const SizedBox(width: AppSpacing.m),
            Expanded(child: apple),
          ],
        );
      },
    );
  }
}

class _SocialButton extends StatelessWidget {
  final String assetPath;
  final String label;
  final VoidCallback? onTap;

  const _SocialButton({
    required this.assetPath,
    required this.label,
    required this.onTap,
  });

  static const double _logoSize = 22;

  static TextStyle _labelStyle(ColorScheme scheme) => TextStyle(
        fontSize: 13.5,
        fontWeight: FontWeight.w600,
        letterSpacing: 0.135,
        color: scheme.onSurface,
      );

  /// `true` si [label] tient en entier dans un bouton large de [width]
  /// (marges, bordure et logo compris), au facteur de texte courant.
  static bool fitsIn(BuildContext context, String label, double width) {
    final painter = TextPainter(
      text: TextSpan(
        text: label,
        style: DefaultTextStyle.of(context)
            .style
            .merge(_labelStyle(Theme.of(context).colorScheme)),
      ),
      textDirection: Directionality.of(context),
      textScaler: MediaQuery.textScalerOf(context),
      maxLines: 1,
    )..layout();
    final needed =
        painter.width + _logoSize + AppSpacing.s + 2 * AppSpacing.m + 2;
    painter.dispose();
    return needed <= width;
  }

  @override
  Widget build(BuildContext context) {
    final brightness = Theme.of(context).brightness;
    final isDark = brightness == Brightness.dark;
    final scheme = Theme.of(context).colorScheme;
    return Semantics(
      button: true,
      label: label,
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(14),
          child: Ink(
            height: 52,
            decoration: BoxDecoration(
              color: isDark ? AppColors.dsSurfaceDark : Colors.white,
              borderRadius: BorderRadius.circular(14),
              border: Border.all(
                color: AppColors.dsBorder(brightness),
                width: 1,
              ),
            ),
            padding: const EdgeInsets.symmetric(horizontal: AppSpacing.m),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Image.asset(assetPath, width: _logoSize, height: _logoSize),
                const SizedBox(width: AppSpacing.s),
                Flexible(
                  child: Text(
                    label,
                    overflow: TextOverflow.ellipsis,
                    maxLines: 1,
                    style: _labelStyle(scheme),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
