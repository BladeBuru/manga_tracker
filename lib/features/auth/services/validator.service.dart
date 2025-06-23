import 'package:flutter/material.dart';

class ValidatorService {
  final RegExp emailRegex = RegExp(
    '^([a-zA-Z0-9_\\-\\.]+)@([a-zA-Z0-9_\\-\\.]+)\\.([a-zA-Z]{2,5})',
  );


  final RegExp pwdRegex = RegExp(
    r'^(?=.*[a-z])(?=.*[A-Z])(?=.*\d)(?=.*[^A-Za-z\d]).{8,64}$',
  );

  String? validateEmailAddress(String? value) {
    if (value == null || value.isEmpty) {
      return 'Veuillez entrer votre adresse e-mail';
    }

    if (!emailRegex.hasMatch(value)) {
      return 'Veuillez entrer une adresse e-mail valide';
    }
    return null;
  }

  String? validatePassword(String? value) {
    if (value == null || value.isEmpty) {
      return 'Veuillez entrer votre mot de passe';
    }

    if (!(8 <= value.length && value.length <= 64)) {
      return 'Votre mot de passe doit comporter entre 8 et 64 caractères';
    }

    if (!pwdRegex.hasMatch(value)) {
      return 'Votre mot de passe doit contenir au moins une lettre minuscule, une lettre majuscule et un caractère spécial';
    }
    return null;
  }

  String? validateConfirmPassword(
    String? value,
    TextEditingController pwdController,
  ) {
    if (value == null || value.isEmpty) {
      return 'Veuillez confirmer votre mot de passe';
    }

    if (value != pwdController.text) {
      return 'Les mots de passe ne correspondent pas';
    }
    return null;
  }

  String? noValidation(String? value) {
    return null;
  }
}
