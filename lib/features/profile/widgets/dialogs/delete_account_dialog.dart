import 'package:flutter/material.dart';

import 'package:mangatracker/core/components/pastel_tile.dart';
import 'package:mangatracker/features/profile/widgets/dialogs/profile_dialog_shell.dart';
import 'package:mangatracker/l10n/app_localizations.dart';

/// Dialog de confirmation de suppression de compte (Design V1).
///
/// Le caller exécute la suppression si `true` est renvoyé.
Future<bool> showDeleteAccountConfirmDialog(BuildContext context) async {
  final l10n = AppLocalizations.of(context)!;
  final result = await showDialog<bool>(
    context: context,
    builder: (context) => ProfileDialogShell(
      icon: Icons.delete_outline,
      iconColor: PastelTileColor.red,
      title: l10n.confirmDeleteAccount,
      subtitle: l10n.confirmDeleteAccountMessage,
      danger: true,
      actions: [
        ProfileDialogCancelButton(
          label: l10n.cancel,
          onPressed: () => Navigator.of(context).pop(false),
        ),
        ProfileDialogConfirmButton(
          label: l10n.delete,
          onPressed: () => Navigator.of(context).pop(true),
        ),
      ],
    ),
  );
  return result ?? false;
}
