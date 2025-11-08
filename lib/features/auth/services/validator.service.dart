import 'package:flutter/material.dart';
import 'package:mangatracker/l10n/app_localizations.dart';

class ValidatorService {
  final RegExp emailRegex = RegExp(
    '^([a-zA-Z0-9_\\-\\.]+)@([a-zA-Z0-9_\\-\\.]+)\\.([a-zA-Z]{2,5})',
  );

  final RegExp pwdRegex = RegExp(
    r'^(?=.*[a-z])(?=.*[A-Z])(?=.*\d)(?=.*[^A-Za-z\d]).{8,64}$',
  );

  String? validateEmailAddress(String? value, BuildContext? context) {
    final l10n = context != null ? AppLocalizations.of(context) : null;
    
    if (value == null || value.isEmpty) {
      return l10n?.validationEmailRequired ?? 'Veuillez entrer votre adresse e-mail';
    }

    if (!emailRegex.hasMatch(value)) {
      return l10n?.validationEmailInvalid ?? 'Veuillez entrer une adresse e-mail valide';
    }
    return null;
  }

  String? validatePassword(String? value, BuildContext? context) {
    final l10n = context != null ? AppLocalizations.of(context) : null;
    
    if (value == null || value.isEmpty) {
      return l10n?.validationPasswordRequired ?? 'Veuillez entrer votre mot de passe';
    }

    if (!(8 <= value.length && value.length <= 64)) {
      return l10n?.validationPasswordLength ?? 'Votre mot de passe doit comporter entre 8 et 64 caractères';
    }

    if (!pwdRegex.hasMatch(value)) {
      return l10n?.validationPasswordComplexity ?? 'Votre mot de passe doit contenir au moins une lettre minuscule, une lettre majuscule et un caractère spécial';
    }
    return null;
  }

  String? validateConfirmPassword(
    String? value,
    TextEditingController pwdController,
    BuildContext? context,
  ) {
    final l10n = context != null ? AppLocalizations.of(context) : null;
    
    if (value == null || value.isEmpty) {
      return l10n?.validationConfirmPasswordRequired ?? 'Veuillez confirmer votre mot de passe';
    }

    if (value != pwdController.text) {
      return l10n?.validationPasswordsDoNotMatch ?? 'Les mots de passe ne correspondent pas';
    }
    return null;
  }

  String? noValidation(String? value) {
    return null;
  }
}
