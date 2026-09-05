import 'package:flutter/material.dart';
import 'package:mangatracker/core/theme/app_colors.dart';
import 'package:mangatracker/core/theme/app_radius.dart';

/// Bloc de squelette (skeleton screen) du design system.
///
/// Rectangle arrondi `dsBgInset`, sans animation : reste stable en test
/// (`pumpAndSettle`) et ne consomme rien pendant les chargements longs.
/// Composer plusieurs boites pour esquisser une carte, une ligne de titre…
class AppSkeletonBox extends StatelessWidget {
  final double? width;
  final double? height;
  final BorderRadius? borderRadius;

  const AppSkeletonBox({
    super.key,
    this.width,
    this.height,
    this.borderRadius,
  });

  @override
  Widget build(BuildContext context) {
    final brightness = Theme.of(context).brightness;
    return ExcludeSemantics(
      child: Container(
        width: width,
        height: height,
        decoration: BoxDecoration(
          color: AppColors.dsBgInset(brightness),
          borderRadius: borderRadius ?? AppRadius.circularMd,
        ),
      ),
    );
  }
}
