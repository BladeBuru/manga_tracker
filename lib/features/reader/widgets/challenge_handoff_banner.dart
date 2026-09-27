import 'package:flutter/material.dart';
import 'package:mangatracker/core/theme/app_spacing.dart';
import 'package:mangatracker/l10n/app_localizations.dart';

/// Bandeau affiché au-dessus d'une vérification anti-robot confiée à une
/// WebView brute (voir `ChallengeHandoffView`).
///
/// Dit à l'utilisateur ce qui se passe (la page n'est pas le chapitre, c'est
/// la vérification du site) et que la lecture reprendra seule. La sortie vers
/// le navigateur externe reste à portée de main si la vérification n'aboutit
/// pas.
class ChallengeHandoffBanner extends StatelessWidget {
  const ChallengeHandoffBanner({super.key, required this.onOpenInBrowser});

  final VoidCallback onOpenInBrowser;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final scheme = Theme.of(context).colorScheme;
    final onContainer = scheme.onSecondaryContainer;
    return Material(
      color: scheme.secondaryContainer,
      child: SafeArea(
        top: false,
        bottom: false,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(
            AppSpacing.m,
            AppSpacing.s,
            AppSpacing.s,
            AppSpacing.s,
          ),
          child: Row(
            children: [
              Icon(Icons.verified_user_outlined, color: onContainer),
              const SizedBox(width: AppSpacing.s),
              Expanded(
                child: Text(
                  l10n?.readerChallengeHandoffInfo ??
                      'Vérification de sécurité du site : suivez ses '
                          'instructions, la lecture reprendra automatiquement.',
                  style: Theme.of(context)
                      .textTheme
                      .bodySmall
                      ?.copyWith(color: onContainer),
                ),
              ),
              const SizedBox(width: AppSpacing.xs),
              TextButton(
                onPressed: onOpenInBrowser,
                child: Text(
                  l10n?.challengeLoopOpenBrowser ?? 'Ouvrir dans le navigateur',
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
