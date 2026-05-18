import 'package:flutter/material.dart';
import 'package:mangatracker/core/theme/app_radius.dart';
import 'package:mangatracker/core/theme/app_spacing.dart';
import 'package:mangatracker/l10n/app_localizations.dart';

/// Bandeau "Mode hors ligne" réutilisable du design system.
///
/// **Refactor (2026-05-18)** : remplace les implémentations hardcodées
/// avec `Colors.orange` qui étaient dispersées dans 5+ pages (home,
/// homepage_bloc, library, library_bloc, detail_bloc). Maintenant un
/// seul style, cohérent avec le theme rouge de l'app.
///
/// Style : `errorContainer` (rouge clair tonal) au lieu d'orange vif —
/// l'orange était mal perçu visuellement, le rouge clair signale aussi
/// bien l'état dégradé sans agresser.
///
/// Inclut le compteur d'actions en attente si > 0.
class OfflineBanner extends StatelessWidget {
  final int pendingActions;
  final EdgeInsetsGeometry? margin;

  const OfflineBanner({
    super.key,
    this.pendingActions = 0,
    this.margin,
  });

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final l10n = AppLocalizations.of(context);
    return Container(
      width: double.infinity,
      margin: margin ?? const EdgeInsets.only(bottom: AppSpacing.s + 4),
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.m,
        vertical: AppSpacing.s + 2,
      ),
      decoration: BoxDecoration(
        color: scheme.errorContainer,
        borderRadius: AppRadius.circularMd,
        border: Border.all(
          color: scheme.error.withValues(alpha: 0.3),
          width: 1,
        ),
      ),
      child: Row(
        children: [
          Icon(
            Icons.cloud_off,
            size: 18,
            color: scheme.onErrorContainer,
          ),
          const SizedBox(width: AppSpacing.s),
          Expanded(
            child: Text(
              l10n?.offlineMode ?? 'Hors ligne',
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: scheme.onErrorContainer,
                    fontWeight: FontWeight.w600,
                  ),
            ),
          ),
          if (pendingActions > 0) ...[
            const SizedBox(width: AppSpacing.s),
            Container(
              padding: const EdgeInsets.symmetric(
                horizontal: AppSpacing.s,
                vertical: 2,
              ),
              decoration: BoxDecoration(
                color: scheme.error,
                borderRadius: AppRadius.circularXs,
              ),
              child: Text(
                '$pendingActions ${l10n?.pendingActions ?? "en attente"}',
                style: TextStyle(
                  color: scheme.onError,
                  fontSize: 11,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }
}
