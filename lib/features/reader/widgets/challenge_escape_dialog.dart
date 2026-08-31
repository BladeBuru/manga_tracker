import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:mangatracker/l10n/app_localizations.dart';

/// Ce que l'utilisateur a choisi face à une vérification qui boucle.
enum ChallengeEscapeAction {
  /// Fermer le message et rester sur place.
  dismiss,

  /// Réessayer la vérification dans le lecteur.
  retry,

  /// Poursuivre dans le navigateur du système.
  openedExternally,
}

/// Porte de sortie proposée quand une vérification anti-robot ne cesse de se
/// represente sans jamais aboutir.
///
/// L'application ne tente rien contre le défi : elle arrête simplement de
/// boucler et laisse l'utilisateur terminer la vérification dans son
/// navigateur, où elle aboutit généralement.
class ChallengeEscapeDialog extends StatelessWidget {
  const ChallengeEscapeDialog({super.key, required this.url});

  final String url;

  /// Affiche le dialogue et exécute l'action choisie.
  ///
  /// L'ouverture externe est réalisée ici afin que la vue du lecteur reste
  /// légère.
  static Future<ChallengeEscapeAction> show({
    required BuildContext context,
    required String url,
  }) async {
    final action = await showDialog<ChallengeEscapeAction>(
      context: context,
      barrierDismissible: false,
      builder: (_) => ChallengeEscapeDialog(url: url),
    );
    return action ?? ChallengeEscapeAction.dismiss;
  }

  String get _host {
    final uri = Uri.tryParse(url);
    final host = uri?.host ?? '';
    return host.isEmpty ? url : host;
  }

  Future<void> _openExternally(BuildContext context) async {
    final uri = Uri.tryParse(url);
    if (uri == null) {
      Navigator.pop(context, ChallengeEscapeAction.dismiss);
      return;
    }
    final navigator = Navigator.of(context);
    try {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
      navigator.pop(ChallengeEscapeAction.openedExternally);
    } catch (_) {
      navigator.pop(ChallengeEscapeAction.dismiss);
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);

    return AlertDialog(
      icon: const Icon(Icons.shield_outlined, color: Colors.orange, size: 48),
      title: Text(l10n?.challengeLoopTitle ?? 'Vérification bloquée'),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            l10n?.challengeLoopMessage ??
                "La vérification anti-robot de ce site n'aboutit pas : elle se "
                    'recharge en boucle. Ouvrez la page dans votre navigateur '
                    'pour la terminer, puis revenez ici.',
          ),
          const SizedBox(height: 12),
          Text(
            _host,
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  fontWeight: FontWeight.w600,
                ),
          ),
        ],
      ),
      actionsOverflowButtonSpacing: 8,
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context, ChallengeEscapeAction.dismiss),
          child: Text(l10n?.close ?? 'Fermer'),
        ),
        TextButton(
          onPressed: () => Navigator.pop(context, ChallengeEscapeAction.retry),
          child: Text(l10n?.retry ?? 'Réessayer'),
        ),
        FilledButton.icon(
          onPressed: () => _openExternally(context),
          icon: const Icon(Icons.open_in_browser, size: 18),
          label: Text(l10n?.challengeLoopOpenBrowser ?? 'Ouvrir dans le navigateur'),
        ),
      ],
    );
  }
}
