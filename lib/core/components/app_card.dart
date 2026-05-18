import 'package:flutter/material.dart';
import 'package:mangatracker/core/theme/app_radius.dart';

/// Carte de contenu standard du design system (Google Material 3 look).
///
/// Surface tonale `surfaceContainerLow` + radius `xxxl` (16px) + padding 16px
/// + optional `onTap` qui ajoute un InkWell. À utiliser PARTOUT où on
/// affiche un bloc de contenu (résultat de recherche, item d'inbox, item
/// de groupe, info card, etc.).
///
/// Variantes :
///  - `AppCard.tonalPrimary` : fond `primaryContainer` pour mettre en
///    valeur (hero, header).
///  - `AppCard.outlined` : fond `surface` + bord `outlineVariant` pour
///    les cas sans backdrop coloré.
class AppCard extends StatelessWidget {
  final Widget child;
  final VoidCallback? onTap;
  final EdgeInsetsGeometry padding;
  final Color? backgroundColor;
  final BorderSide? side;

  const AppCard({
    super.key,
    required this.child,
    this.onTap,
    this.padding = const EdgeInsets.all(16),
    this.backgroundColor,
    this.side,
  });

  /// Variante "hero" : fond `primaryContainer`, padding 20. Static builder
  /// (Dart n'autorise pas qu'un factory retourne un sous-type private).
  static Widget tonalPrimary({
    Key? key,
    required Widget child,
    VoidCallback? onTap,
  }) {
    return _AppCardTonalPrimary(key: key, onTap: onTap, child: child);
  }

  /// Variante outlined : fond `surface` + bord `outlineVariant`.
  static Widget outlined({
    Key? key,
    required Widget child,
    VoidCallback? onTap,
  }) {
    return _AppCardOutlined(key: key, onTap: onTap, child: child);
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final shape = RoundedRectangleBorder(
      borderRadius: AppRadius.circularXxxl,
      side: side ?? BorderSide.none,
    );
    final card = Card(
      elevation: 0,
      color: backgroundColor ?? scheme.surfaceContainerLow,
      shape: shape,
      margin: EdgeInsets.zero,
      child: Padding(padding: padding, child: child),
    );
    if (onTap == null) return card;
    return InkWell(
      borderRadius: AppRadius.circularXxxl,
      onTap: onTap,
      child: card,
    );
  }
}

class _AppCardTonalPrimary extends StatelessWidget {
  final Widget child;
  final VoidCallback? onTap;
  const _AppCardTonalPrimary({super.key, required this.child, this.onTap});

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return AppCard(
      onTap: onTap,
      backgroundColor: scheme.primaryContainer,
      padding: const EdgeInsets.all(20),
      child: child,
    );
  }
}

class _AppCardOutlined extends StatelessWidget {
  final Widget child;
  final VoidCallback? onTap;
  const _AppCardOutlined({super.key, required this.child, this.onTap});

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return AppCard(
      onTap: onTap,
      backgroundColor: scheme.surface,
      side: BorderSide(color: scheme.outlineVariant),
      child: child,
    );
  }
}
