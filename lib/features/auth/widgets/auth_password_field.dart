import 'package:flutter/material.dart';
import 'package:mangatracker/core/theme/app_colors.dart';
import 'package:mangatracker/features/auth/widgets/auth_form_field.dart';
import 'package:mangatracker/l10n/app_localizations.dart';

/// Champ mot de passe V1 — wrappe [AuthFormField] avec un icône eye
/// (afficher/masquer + long-press momentané).
class AuthPasswordField extends StatefulWidget {
  final String label;
  final TextEditingController controller;
  final String? Function(String?)? validator;
  final TextInputAction textInputAction;
  final VoidCallback? onSubmitted;
  final void Function(String)? onChanged;
  final FocusNode? focusNode;
  final List<String> autofillHints;

  const AuthPasswordField({
    super.key,
    required this.label,
    required this.controller,
    this.validator,
    this.textInputAction = TextInputAction.done,
    this.onSubmitted,
    this.onChanged,
    this.focusNode,
    this.autofillHints = const [AutofillHints.password],
  });

  @override
  State<AuthPasswordField> createState() => _AuthPasswordFieldState();
}

class _AuthPasswordFieldState extends State<AuthPasswordField> {
  bool _obscure = true;

  void _toggle() {
    setState(() => _obscure = !_obscure);
  }

  void _showWhileHeld(bool show) {
    if (mounted) setState(() => _obscure = !show);
  }

  @override
  Widget build(BuildContext context) {
    final brightness = Theme.of(context).brightness;
    final l10n = AppLocalizations.of(context);
    final iconColor = AppColors.dsText3(brightness);
    return AuthFormField(
      label: widget.label,
      controller: widget.controller,
      obscureText: _obscure,
      keyboardType: TextInputType.visiblePassword,
      autofillHints: widget.autofillHints,
      textInputAction: widget.textInputAction,
      validator: widget.validator,
      onSubmitted: widget.onSubmitted,
      onChanged: widget.onChanged,
      focusNode: widget.focusNode,
      suffixIcon: Semantics(
        button: true,
        label: _obscure
            ? (l10n?.showPassword ?? 'Afficher le mot de passe')
            : (l10n?.hidePassword ?? 'Masquer le mot de passe'),
        child: GestureDetector(
          onLongPressStart: (_) => _showWhileHeld(true),
          onLongPressEnd: (_) => _showWhileHeld(false),
          child: IconButton(
            visualDensity: VisualDensity.compact,
            padding: EdgeInsets.zero,
            constraints: const BoxConstraints(minWidth: 36, minHeight: 36),
            icon: Icon(
              _obscure
                  ? Icons.visibility_outlined
                  : Icons.visibility_off_outlined,
              color: iconColor,
              size: 20,
            ),
            onPressed: _toggle,
          ),
        ),
      ),
    );
  }
}
