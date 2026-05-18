import 'package:flutter/material.dart';
import 'package:mangatracker/core/theme/app_colors.dart';
import 'package:mangatracker/core/theme/app_spacing.dart';

/// Bouton de connexion biométrique discret affiché uniquement quand la
/// biométrie est activée. Style V1 : outline hairline, radius 14,
/// icône fingerprint + label.
class BiometricLoginButton extends StatelessWidget {
  final String label;
  final VoidCallback onTap;

  const BiometricLoginButton({
    super.key,
    required this.label,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final brightness = Theme.of(context).brightness;
    final scheme = Theme.of(context).colorScheme;
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(14),
        child: Ink(
          height: 48,
          decoration: BoxDecoration(
            color: Colors.transparent,
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
              Icon(
                Icons.fingerprint,
                color: scheme.primary,
                size: 20,
              ),
              const SizedBox(width: AppSpacing.s),
              Text(
                label,
                style: TextStyle(
                  fontSize: 13.5,
                  fontWeight: FontWeight.w600,
                  color: AppColors.dsText2(brightness),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
