import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../theme/app_text_styles.dart';
import '../theme/app_colors.dart';

class AuthButton extends StatelessWidget {
  final String text;
  final Function()? onTap;
  final EdgeInsetsGeometry padding;
  final double borderRadius;

  const AuthButton({
    super.key,
    required this.text,
    required this.onTap,
    this.padding = const EdgeInsets.symmetric(horizontal: 30.0, vertical: 16),
    this.borderRadius = 25,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 30.0),
      child: Material(
        borderRadius: BorderRadius.circular(borderRadius),
        child: InkWell(
          borderRadius: BorderRadius.circular(borderRadius),
          highlightColor: Colors.grey[200],
          splashColor: Colors.grey[300],
          onTap: () {
            HapticFeedback.lightImpact();
            onTap?.call();
          },
          child: Ink(
            decoration: BoxDecoration(
              color: Colors.grey[100],
              borderRadius: BorderRadius.circular(borderRadius),
              border: Border.all(
                width: 1.5,
                color: AppColors.primary,
              ),
            ),
            padding: padding,
            child: SizedBox(
              width: double.infinity,
              child: Center(
                child: Text(
                  text,
                  style: AppTextStyles.authButton.copyWith(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
