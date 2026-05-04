import 'package:flutter/material.dart';
import 'package:mangatracker/core/service_locator/service_locator.dart';
import 'package:mangatracker/core/theme/app_radius.dart';
import 'package:mangatracker/features/auth/services/email_auth.service.dart';
import 'package:mangatracker/l10n/app_localizations.dart';

/// Banner discret affiché en haut d'un écran principal quand l'utilisateur
/// n'a pas encore vérifié son email. Propose un bouton « Renvoyer le mail ».
///
/// À insérer manuellement dans la view du parent qui décide quand l'afficher
/// (par exemple HomePageBlocView ou Profile, sous le header). Le widget se
/// rend lui-même invisible si `visible == false`.
///
/// **Anti-spam** : le bouton « Renvoyer » est désactivé pendant 60 s après
/// chaque clic pour respecter le throttle serveur (3 req/min).
class VerifyEmailBanner extends StatefulWidget {
  /// `false` si l'email a déjà été vérifié (banner caché).
  final bool visible;

  const VerifyEmailBanner({super.key, required this.visible});

  @override
  State<VerifyEmailBanner> createState() => _VerifyEmailBannerState();
}

class _VerifyEmailBannerState extends State<VerifyEmailBanner> {
  bool _sending = false;
  bool _justSent = false;

  Future<void> _resend() async {
    if (_sending) return;
    setState(() => _sending = true);
    final ok = await getIt<EmailAuthService>().resendVerificationEmail();
    if (!mounted) return;
    setState(() {
      _sending = false;
      _justSent = ok;
    });
    if (!ok) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            AppLocalizations.of(context)?.networkError ??
                'Erreur réseau. Réessayez plus tard.',
          ),
        ),
      );
    } else {
      // Re-active le bouton après 60 s pour respecter le throttle serveur.
      Future.delayed(const Duration(seconds: 60), () {
        if (mounted) setState(() => _justSent = false);
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    if (!widget.visible) return const SizedBox.shrink();
    final l10n = AppLocalizations.of(context);

    return Container(
      width: double.infinity,
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.amber.withValues(alpha: 0.12),
        border: Border.all(color: Colors.amber.withValues(alpha: 0.5)),
        borderRadius: BorderRadius.circular(AppRadius.md),
      ),
      child: Row(
        children: [
          const Icon(Icons.mark_email_unread_outlined,
              color: Colors.amber, size: 22),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              l10n?.verifyEmailBannerMessage ??
                  'Vérifiez votre adresse email pour activer toutes les fonctionnalités.',
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: Colors.amber[900],
                    fontWeight: FontWeight.w500,
                  ),
            ),
          ),
          const SizedBox(width: 8),
          TextButton(
            onPressed: (_sending || _justSent) ? null : _resend,
            child: _sending
                ? const SizedBox(
                    width: 16,
                    height: 16,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : Text(
                    _justSent
                        ? (l10n?.emailSentShort ?? 'Envoyé')
                        : (l10n?.resendEmailShort ?? 'Renvoyer'),
                  ),
          ),
        ],
      ),
    );
  }
}
