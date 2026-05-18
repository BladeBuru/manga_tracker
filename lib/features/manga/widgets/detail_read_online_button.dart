import 'package:flutter/material.dart';
import 'package:mangatracker/core/theme/app_spacing.dart';
import 'package:mangatracker/l10n/app_localizations.dart';

// ╔═══════════════════════════════════════════════════════════════════════╗
// ║  V1 « Refined Classic » — Bouton "Lire en ligne" full-width.          ║
// ║  Style FilledButton primary red, radius 14, height 48,                ║
// ║  halo subtil 0 8px 20px -8px primary.                                 ║
// ╚═══════════════════════════════════════════════════════════════════════╝

/// Bouton CTA "Lire en ligne" (ou "Ajouter un lien" si pas de customLink).
///
/// - Si [hasCustomLink] est `true` : icône open_in_new, label "Lire en ligne".
///   Tap → [onReadOnline]. Bouton "..." aligné à droite déclenche [onOpenMenu].
/// - Si [hasCustomLink] est `false` : icône link_off, label "Ajouter un lien".
///   Tap → [onAddLink].
class DetailReadOnlineButton extends StatelessWidget {
  final bool hasCustomLink;
  final VoidCallback onReadOnline;
  final VoidCallback onAddLink;
  final VoidCallback onOpenMenu;

  const DetailReadOnlineButton({
    super.key,
    required this.hasCustomLink,
    required this.onReadOnline,
    required this.onAddLink,
    required this.onOpenMenu,
  });

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final l10n = AppLocalizations.of(context)!;

    final shape = RoundedRectangleBorder(
      borderRadius: BorderRadius.circular(14),
    );

    if (!hasCustomLink) {
      return Padding(
        padding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.m,
          vertical: AppSpacing.xs,
        ),
        child: FilledButton.tonalIcon(
          onPressed: onAddLink,
          icon: const Icon(Icons.link_off, size: 18),
          label: Text(l10n.addLink),
          style: FilledButton.styleFrom(
            minimumSize: const Size.fromHeight(48),
            shape: shape,
            textStyle: const TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.w700,
              letterSpacing: 0.15,
            ),
          ),
        ),
      );
    }

    return Padding(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.m,
        vertical: AppSpacing.xs,
      ),
      child: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(14),
          boxShadow: [
            BoxShadow(
              color: scheme.primary.withAlpha(95),
              blurRadius: 20,
              spreadRadius: -8,
              offset: const Offset(0, 8),
            ),
          ],
        ),
        child: Stack(
          children: [
            FilledButton.icon(
              onPressed: onReadOnline,
              icon: const Icon(Icons.open_in_new_rounded, size: 18),
              label: Padding(
                padding: const EdgeInsets.only(right: 24),
                child: Text(l10n.readOnline),
              ),
              style: FilledButton.styleFrom(
                minimumSize: const Size.fromHeight(48),
                shape: shape,
                textStyle: const TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w700,
                  letterSpacing: 0.15,
                ),
              ),
            ),
            Positioned(
              top: 0,
              bottom: 0,
              right: 4,
              child: Center(
                child: IconButton(
                  icon: const Icon(Icons.more_vert, size: 18),
                  color: scheme.onPrimary,
                  tooltip: l10n.manageLink,
                  onPressed: onOpenMenu,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
