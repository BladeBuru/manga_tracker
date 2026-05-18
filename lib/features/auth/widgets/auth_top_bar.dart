import 'package:flutter/material.dart';
import 'package:mangatracker/core/components/language_selector_button.dart';
import 'package:mangatracker/core/components/theme_toggle_button.dart';
import 'package:mangatracker/core/theme/app_colors.dart';

/// Barre supérieure des pages d'auth : optionnellement un bouton retour
/// à gauche, et toujours le `ThemeToggleButton` + `LanguageSelectorButton`
/// à droite.
class AuthTopBar extends StatelessWidget {
  final VoidCallback? onBack;
  final String? backTooltip;

  const AuthTopBar({
    super.key,
    this.onBack,
    this.backTooltip,
  });

  @override
  Widget build(BuildContext context) {
    final brightness = Theme.of(context).brightness;
    return Row(
      mainAxisAlignment: onBack != null
          ? MainAxisAlignment.spaceBetween
          : MainAxisAlignment.end,
      children: [
        if (onBack != null)
          IconButton(
            icon: Icon(
              Icons.arrow_back,
              color: AppColors.dsText2(brightness),
            ),
            tooltip: backTooltip,
            onPressed: onBack,
          ),
        Row(
          mainAxisSize: MainAxisSize.min,
          children: const [
            ThemeToggleButton(),
            LanguageSelectorButton(),
          ],
        ),
      ],
    );
  }
}
