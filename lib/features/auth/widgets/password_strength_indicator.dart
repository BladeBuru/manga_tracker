import 'package:flutter/material.dart';
import 'package:mangatracker/core/theme/app_colors.dart';
import 'package:mangatracker/l10n/app_localizations.dart';

/// Indicateur de robustesse du mot de passe — barre + label sous le champ.
///
/// Calcul de robustesse compatible avec celui du `PasswordFields` legacy
/// (length, casse, chiffres, symboles).
class PasswordStrengthIndicator extends StatelessWidget {
  /// Valeur courante du mot de passe à analyser.
  final String value;

  const PasswordStrengthIndicator({super.key, required this.value});

  double get _strength {
    if (value.isEmpty) return 0;
    double s = 0;
    if (value.length >= 8) s += 0.25;
    if (value.length >= 12) s += 0.15;
    if (RegExp(r'[a-z]').hasMatch(value)) s += 0.15;
    if (RegExp(r'[A-Z]').hasMatch(value)) s += 0.15;
    if (RegExp(r'\d').hasMatch(value)) s += 0.15;
    if (RegExp(r'[^A-Za-z0-9]').hasMatch(value)) s += 0.15;
    return s.clamp(0, 1);
  }

  @override
  Widget build(BuildContext context) {
    if (value.isEmpty) return const SizedBox.shrink();
    final brightness = Theme.of(context).brightness;
    final scheme = Theme.of(context).colorScheme;
    final l10n = AppLocalizations.of(context);
    final strength = _strength;
    final (label, color) = _labelAndColor(strength, scheme, l10n);
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(999),
            child: LinearProgressIndicator(
              value: strength,
              minHeight: 4,
              valueColor: AlwaysStoppedAnimation<Color>(color),
              backgroundColor: AppColors.dsBgInset(brightness),
            ),
          ),
          const SizedBox(height: 4),
          Text(
            label,
            style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w600,
              letterSpacing: 0.2,
              color: color,
            ),
          ),
        ],
      ),
    );
  }

  (String, Color) _labelAndColor(
    double strength,
    ColorScheme scheme,
    AppLocalizations? l10n,
  ) {
    if (strength < 0.34) {
      return (
        l10n?.passwordStrengthWeak ?? 'Faible',
        scheme.error,
      );
    }
    if (strength < 0.67) {
      return (
        l10n?.passwordStrengthMedium ?? 'Moyen',
        scheme.tertiary,
      );
    }
    return (
      l10n?.passwordStrengthStrong ?? 'Fort',
      scheme.primary,
    );
  }
}
