import 'package:flutter/material.dart';
import 'package:mangatracker/core/theme/app_radius.dart';
import 'package:mangatracker/core/theme/app_spacing.dart';
import 'package:mangatracker/l10n/app_localizations.dart';

/// Bandeau « session expirée » — **invitation, jamais blocage**.
///
/// S'affiche quand le serveur a rejeté la session (401/403) alors que du
/// contenu en cache reste affiché derrière. Contrairement à l'ancienne
/// redirection forcée vers le login, l'utilisateur garde accès à ce qu'il a
/// déjà consulté : le cache local ne contient que ce que **cet** utilisateur
/// avait déjà obtenu en étant authentifié.
///
/// Distinct d'[OfflineBanner] à dessein :
///  - `OfflineBanner` (rouge tonal) = « je n'ai pas pu joindre le serveur » ;
///  - celui-ci (secondaire tonal) = « le serveur répond, mais ne me reconnaît
///    plus » — l'appareil EST en ligne, dire « hors ligne » serait faux.
///
/// L'action est facultative : sans [onReconnect], le bandeau reste purement
/// informatif.
class SessionRejectedBanner extends StatelessWidget {
  /// Ouvre l'écran de connexion. `null` ⇒ bandeau informatif seul.
  final VoidCallback? onReconnect;

  final EdgeInsetsGeometry? margin;

  const SessionRejectedBanner({
    super.key,
    this.onReconnect,
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
        vertical: AppSpacing.s,
      ),
      decoration: BoxDecoration(
        color: scheme.secondaryContainer,
        borderRadius: AppRadius.circularMd,
        border: Border.all(
          color: scheme.secondary.withValues(alpha: 0.3),
          width: 1,
        ),
      ),
      child: Row(
        children: [
          Icon(
            Icons.lock_clock_outlined,
            size: 18,
            color: scheme.onSecondaryContainer,
          ),
          const SizedBox(width: AppSpacing.s),
          Expanded(
            child: Text(
              l10n?.sessionRejectedBanner ??
                  'Session expirée — voici vos données enregistrées',
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: scheme.onSecondaryContainer,
                    fontWeight: FontWeight.w600,
                  ),
            ),
          ),
          if (onReconnect != null) ...[
            const SizedBox(width: AppSpacing.s),
            TextButton(
              onPressed: onReconnect,
              style: TextButton.styleFrom(
                foregroundColor: scheme.onSecondaryContainer,
                padding: const EdgeInsets.symmetric(
                  horizontal: AppSpacing.s,
                ),
                minimumSize: const Size(0, 32),
                tapTargetSize: MaterialTapTargetSize.shrinkWrap,
              ),
              child: Text(
                l10n?.sessionRejectedAction ?? 'Se reconnecter',
                style: const TextStyle(
                  fontSize: 12,
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
