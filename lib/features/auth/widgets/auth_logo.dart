import 'package:flutter/material.dart';
import 'package:mangatracker/core/theme/app_radius.dart';
import 'package:mangatracker/core/theme/app_spacing.dart';

/// Logo applicatif enveloppé dans un container thème-aware.
///
/// L'asset PNG (`mask_logo-backgroud-white.png`) a un fond blanc fixe :
/// pour qu'il s'intègre proprement en mode sombre, on l'incruste dans une
/// surface tonale (`surfaceContainerHighest`) avec un coin arrondi
/// généreux. La "vignette" autour du logo suit ainsi le thème actif
/// (light / dark) sans toucher au fichier image.
///
/// Utilisé sur les pages `login.view.dart` et `register.view.dart` pour
/// garantir la cohérence visuelle entre les deux écrans d'auth.
class AuthLogo extends StatelessWidget {
  final String semanticLabel;
  final double height;

  const AuthLogo({
    super.key,
    required this.semanticLabel,
    this.height = 140,
  });

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Align(
      child: Container(
        padding: const EdgeInsets.all(AppSpacing.s),
        decoration: BoxDecoration(
          color: scheme.surfaceContainerHighest,
          borderRadius: AppRadius.circularJumbo,
          border: Border.all(
            color: scheme.outlineVariant.withValues(alpha: 0.5),
          ),
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(AppRadius.huge),
          child: Image.asset(
            'assets/images/mask_logo-backgroud-white.png',
            height: height,
            semanticLabel: semanticLabel,
          ),
        ),
      ),
    );
  }
}
