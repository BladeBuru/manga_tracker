import 'package:flutter/material.dart';

class ValidatorService {
  final RegExp emailRegex =
      RegExp("^([a-zA-Z0-9_\\-\\.]+)@([a-zA-Z0-9_\\-\\.]+)\\.([a-zA-Z]{2,5})");
  final RegExp pwdRegex = RegExp(
      "^(?=.*[a-z])(?=.*[A-Z])(?=.*\\d)(?=.*[@\$!%*?&])[A-Za-z\\d@\$!%*?&]{8,64}");

  String? validateEmailAddress(String? value) {
    if (value == null || value.isEmpty) {
      return 'Please enter your email address';
    }

    if (!emailRegex.hasMatch(value)) {
      return 'Please enter a valid email address';
    }
    return null;
  }

  String? validatePassword(String? value) {
    if (value == null || value.isEmpty) {
      return 'Please enter your password';
    }

    if (!(8 <= value.length && value.length <= 64)) {
      return 'Your password must be between 8 and 64 characters';
    }

    if (!pwdRegex.hasMatch(value)) {
      return 'Your password must contain at least one lowercase letter, one uppercase letter and one special character';
    }
    return null;
  }

  String? validateConfirmPassword(
      String? value, TextEditingController pwdController) {
    if (value == null || value.isEmpty) {
      return 'Please confirm your password';
    }

    if (value != pwdController.text) {
      return 'Passwords do not match';
    }
    return null;
  }

  String? noValidation(String? value) {
    return null;
  }
}
