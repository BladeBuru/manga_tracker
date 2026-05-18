import 'package:flutter/material.dart';
import 'package:mangatracker/core/theme/app_radius.dart';

/// Tuile carrée (ou arrondie) pour les boutons OAuth (Google, Apple…).
///
/// Theme-aware : la surface et la bordure suivent le `ColorScheme` actif
/// (light / dark) pour rester lisibles dans les deux modes.
class SquareTile extends StatelessWidget {
  final String imagePath;
  final VoidCallback? onTap;
  final bool isRounded; // si true = rond, sinon carré
  final double size;

  const SquareTile({
    super.key,
    required this.imagePath,
    this.onTap,
    this.isRounded = false,
    this.size = 60,
  });

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final borderRadius =
        BorderRadius.circular(isRounded ? size : AppRadius.xxxl);

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: borderRadius,
        child: Ink(
          padding: const EdgeInsets.all(15),
          decoration: BoxDecoration(
            border: Border.all(
              color: scheme.outlineVariant.withValues(alpha: 0.6),
            ),
            borderRadius: borderRadius,
            color: scheme.surfaceContainerHighest,
          ),
          child: Image.asset(
            imagePath,
            height: size,
            width: size,
          ),
        ),
      ),
    );
  }
}
