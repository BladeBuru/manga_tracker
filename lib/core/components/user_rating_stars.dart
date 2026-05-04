import 'package:flutter/material.dart';
import 'package:mangatracker/core/theme/app_radius.dart';

/// Widget de notation à 5 étoiles, mappé sur une note 0-10.
///
/// - Tap sur l'étoile N → note = N × 2 (donc 5 étoiles = 10/10).
/// - Tap sur la même étoile que la note actuelle → reset à 0 (supprime la note).
/// - Tap sur l'étoile 1 quand rating = 0 → 2 (passage de "non noté" à "1 étoile").
///
/// Affiche aussi le score textuel "X/10" à côté.
///
/// Compatible Android, iOS, Web (pas de `dart:io`, pas de packages
/// plateforme).
class UserRatingStars extends StatelessWidget {
  /// Note actuelle (0 à 10). 0 = non noté.
  final int rating;

  /// Appelé avec la nouvelle note quand l'utilisateur tape.
  /// Peut recevoir 0 si l'utilisateur retape sur la même étoile (toggle off).
  final ValueChanged<int>? onRatingChanged;

  /// Désactive l'interaction (par exemple si le manga n'est pas en
  /// bibliothèque).
  final bool readOnly;

  /// Taille des étoiles en pixels.
  final double size;

  const UserRatingStars({
    super.key,
    required this.rating,
    this.onRatingChanged,
    this.readOnly = false,
    this.size = 28,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final activeColor = theme.colorScheme.primary;
    final inactiveColor = theme.colorScheme.onSurface.withValues(alpha: 0.3);

    return Semantics(
      // Le label sémantique est passé par le parent via Semantics englobant.
      // (Aucune dépendance i18n directe ici — le widget reste utilisable
      // partout, et l'accessibilité est ajoutée par le contexte d'usage.)
      slider: !readOnly,
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          for (int i = 1; i <= 5; i++)
            _StarTapTarget(
              filled: rating >= i * 2,
              halfFilled: rating == i * 2 - 1,
              activeColor: activeColor,
              inactiveColor: inactiveColor,
              size: size,
              onTap: readOnly || onRatingChanged == null
                  ? null
                  : () => _handleStarTap(i),
            ),
          const SizedBox(width: 8),
          Text(
            rating == 0 ? '—' : '$rating/10',
            style: theme.textTheme.bodyMedium?.copyWith(
              fontWeight: FontWeight.w600,
              color: rating == 0 ? inactiveColor : activeColor,
            ),
          ),
        ],
      ),
    );
  }

  void _handleStarTap(int starIndex) {
    final tappedValue = starIndex * 2;
    // Toggle off : retap sur la même note → 0
    final newRating = rating == tappedValue ? 0 : tappedValue;
    onRatingChanged!(newRating);
  }
}

class _StarTapTarget extends StatelessWidget {
  final bool filled;
  final bool halfFilled;
  final Color activeColor;
  final Color inactiveColor;
  final double size;
  final VoidCallback? onTap;

  const _StarTapTarget({
    required this.filled,
    required this.halfFilled,
    required this.activeColor,
    required this.inactiveColor,
    required this.size,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final IconData icon;
    final Color color;
    if (filled) {
      icon = Icons.star_rounded;
      color = activeColor;
    } else if (halfFilled) {
      icon = Icons.star_half_rounded;
      color = activeColor;
    } else {
      icon = Icons.star_outline_rounded;
      color = inactiveColor;
    }

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(AppRadius.sm),
      child: Padding(
        padding: const EdgeInsets.all(2),
        child: Icon(icon, size: size, color: color),
      ),
    );
  }
}
