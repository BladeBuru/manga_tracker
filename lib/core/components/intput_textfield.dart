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
    final colorScheme = Theme.of(context).colorScheme;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    // Tokens du thème pour rester lisible en light & dark.
    final fillColor = isDark
        ? colorScheme.surfaceContainerHigh
        : colorScheme.surfaceContainerLow;
    final textColor = colorScheme.onSurface;
    final hintColor = colorScheme.onSurfaceVariant;
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
        style: TextStyle(color: textColor),
        decoration: InputDecoration(
          hintText: hintText,
          hintStyle: TextStyle(color: hintColor),
          labelText: labelText,
          labelStyle: TextStyle(color: hintColor),
          helperText: helperText,
          helperStyle: TextStyle(color: hintColor),
          filled: true,
          fillColor: fillColor,
          prefixIcon: prefixIcon,
          suffixIcon: suffixIcon,
          errorMaxLines: 3,
        enabledBorder: OutlineInputBorder(
          borderSide: BorderSide(color: colorScheme.outlineVariant),
          borderRadius: AppRadius.circularXxl,
        ),
        focusedBorder: OutlineInputBorder(
          borderSide: BorderSide(color: colorScheme.primary),
          borderRadius: AppRadius.circularXxl,
        ),
        errorBorder: OutlineInputBorder(
          borderSide: BorderSide(color: colorScheme.error),
          borderRadius: AppRadius.circularXxl,
        ),
        focusedErrorBorder: OutlineInputBorder(
          borderSide: BorderSide(color: colorScheme.error),
          borderRadius: AppRadius.circularXxl,
        ),
        ),
        validator: validator,
        onChanged: onChanged,
      ),
    );
  }
}
