import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../theme/app_colors.dart';
import '../theme/app_text_styles.dart';

class AuthButton extends StatelessWidget {
  final String text;
  final Function()? onTap;
  final EdgeInsetsGeometry padding;
  final double borderRadius;

  const AuthButton({
    super.key,
    required this.text,
    required this.onTap,
    this.padding = const EdgeInsets.symmetric(horizontal: 32, vertical: 18),
    this.borderRadius = 30,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      borderRadius: BorderRadius.circular(borderRadius),
      child: InkWell(
        borderRadius: BorderRadius.circular(borderRadius),
        highlightColor: AppColors.highlight,
        splashColor: AppColors.splash,
        onTap: () {
          HapticFeedback.lightImpact();
          onTap?.call();
        },
        child: Ink(
          decoration: BoxDecoration(
            color: AppColors.background,
            borderRadius: BorderRadius.circular(borderRadius),
            border: Border.all(width: 2.5, color: AppColors.border),
          ),
          padding: padding,
          child: Center(
            child: Text(
              text,
              style: AppTextStyles.authButton,
            ),
          ),
        ),
      ),
    );
  }
}
