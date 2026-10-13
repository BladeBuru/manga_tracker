import 'package:flutter/material.dart';
import 'package:mangatracker/features/profile/services/gdpr.service.dart';
import 'package:mangatracker/l10n/app_localizations.dart';

/// Dialog modal blocking demandant à l'utilisateur d'accepter les nouvelles
/// versions des CGU / Politique de confidentialité.
///
/// L'utilisateur a deux choix :
///  - Accepter (return true)
///  - Refuser → l'app le déconnecte (return false). Article 7 RGPD : le
///    consentement doit être libre, on doit donc proposer une issue.
///
/// (Extrait de `bottom_navbar.dart`, inchangé.)
class ConsentRefreshDialog extends StatefulWidget {
  final ConsentStatus status;

  const ConsentRefreshDialog({super.key, required this.status});

  @override
  State<ConsentRefreshDialog> createState() => _ConsentRefreshDialogState();
}

class _ConsentRefreshDialogState extends State<ConsentRefreshDialog> {
  bool _acceptedTos = false;
  bool _acceptedPrivacy = false;

  bool get _canAccept {
    final s = widget.status;
    final tosOk = !s.needsTosAcceptance || _acceptedTos;
    final privacyOk = !s.needsPrivacyAcceptance || _acceptedPrivacy;
    return tosOk && privacyOk;
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final s = widget.status;

    return AlertDialog(
      title: Text(l10n?.consentRefreshTitle ??
          'Mise à jour de nos conditions'),
      content: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              l10n?.consentRefreshIntro ??
                  'Nos conditions d\'utilisation et notre politique de confidentialité ont été mises à jour. '
                      'Veuillez les accepter pour continuer.',
              style: Theme.of(context).textTheme.bodyMedium,
            ),
            const SizedBox(height: 16),
            if (s.needsTosAcceptance)
              CheckboxListTile(
                value: _acceptedTos,
                onChanged: (v) => setState(() => _acceptedTos = v ?? false),
                title: Text(
                  l10n?.iAcceptTos ??
                      "J'accepte les Conditions d'utilisation",
                  style: const TextStyle(fontSize: 14),
                ),
                subtitle: Text(
                  '${l10n?.versionLabel ?? 'Version'} ${s.currentTosVersion}',
                  style: const TextStyle(fontSize: 11),
                ),
                controlAffinity: ListTileControlAffinity.leading,
                contentPadding: EdgeInsets.zero,
              ),
            if (s.needsPrivacyAcceptance)
              CheckboxListTile(
                value: _acceptedPrivacy,
                onChanged: (v) =>
                    setState(() => _acceptedPrivacy = v ?? false),
                title: Text(
                  l10n?.iAcceptPrivacy ??
                      "J'accepte la Politique de confidentialité",
                  style: const TextStyle(fontSize: 14),
                ),
                subtitle: Text(
                  '${l10n?.versionLabel ?? 'Version'} ${s.currentPrivacyVersion}',
                  style: const TextStyle(fontSize: 11),
                ),
                controlAffinity: ListTileControlAffinity.leading,
                contentPadding: EdgeInsets.zero,
              ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(false),
          child: Text(l10n?.refuseAndLogout ?? 'Refuser et se déconnecter'),
        ),
        FilledButton(
          onPressed: _canAccept
              ? () => Navigator.of(context).pop(true)
              : null,
          child: Text(l10n?.iAccept ?? 'Accepter'),
        ),
      ],
    );
  }
}
