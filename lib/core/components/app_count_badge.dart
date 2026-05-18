import 'package:flutter/material.dart';
import 'package:mangatracker/core/theme/app_radius.dart';

/// Petit compteur rond inline du design system (Google look).
///
/// Pour les compteurs textuels (ex: "12 mangas", "3 amis"). Pour les
/// badges sur icônes, utiliser `Badge.count` Material 3 directement.
class AppCountBadge extends StatelessWidget {
  final int count;
  final String? suffix;
  final Color? backgroundColor;
  final Color? foregroundColor;

  const AppCountBadge({
    super.key,
    required this.count,
    this.suffix,
    this.backgroundColor,
    this.foregroundColor,
  });

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final bg = backgroundColor ?? scheme.primaryContainer;
    final fg = foregroundColor ?? scheme.onPrimaryContainer;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(color: bg, borderRadius: AppRadius.circularXs),
      child: Text(
        suffix != null ? '$count $suffix' : '$count',
        style: TextStyle(color: fg, fontSize: 11, fontWeight: FontWeight.w700),
      ),
    );
  }
}
