import 'package:flutter/material.dart';

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
  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        IntputTexteField(
          controller: widget.passwordControler,
          hintText: widget.update ? 'Nouveau mot de passe' : 'Mot de passe',
          obscureText: true,
          keyboardType: TextInputType.visiblePassword,
          validator: widget.validatorService.validatePassword,
          autofillHints: const [AutofillHints.newPassword,AutofillHints.password],
        ),

        const SizedBox(height: 15),

        IntputTexteField(
          controller: widget.confirmPasswordControler,
          hintText: 'Confirmation',
          obscureText: true,
          keyboardType: TextInputType.visiblePassword,
          validator: (value) {
            return widget.validatorService.validateConfirmPassword(
              value,
              widget.passwordControler,
            );
          },
        ),
      ],
    );
  }
}
