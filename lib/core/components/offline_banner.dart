import 'package:flutter/material.dart';
import 'package:mangatracker/core/theme/app_radius.dart';
import 'package:mangatracker/core/theme/app_spacing.dart';
import 'package:mangatracker/l10n/app_localizations.dart';

/// Bandeau « Mode hors ligne » du design system : les données affichées
/// viennent de l'appareil.
///
/// Refonte 2026-10 (retours utilisateurs) : le compteur affichait
/// « 112 Closure: (int) => String… » (méthode de traduction non appelée) et,
/// placé dans la même ligne sans pouvoir se réduire, écrasait le libellé
/// lettre par lettre (« Mo / de / hor / s… »). Désormais deux lignes
/// empilées, chacune sur une ligne, et une surface tonale discrète plutôt
/// qu'un aplat rouge.
class OfflineBanner extends StatelessWidget {
  final int pendingActions;
  final EdgeInsetsGeometry? margin;

  const OfflineBanner({super.key, this.pendingActions = 0, this.margin});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final scheme = Theme.of(context).colorScheme;
    return StatusBanner(
      margin: margin,
      icon: Icons.cloud_off_outlined,
      background: scheme.surfaceContainerHigh,
      foreground: scheme.onSurface,
      accent: scheme.error,
      title: l10n.offlineMode,
      subtitle: pendingActions > 0 ? l10n.pendingActions(pendingActions) : null,
    );
  }
}

/// Bandeau « modifications en attente d'envoi », réseau disponible : ce qui
/// a été fait hors ligne n'est pas encore parti. Neutre — rien n'est cassé —
/// avec l'action « Synchroniser ».
class PendingSyncBanner extends StatelessWidget {
  final int pendingActions;
  final VoidCallback? onSync;
  final EdgeInsetsGeometry? margin;

  const PendingSyncBanner({
    super.key,
    required this.pendingActions,
    this.onSync,
    this.margin,
  });

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final scheme = Theme.of(context).colorScheme;
    return StatusBanner(
      margin: margin,
      icon: Icons.cloud_upload_outlined,
      background: scheme.secondaryContainer,
      foreground: scheme.onSecondaryContainer,
      accent: scheme.onSecondaryContainer,
      title: l10n.pendingSyncTitle,
      subtitle: l10n.pendingActions(pendingActions),
      action: onSync == null
          ? null
          : TextButton(onPressed: onSync, child: Text(l10n.syncNowAction)),
    );
  }
}

/// Mise en page commune des bandeaux d'état : icône, titre, sous-titre
/// optionnel, action optionnelle. Aucun texte ne peut écraser l'autre.
class StatusBanner extends StatelessWidget {
  final IconData icon;
  final Color background;
  final Color foreground;
  final Color accent;
  final String title;
  final String? subtitle;
  final Widget? action;
  final EdgeInsetsGeometry? margin;

  const StatusBanner({
    super.key,
    required this.icon,
    required this.background,
    required this.foreground,
    required this.accent,
    required this.title,
    this.subtitle,
    this.action,
    this.margin,
  });

  @override
  Widget build(BuildContext context) {
    final text = Theme.of(context).textTheme;
    return Semantics(
      liveRegion: true,
      container: true,
      child: Container(
        width: double.infinity,
        margin: margin ?? const EdgeInsets.only(bottom: AppSpacing.s + 4),
        padding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.m,
          vertical: AppSpacing.s + 2,
        ),
        decoration: BoxDecoration(
          color: background,
          borderRadius: AppRadius.circularMd,
        ),
        child: Row(
          children: [
            Icon(icon, size: 20, color: accent),
            const SizedBox(width: AppSpacing.s + 4),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    title,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: text.labelLarge?.copyWith(
                      color: foreground,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  if (subtitle != null)
                    Text(
                      subtitle!,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: text.bodySmall?.copyWith(
                        color: foreground.withValues(alpha: 0.75),
                      ),
                    ),
                ],
              ),
            ),
            if (action != null) ...[
              const SizedBox(width: AppSpacing.s),
              action!,
            ],
          ],
        ),
      ),
    );
  }
}
