import 'package:flutter/material.dart';
import 'package:mangatracker/core/theme/app_colors.dart';
import 'package:mangatracker/core/theme/app_spacing.dart';

/// Hero de bienvenue pour les pages d'auth : logo 80x80 + titre + sous-titre.
///
/// V1 « Refined Classic » : logo en mask (transparent) sur un disque
/// `bg-inset` avec hairline border, titre 24px w800, sous-titre 14px
/// `dsText2`.
class AuthHero extends StatelessWidget {
  final String title;
  final String? subtitle;
  final String logoSemanticLabel;

  const AuthHero({
    super.key,
    required this.title,
    required this.logoSemanticLabel,
    this.subtitle,
  });

  @override
  Widget build(BuildContext context) {
    final brightness = Theme.of(context).brightness;
    final scheme = Theme.of(context).colorScheme;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        Container(
          width: 80,
          height: 80,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: AppColors.dsBgInset(brightness),
            border: Border.all(
              color: AppColors.dsHairline(brightness),
              width: 1,
            ),
          ),
          clipBehavior: Clip.antiAlias,
          child: Padding(
            padding: const EdgeInsets.all(8),
            child: Image.asset(
              'assets/images/mask_logo.png',
              semanticLabel: logoSemanticLabel,
              fit: BoxFit.contain,
            ),
          ),
        ),
        const SizedBox(height: AppSpacing.l),
        Text(
          title,
          textAlign: TextAlign.center,
          style: TextStyle(
            fontSize: 24,
            fontWeight: FontWeight.w800,
            letterSpacing: -0.6, // -0.025em * 24
            color: scheme.onSurface,
            height: 1.2,
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
              color: AppColors.dsText2(brightness),
              height: 1.4,
            ),
          ),
        ],
      ],
    );
  }
}
