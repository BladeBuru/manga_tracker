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

  /// Nombre max de caractères affiché en compteur (`maxLength` natif).
  final int? maxLength;

  /// Nombre de lignes pour les champs multi-lignes (bio, description...).
  /// Défaut 1.
  final int? maxLines;

  /// Padding externe autour du `TextFormField`.
  ///
  /// Par défaut `EdgeInsets.symmetric(horizontal: 30)` — c'est le pattern
  /// des pages d'auth (login/register) où les champs sont en pleine
  /// largeur d'écran centrée. Quand utilisé **dans une `AppCard`** (page
  /// d'édition de profil, etc.) il faut passer `EdgeInsets.zero` pour
  /// éviter un double padding visuel.
  final EdgeInsetsGeometry padding;

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
    this.maxLength,
    this.maxLines = 1,
    this.padding = const EdgeInsets.symmetric(horizontal: 30.0),
  });

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    // **Refactor 2026-05-18** : `fillColor: surfaceContainerHighest` (au
    // lieu de `surfaceContainerLow`) → en light mode `Low` était quasi-
    // blanc, indistinguable du fond → seule la bordure outline noire
    // ressortait, look "form HTML 2018". `Highest` est gris moyen lisible
    // en light ET dark. La bordure outline est supprimée (`BorderSide.none`
    // en enabled/error), seul le focus garde un ring `primary 0.5` 2px.
    // Look Material 3 "filled chip input" moderne — Gmail, Tasks, Drive.
    final fillColor = colorScheme.surfaceContainerHighest;
    final textColor = colorScheme.onSurface;
    final hintColor = colorScheme.onSurfaceVariant;
    return Padding(
      padding: padding,
      child: TextFormField(
        controller: controller,
        obscureText: obscureText,
        keyboardType: keyboardType,
        autofillHints: autofillHints,
        textInputAction: textInputAction,
        focusNode: focusNode,
        maxLength: maxLength,
        maxLines: maxLines,
        onFieldSubmitted: onSubmitted != null ? (_) => onSubmitted!() : null,
        style: TextStyle(color: textColor),
        textAlignVertical: TextAlignVertical.top,
        decoration: InputDecoration(
          hintText: hintText,
          hintStyle: TextStyle(color: hintColor),
          labelText: labelText,
          labelStyle: TextStyle(color: hintColor),
          // Fix Material 3 multi-line : sans ça le label "Bio" flotte au
          // milieu vertical du champ multi-ligne au lieu de rester en
          // haut (UX vraiment moche pour une textarea).
          alignLabelWithHint: true,
          helperText: helperText,
          helperStyle: TextStyle(color: hintColor),
          filled: true,
          fillColor: fillColor,
          prefixIcon: prefixIcon,
          suffixIcon: suffixIcon,
          errorMaxLines: 3,
          enabledBorder: OutlineInputBorder(
            borderSide: BorderSide.none,
            borderRadius: AppRadius.circularXxl,
          ),
          focusedBorder: OutlineInputBorder(
            borderSide: BorderSide(
              color: colorScheme.primary.withValues(alpha: 0.6),
              width: 2,
            ),
            borderRadius: AppRadius.circularXxl,
          ),
          errorBorder: OutlineInputBorder(
            borderSide: BorderSide(color: colorScheme.error),
            borderRadius: AppRadius.circularXxl,
          ),
          focusedErrorBorder: OutlineInputBorder(
            borderSide: BorderSide(color: colorScheme.error, width: 2),
            borderRadius: AppRadius.circularXxl,
          ),
        ),
        validator: validator,
        onChanged: onChanged,
      ),
    );
  }
}
