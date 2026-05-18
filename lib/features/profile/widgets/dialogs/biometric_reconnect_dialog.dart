import 'package:flutter/material.dart';

import 'package:mangatracker/core/components/pastel_tile.dart';
import 'package:mangatracker/features/profile/widgets/dialogs/profile_dialog_shell.dart';
import 'package:mangatracker/l10n/app_localizations.dart';

/// Dialog "biométrie nécessite une reconnexion" (Design V1).
///
/// Retourne `true` si l'utilisateur a choisi de se déconnecter immédiatement.
Future<bool> showBiometricReconnectInfoDialog(BuildContext context) async {
  final l10n = AppLocalizations.of(context)!;
  final result = await showDialog<bool>(
    context: context,
    builder: (context) => ProfileDialogShell(
      icon: Icons.fingerprint,
      iconColor: PastelTileColor.purple,
      title: l10n.biometricAuthTitle,
      subtitle: l10n.biometricAuthRequiresReconnect,
      actions: [
        ProfileDialogCancelButton(
          label: l10n.cancel,
          onPressed: () => Navigator.of(context).pop(false),
        ),
        ProfileDialogConfirmButton(
          label: l10n.logout,
          onPressed: () => Navigator.of(context).pop(true),
        ),
      ],
    ),
  );
  return result ?? false;
}
