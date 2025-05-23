import 'package:flutter/material.dart';

import '../../features/auth/services/validator.service.dart';
import '../../features/auth/views/widgets/intput_textfield.dart';

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
          textField: widget.update ? 'Nouveau mot de passe' : 'Mot de passe',
          obscureText: true,
          validator: widget.validatorService.validatePassword,
        ),

        const SizedBox(height: 15),

        IntputTexteField(
          controller: widget.confirmPasswordControler,
          textField: 'Confirmation',
          obscureText: true,
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
