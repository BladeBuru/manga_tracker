import 'package:flutter/material.dart';
import 'package:mangatracker/core/theme/app_colors.dart';

/// Section V1 « Refined Classic » dédiée à la page Amis.
///
/// Réplique le pattern de `ProfileEditSection` (label uppercase tracké + carte
/// blanche/hairline avec dividers entre rows), mais avec un indent du divider
/// adapté aux avatars (58 px au lieu de 16 px pour les rows de profile_edit) :
/// pile l'avatar `medium` (40 px de diamètre) + padding gauche (14) + gap (4)
/// pour que la ligne démarre sous le texte, pas sous l'avatar.
class FriendsSectionCard extends StatelessWidget {
  final String label;
  final List<Widget> children;

  const FriendsSectionCard({
    super.key,
    required this.label,
    required this.children,
  });

  @override
  Widget build(BuildContext context) {
    final brightness = Theme.of(context).brightness;
    final isDark = brightness == Brightness.dark;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(left: 4, bottom: 10),
          child: Text(
            label.toUpperCase(),
            style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w600,
              letterSpacing: 0.88,
              color: AppColors.dsText2(brightness),
            ),
          ),
        ),
        Container(
          decoration: BoxDecoration(
            color: isDark ? AppColors.dsSurfaceDark : Colors.white,
            borderRadius: BorderRadius.circular(16),
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
                    padding: const EdgeInsets.only(left: 66),
                    child: Container(
                      height: 1,
                      color: AppColors.dsHairline(brightness),
                    ),
                  ),
              ],
            ],
          ),
        ),
      ],
    );
  }
}
