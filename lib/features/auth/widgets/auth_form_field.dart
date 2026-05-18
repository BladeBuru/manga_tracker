import 'package:flutter/material.dart';
import 'package:mangatracker/core/theme/app_colors.dart';

/// Champ de formulaire d'auth aligné sur le design V1 « Refined Classic ».
///
/// Reproduit `ProfileEditField` : label uppercase tracké en haut, plain
/// `TextFormField` sans bordure, bg `dsBgInset` quand focused, barre
/// verticale rouge 3px à gauche quand focused.
///
/// Conçu pour être empilé dans une [AuthFormCard] avec des `Divider`
/// hairline entre chaque champ.
class AuthFormField extends StatefulWidget {
  final String label;
  final TextEditingController controller;
  final String? hintText;
  final bool obscureText;
  final String? Function(String?)? validator;
  final TextInputType keyboardType;
  final Iterable<String>? autofillHints;
  final TextInputAction? textInputAction;
  final FocusNode? focusNode;
  final void Function()? onSubmitted;
  final void Function(String)? onChanged;
  final Widget? suffixIcon;
  final bool autovalidate;

  const AuthFormField({
    super.key,
    required this.label,
    required this.controller,
    this.hintText,
    this.obscureText = false,
    this.validator,
    this.keyboardType = TextInputType.text,
    this.autofillHints,
    this.textInputAction,
    this.focusNode,
    this.onSubmitted,
    this.onChanged,
    this.suffixIcon,
    this.autovalidate = false,
  });

  @override
  State<AuthFormField> createState() => _AuthFormFieldState();
}

class _AuthFormFieldState extends State<AuthFormField> {
  late final FocusNode _focusNode;
  bool _ownsFocusNode = false;

  @override
  void initState() {
    super.initState();
    if (widget.focusNode != null) {
      _focusNode = widget.focusNode!;
    } else {
      _focusNode = FocusNode();
      _ownsFocusNode = true;
    }
    _focusNode.addListener(_onFocusChange);
  }

  @override
  void dispose() {
    _focusNode.removeListener(_onFocusChange);
    if (_ownsFocusNode) {
      _focusNode.dispose();
    }
    super.dispose();
  }

  void _onFocusChange() {
    if (mounted) setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    final brightness = Theme.of(context).brightness;
    final scheme = Theme.of(context).colorScheme;
    final focused = _focusNode.hasFocus;
    return Stack(
      children: [
        if (focused)
          Positioned(
            top: 6,
            bottom: 6,
            left: 0,
            child: Container(
              width: 3,
              decoration: BoxDecoration(
                color: scheme.primary,
                borderRadius: BorderRadius.circular(999),
              ),
            ),
          ),
        AnimatedContainer(
          duration: const Duration(milliseconds: 150),
          color: focused ? AppColors.dsBgInset(brightness) : Colors.transparent,
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 12),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                widget.label.toUpperCase(),
                style: TextStyle(
                  fontSize: 10.5,
                  fontWeight: FontWeight.w600,
                  letterSpacing: 0.63,
                  color: AppColors.dsText3(brightness),
                ),
              ),
              const SizedBox(height: 6),
              Row(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  Expanded(
                    child: TextFormField(
                      controller: widget.controller,
                      focusNode: _focusNode,
                      obscureText: widget.obscureText,
                      keyboardType: widget.keyboardType,
                      autofillHints: widget.autofillHints,
                      textInputAction: widget.textInputAction,
                      validator: widget.validator,
                      onChanged: widget.onChanged,
                      onFieldSubmitted: widget.onSubmitted != null
                          ? (_) => widget.onSubmitted!()
                          : null,
                      autovalidateMode: widget.autovalidate
                          ? AutovalidateMode.onUserInteraction
                          : AutovalidateMode.disabled,
                      style: TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w500,
                        letterSpacing: -0.075,
                        color: scheme.onSurface,
                      ),
                      decoration: InputDecoration(
                        hintText: widget.hintText,
                        hintStyle: TextStyle(
                          color: AppColors.dsText3(brightness),
                          fontWeight: FontWeight.w500,
                        ),
                        border: InputBorder.none,
                        enabledBorder: InputBorder.none,
                        focusedBorder: InputBorder.none,
                        errorBorder: InputBorder.none,
                        focusedErrorBorder: InputBorder.none,
                        contentPadding: EdgeInsets.zero,
                        isDense: true,
                        errorMaxLines: 3,
                        errorStyle: TextStyle(
                          color: scheme.error,
                          fontSize: 12,
                        ),
                      ),
                    ),
                  ),
                  if (widget.suffixIcon != null) widget.suffixIcon!,
                ],
              ),
            ],
          ),
        ),
      ],
    );
  }
}
