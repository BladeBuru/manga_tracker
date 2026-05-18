import 'package:flutter/material.dart';

import 'package:mangatracker/core/components/password_fields.dart';
import 'package:mangatracker/core/components/pastel_tile.dart';
import 'package:mangatracker/core/service_locator/service_locator.dart';
import 'package:mangatracker/features/auth/services/validator.service.dart';
import 'package:mangatracker/features/profile/widgets/dialogs/profile_dialog_shell.dart';
import 'package:mangatracker/l10n/app_localizations.dart';

/// Dialog de changement de mot de passe (Design V1).
///
/// Retourne le nouveau mot de passe ou `null` si annulé / invalide.
Future<String?> showChangePasswordDialog(BuildContext context) async {
  final l10n = AppLocalizations.of(context)!;
  final formKey = GlobalKey<FormState>();
  final passwordController = TextEditingController();
  final confirmController = TextEditingController();

  final result = await showDialog<String>(
    context: context,
    builder: (context) => _ChangePasswordDialog(
      formKey: formKey,
      passwordController: passwordController,
      confirmController: confirmController,
      l10n: l10n,
    ),
  );

  passwordController.dispose();
  confirmController.dispose();
  return result;
}

class _ChangePasswordDialog extends StatefulWidget {
  final GlobalKey<FormState> formKey;
  final TextEditingController passwordController;
  final TextEditingController confirmController;
  final AppLocalizations l10n;

  const _ChangePasswordDialog({
    required this.formKey,
    required this.passwordController,
    required this.confirmController,
    required this.l10n,
  });

  @override
  State<_ChangePasswordDialog> createState() => _ChangePasswordDialogState();
}

class _ChangePasswordDialogState extends State<_ChangePasswordDialog> {
  bool _canSubmit = false;

  @override
  void initState() {
    super.initState();
    widget.passwordController.addListener(_evaluateCanSubmit);
    widget.confirmController.addListener(_evaluateCanSubmit);
  }

  @override
  void dispose() {
    widget.passwordController.removeListener(_evaluateCanSubmit);
    widget.confirmController.removeListener(_evaluateCanSubmit);
    super.dispose();
  }

  void _evaluateCanSubmit() {
    final canSubmit = widget.passwordController.text.isNotEmpty &&
        widget.confirmController.text.isNotEmpty;
    if (canSubmit != _canSubmit) {
      setState(() => _canSubmit = canSubmit);
    }
  }

  void _onSubmit() {
    if (!widget.formKey.currentState!.validate()) return;
    Navigator.of(context).pop(widget.passwordController.text);
  }

  @override
  Widget build(BuildContext context) {
    return ProfileDialogShell(
      icon: Icons.lock_outline,
      iconColor: PastelTileColor.yellow,
      title: widget.l10n.changePassword,
      subtitle: widget.l10n.changePasswordSubtitle,
      actions: [
        ProfileDialogCancelButton(
          label: widget.l10n.cancel,
          onPressed: () => Navigator.of(context).pop(),
        ),
        ProfileDialogConfirmButton(
          label: widget.l10n.save,
          onPressed: _canSubmit ? _onSubmit : null,
        ),
      ],
      child: Form(
        key: widget.formKey,
        child: SingleChildScrollView(
          child: PasswordFields(
            passwordControler: widget.passwordController,
            confirmPasswordControler: widget.confirmController,
            validatorService: getIt<ValidatorService>(),
            update: true,
          ),
        ),
      ),
    );
  }
}
