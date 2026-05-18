import 'package:flutter/material.dart';

import 'package:mangatracker/core/components/pastel_tile.dart';
import 'package:mangatracker/features/profile/widgets/dialogs/profile_dialog_shell.dart';
import 'package:mangatracker/l10n/app_localizations.dart';

/// Dialog de confirmation de déconnexion (Design V1).
///
/// Retourne `true` si l'utilisateur a confirmé.
Future<bool> showLogoutConfirmDialog(BuildContext context) async {
  final l10n = AppLocalizations.of(context)!;
  final result = await showDialog<bool>(
    context: context,
    builder: (context) => ProfileDialogShell(
      icon: Icons.logout,
      iconColor: PastelTileColor.red,
      title: l10n.confirmLogout,
      subtitle: l10n.confirmLogoutMessage,
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
