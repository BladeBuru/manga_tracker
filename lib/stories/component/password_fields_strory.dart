import 'package:dashbook/dashbook.dart';
import 'package:flutter/material.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/components/password_fields.dart';
import '../../../features/auth/services/validator.service.dart';

void addPasswordFieldsStory(Dashbook dashbook) {
  dashbook.storiesOf('Core/PasswordFields').add('Default', (ctx) {
    final formKey = GlobalKey<FormState>();
    final passwordController = TextEditingController();
    final confirmPasswordController = TextEditingController();
    final validator = FakeValidatorService();

    return MaterialApp(
      theme: AppTheme.light,
      home: Scaffold(
        body: SafeArea(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            child: Center(
              child: Container(
                width: 350,
                child: Form(
                  key: formKey,
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      PasswordFields(
                        passwordControler: passwordController,
                        confirmPasswordControler: confirmPasswordController,
                        validatorService: validator,
                      ),
                      const SizedBox(height: 20),
                      ElevatedButton(
                        onPressed: () {
                          final isValid = formKey.currentState?.validate() ?? false;
                          debugPrint("Formulaire valide : $isValid");
                        },
                        child: const Text('Valider'),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  });
}


class FakeValidatorService extends ValidatorService {
  @override
  String? validatePassword(String? value) {
    if (value == null || value.isEmpty) return 'Champ requis';
    if (value.length < 6) return 'Minimum 6 caractères';
    return null;
  }

  @override
  String? validateConfirmPassword(String? value, TextEditingController passwordController) {
    if (value == null || value.isEmpty) return 'Champ requis';
    if (value != passwordController.text) return 'Les mots de passe ne correspondent pas';
    return null;
  }
}
