import 'package:flutter/material.dart';
import 'package:mangatracker/core/theme/app_colors.dart';
import 'package:mangatracker/core/theme/app_radius.dart';

/// Carte blanche (light) / `dsSurfaceDark` (dark) contenant les champs de
/// formulaire d'auth, avec un hairline border + radius 16 et des
/// dividers internes entre les enfants — V1 « Refined Classic ».
class AuthFormCard extends StatelessWidget {
  final List<Widget> children;

  const AuthFormCard({super.key, required this.children});

  @override
  Widget build(BuildContext context) {
    final brightness = Theme.of(context).brightness;
    final isDark = brightness == Brightness.dark;
    return Container(
      decoration: BoxDecoration(
        color: isDark ? AppColors.dsSurfaceDark : Colors.white,
        borderRadius: BorderRadius.circular(AppRadius.xxxl),
        border: Border.all(
          color: AppColors.dsHairline(brightness),
          width: 1,
        ),
        boxShadow: isDark
            ? null
            : const [
                BoxShadow(
                  color: Color(0x0A140A0A),
                  blurRadius: 2,
                  offset: Offset(0, 1),
                ),
              ],
      ),
      clipBehavior: Clip.antiAlias,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          for (int i = 0; i < children.length; i++) ...[
            children[i],
            if (i < children.length - 1)
              Padding(
                padding: const EdgeInsets.only(left: 16),
                child: Container(
                  height: 1,
                  color: AppColors.dsHairline(brightness),
                ),
              ),
          ],
        ],
      ),
    );
  }
}
