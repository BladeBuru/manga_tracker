import 'package:flutter/material.dart';
import 'package:mangatracker/core/router/app_modals.dart';
import 'package:mangatracker/l10n/app_localizations.dart';

/// « Envoyer une demande d'ami à X ? » — un seul appui n'envoie plus rien.
Future<bool> confirmSendFriendRequest(BuildContext context, String name) {
  final l10n = AppLocalizations.of(context)!;
  return _confirm(
    context,
    title: l10n.friendsSendConfirmTitle(name),
    body: l10n.friendsSendConfirmBody,
    dismissLabel: l10n.cancel,
    confirmLabel: l10n.friendsSendConfirmAction,
  );
}

/// « Annuler la demande envoyée à X ? »
Future<bool> confirmCancelFriendRequest(BuildContext context, String name) {
  final l10n = AppLocalizations.of(context)!;
  return _confirm(
    context,
    title: l10n.friendsCancelConfirmTitle(name),
    dismissLabel: l10n.friendsKeepRequest,
    confirmLabel: l10n.friendsCancelRequest,
  );
}

Future<bool> _confirm(
  BuildContext context, {
  required String title,
  String? body,
  required String dismissLabel,
  required String confirmLabel,
}) async {
  final confirmed = await showAppDialog<bool>(
    context: context,
    builder: (ctx) => AlertDialog(
      scrollable: true,
      title: Text(title),
      content: body == null ? null : Text(body),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(ctx).pop(false),
          child: Text(dismissLabel),
        ),
        FilledButton(
          onPressed: () => Navigator.of(ctx).pop(true),
          child: Text(confirmLabel),
        ),
      ],
    ),
  );
  return confirmed == true;
}
