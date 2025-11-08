import 'package:flutter/material.dart';
import 'package:mangatracker/l10n/app_localizations.dart';

import '../../features/auth/services/validator.service.dart';
import 'intput_textfield.dart';

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
  late final FocusNode _confirmFocusNode;
  bool _obscurePassword = true;
  bool _obscureConfirmPassword = true;
  double _passwordStrength = 0;
  String? _passwordStrengthLabel;
  Color _passwordStrengthColor = Colors.red;

  @override
  void initState() {
    super.initState();
    _confirmFocusNode = FocusNode();
    widget.passwordControler.addListener(_handlePasswordChange);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        _handlePasswordChange();
      }
    });
  }

  @override
  void dispose() {
    _confirmFocusNode.dispose();
    widget.passwordControler.removeListener(_handlePasswordChange);
    super.dispose();
  }

  void _handlePasswordChange() {
    final l10n = AppLocalizations.of(context);
    _updatePasswordStrength(widget.passwordControler.text, l10n);
  }

  void _updatePasswordStrength(String value, AppLocalizations? l10n) {
    final strength = _calculatePasswordStrength(value);
    String? label;
    Color color = Colors.red;

    if (value.isEmpty) {
      label = null;
      color = Colors.grey[400]!;
    } else if (strength < 0.34) {
      label = l10n?.passwordStrengthWeak ?? 'Faible';
      color = Colors.red;
    } else if (strength < 0.67) {
      label = l10n?.passwordStrengthMedium ?? 'Moyen';
      color = Colors.orange;
    } else {
      label = l10n?.passwordStrengthStrong ?? 'Fort';
      color = Colors.green;
    }

    if (!mounted) return;

    setState(() {
      _passwordStrength = strength;
      _passwordStrengthLabel = label;
      _passwordStrengthColor = color;
    });
  }

  double _calculatePasswordStrength(String value) {
    if (value.isEmpty) return 0;

    double strength = 0;
    if (value.length >= 8) strength += 0.25;
    if (value.length >= 12) strength += 0.15;
    if (RegExp(r'[a-z]').hasMatch(value)) strength += 0.15;
    if (RegExp(r'[A-Z]').hasMatch(value)) strength += 0.15;
    if (RegExp(r'\d').hasMatch(value)) strength += 0.15;
    if (RegExp(r'[^A-Za-z0-9]').hasMatch(value)) strength += 0.15;

    return strength.clamp(0, 1);
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    
    return Column(
      children: [
        IntputTexteField(
          controller: widget.passwordControler,
          hintText: widget.update 
              ? (l10n?.newPassword ?? 'Nouveau mot de passe')
              : (l10n?.password ?? 'Mot de passe'),
          labelText: widget.update 
              ? (l10n?.newPassword ?? 'Nouveau mot de passe')
              : (l10n?.password ?? 'Mot de passe'),
          obscureText: _obscurePassword,
          keyboardType: TextInputType.visiblePassword,
          validator: (value) => widget.validatorService.validatePassword(value, context),
          autofillHints: widget.update 
              ? const [AutofillHints.newPassword]
              : const [AutofillHints.password],
          textInputAction: TextInputAction.next,
          onSubmitted: () {
            _confirmFocusNode.requestFocus();
          },
          onChanged: (value) => _updatePasswordStrength(value, l10n),
          suffixIcon: Semantics(
            button: true,
            label: _obscurePassword
                ? (l10n?.showPassword ?? 'Afficher le mot de passe')
                : (l10n?.hidePassword ?? 'Masquer le mot de passe'),
            child: GestureDetector(
              onLongPressStart: (_) {
                setState(() {
                  _obscurePassword = false;
                });
              },
              onLongPressEnd: (_) {
                setState(() {
                  _obscurePassword = true;
                });
              },
              child: IconButton(
                icon: Icon(
                  _obscurePassword ? Icons.visibility_outlined : Icons.visibility_off_outlined,
                  color: Colors.grey[600],
                ),
                onPressed: () {
                  setState(() {
                    _obscurePassword = !_obscurePassword;
                  });
                },
              ),
            ),
          ),
        ),

        const SizedBox(height: 15),

        if (_passwordStrengthLabel != null) ...[
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 30.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Semantics(
                  label:
                      '${l10n?.passwordStrengthLabel ?? 'Robustesse du mot de passe'} : $_passwordStrengthLabel',
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(6),
                    child: LinearProgressIndicator(
                      value: _passwordStrength,
                      minHeight: 6,
                      valueColor: AlwaysStoppedAnimation<Color>(_passwordStrengthColor),
                      backgroundColor: Colors.grey[200],
                    ),
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  _passwordStrengthLabel!,
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: _passwordStrengthColor,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 15),
        ],

        IntputTexteField(
          controller: widget.confirmPasswordControler,
          hintText: l10n?.confirmPassword ?? 'Confirmation',
          labelText: l10n?.confirmPassword ?? 'Confirmation',
          obscureText: _obscureConfirmPassword,
          keyboardType: TextInputType.visiblePassword,
          validator: (value) {
            return widget.validatorService.validateConfirmPassword(
              value,
              widget.passwordControler,
              context,
            );
          },
          autofillHints: widget.update 
              ? const [AutofillHints.newPassword]
              : const [AutofillHints.password],
          textInputAction: TextInputAction.done,
          focusNode: _confirmFocusNode,
          suffixIcon: Semantics(
            button: true,
            label: _obscureConfirmPassword
                ? (l10n?.showPassword ?? 'Afficher le mot de passe')
                : (l10n?.hidePassword ?? 'Masquer le mot de passe'),
            child: GestureDetector(
              onLongPressStart: (_) {
                setState(() {
                  _obscureConfirmPassword = false;
                });
              },
              onLongPressEnd: (_) {
                setState(() {
                  _obscureConfirmPassword = true;
                });
              },
              child: IconButton(
                icon: Icon(
                  _obscureConfirmPassword
                      ? Icons.visibility_outlined
                      : Icons.visibility_off_outlined,
                  color: Colors.grey[600],
                ),
                onPressed: () {
                  setState(() {
                    _obscureConfirmPassword = !_obscureConfirmPassword;
                  });
                },
              ),
            ),
          ),
        ),
      ],
    );
  }
}
