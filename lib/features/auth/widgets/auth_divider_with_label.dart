import 'package:flutter/material.dart';
import 'package:mangatracker/core/theme/app_colors.dart';
import 'package:mangatracker/core/theme/app_spacing.dart';

/// Séparateur visuel `── label ──` utilisé pour annoncer la rangée des
/// providers OAuth (« ou se connecter avec »).
class AuthDividerWithLabel extends StatelessWidget {
  final String label;

  const AuthDividerWithLabel({super.key, required this.label});

  @override
  Widget build(BuildContext context) {
    final brightness = Theme.of(context).brightness;
    final dividerColor = AppColors.dsHairline(brightness);
    final textColor = AppColors.dsText2(brightness);
    return Row(
      children: [
        Expanded(child: Divider(thickness: 1, color: dividerColor)),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: AppSpacing.m),
          child: Text(
            label,
            style: TextStyle(
              color: textColor,
              fontSize: 12.5,
              fontWeight: FontWeight.w500,
              letterSpacing: 0.2,
            ),
          ),
        ),
        Expanded(child: Divider(thickness: 1, color: dividerColor)),
      ],
    );
  }
}
