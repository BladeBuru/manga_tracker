import 'package:flutter/material.dart';
import 'package:mangatracker/l10n/app_localizations.dart';

import '../../features/auth/services/validator.service.dart';
import 'intput_textfield.dart';

class PasswordFields extends StatefulWidget {
  final TextEditingController passwordControler;
  final TextEditingController confirmPasswordControler;
  final ValidatorService validatorService;
  final bool update;

  const PasswordFields({
    super.key,
    required this.passwordControler,
    required this.confirmPasswordControler,
    required this.validatorService,
    this.update = false,
  });

  @override
  State<PasswordFields> createState() => _PasswordFieldsState();
}

class _PasswordFieldsState extends State<PasswordFields> {
  late final FocusNode _confirmFocusNode;

  @override
  void initState() {
    super.initState();
    _confirmFocusNode = FocusNode();
  }

  @override
  void dispose() {
    _confirmFocusNode.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    
    return Column(
      children: [
        IntputTexteField(
          controller: widget.passwordControler,
          hintText: widget.update 
              ? (l10n?.newPassword ?? 'Nouveau mot de passe')
              : (l10n?.password ?? 'Mot de passe'),
          obscureText: true,
          keyboardType: TextInputType.visiblePassword,
          validator: widget.validatorService.validatePassword,
          autofillHints: widget.update 
              ? const [AutofillHints.newPassword]
              : const [AutofillHints.password],
          textInputAction: TextInputAction.next,
          onSubmitted: () {
            _confirmFocusNode.requestFocus();
          },
        ),

        const SizedBox(height: 15),

        IntputTexteField(
          controller: widget.confirmPasswordControler,
          hintText: l10n?.confirmPassword ?? 'Confirmation',
          obscureText: true,
          keyboardType: TextInputType.visiblePassword,
          validator: (value) {
            return widget.validatorService.validateConfirmPassword(
              value,
              widget.passwordControler,
            );
          },
          autofillHints: widget.update 
              ? const [AutofillHints.newPassword]
              : const [AutofillHints.newPassword],
          textInputAction: TextInputAction.done,
          focusNode: _confirmFocusNode,
        ),
      ],
    );
  }
}
