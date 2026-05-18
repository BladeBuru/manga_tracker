import 'package:flutter/material.dart';
import 'package:mangatracker/core/theme/app_colors.dart';
import 'package:mangatracker/core/theme/app_spacing.dart';

/// Rangée de boutons de login social (Google + Apple).
///
/// V1 : 2 boutons outlined côte-à-côte, height 52px, radius 14px,
/// logo + label. Bordure hairline, fond surface.
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
    return Row(
      children: [
        Expanded(
          child: _SocialButton(
            assetPath: 'assets/images/google_logo.png',
            label: googleLabel,
            onTap: disabled || onGoogle == null
                ? null
                : () => onGoogle!(),
          ),
        ),
        const SizedBox(width: AppSpacing.m),
        Expanded(
          child: _SocialButton(
            assetPath: 'assets/images/apple_logo.png',
            label: appleLabel,
            onTap: disabled ? null : onApple,
          ),
        ),
      ],
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
                Image.asset(assetPath, width: 22, height: 22),
                const SizedBox(width: AppSpacing.s),
                Flexible(
                  child: Text(
                    label,
                    overflow: TextOverflow.ellipsis,
                    maxLines: 1,
                    style: TextStyle(
                      fontSize: 13.5,
                      fontWeight: FontWeight.w600,
                      letterSpacing: 0.135,
                      color: scheme.onSurface,
                    ),
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
