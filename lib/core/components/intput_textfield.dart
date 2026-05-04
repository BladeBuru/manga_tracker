import 'package:flutter/material.dart';
import 'package:mangatracker/core/theme/app_radius.dart';

class IntputTexteField extends StatelessWidget {
  final TextEditingController controller;
  final String hintText;
  final bool obscureText;
  final String? Function(String?)? validator;
  final TextInputType keyboardType;
  final Widget? prefixIcon;
  final void Function(String)? onChanged;
  final Iterable<String>? autofillHints;
  final TextInputAction? textInputAction;
  final FocusNode? focusNode;
  final void Function()? onSubmitted;
  final Widget? suffixIcon;
  final String? labelText;
  final String? helperText;

  const IntputTexteField({
    super.key,
    required this.controller,
    required this.hintText,
    this.obscureText = false,
    this.validator,
    this.keyboardType = TextInputType.text,
    this.prefixIcon,
    this.onChanged,
    this.autofillHints,
    this.textInputAction,
    this.focusNode,
    this.onSubmitted,
    this.suffixIcon,
    this.labelText,
    this.helperText,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 30.0),
      child: TextFormField(
        controller: controller,
        obscureText: obscureText,
        keyboardType: keyboardType,
        autofillHints: autofillHints,
        textInputAction: textInputAction,
        focusNode: focusNode,
        onFieldSubmitted: onSubmitted != null ? (_) => onSubmitted!() : null,
        // Couleur du texte saisi forcée en sombre car le fillColor est gris
        // clair fixe — sans cette ligne, en dark mode système, le texte
        // saisi prend la couleur blanche du theme et devient illisible.
        style: const TextStyle(color: Color(0xFF1A1A1A)),
        decoration: InputDecoration(
          hintText: hintText,
          hintStyle: TextStyle(color: Colors.grey[600]),
          labelText: labelText,
          labelStyle: TextStyle(color: Colors.grey[700]),
          helperText: helperText,
          helperStyle: TextStyle(color: Colors.grey[600]),
          filled: true,
          fillColor: Colors.grey[100],
          prefixIcon: prefixIcon,
          suffixIcon: suffixIcon,
          errorMaxLines: 3,
        enabledBorder: OutlineInputBorder(
          borderSide: const BorderSide(color: Colors.white),
          borderRadius: AppRadius.circularXxl,
        ),
        focusedBorder: OutlineInputBorder(
          borderSide: BorderSide(color: Colors.grey.shade400),
          borderRadius: AppRadius.circularXxl,
        ),
        errorBorder: OutlineInputBorder(
          borderSide: const BorderSide(color: Colors.red),
          borderRadius: AppRadius.circularXxl,
        ),
        focusedErrorBorder: OutlineInputBorder(
          borderSide: const BorderSide(color: Colors.red),
          borderRadius: AppRadius.circularXxl,
        ),
        ),
        validator: validator,
        onChanged: onChanged,
      ),
    );
  }
}
