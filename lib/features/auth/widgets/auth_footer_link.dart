import 'package:flutter/material.dart';
import 'package:mangatracker/core/theme/app_colors.dart';
import 'package:mangatracker/core/theme/app_spacing.dart';

/// Pied de page « Pas de compte ? S'inscrire » (et inverse sur register).
///
/// `Wrap` plutôt que `Row` : sur petit écran avec texte agrandi (ou en
/// allemand), le lien passe à la ligne au lieu de déborder.
class AuthFooterLink extends StatelessWidget {
  final String message;
  final String actionLabel;
  final VoidCallback onTap;

  const AuthFooterLink({
    super.key,
    required this.message,
    required this.actionLabel,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final brightness = Theme.of(context).brightness;
    final scheme = Theme.of(context).colorScheme;
    return Wrap(
      alignment: WrapAlignment.center,
      crossAxisAlignment: WrapCrossAlignment.center,
      spacing: AppSpacing.xs,
      children: [
        Text(
          message,
          textAlign: TextAlign.center,
          style: TextStyle(
            color: AppColors.dsText2(brightness),
            fontSize: 13,
            fontWeight: FontWeight.w500,
          ),
        ),
        TextButton(
          onPressed: onTap,
          style: TextButton.styleFrom(
            foregroundColor: scheme.primary,
            // Zone d'appui ≥ 40 dp même si le lien est court.
            minimumSize: const Size(40, 40),
            padding: const EdgeInsets.symmetric(horizontal: AppSpacing.xs),
            tapTargetSize: MaterialTapTargetSize.shrinkWrap,
            textStyle: const TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w700,
            ),
          ),
          child: Text(actionLabel, textAlign: TextAlign.center),
        ),
      ],
    );
  }
}
