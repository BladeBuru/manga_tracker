import 'package:flutter/material.dart';
import 'package:mangatracker/features/auth/services/validator.service.dart';
import 'package:mangatracker/features/auth/widgets/auth_password_field.dart';
import 'package:mangatracker/features/auth/widgets/password_strength_indicator.dart';
import 'package:mangatracker/l10n/app_localizations.dart';

/// Bloc password V1 destiné à être inclus dans une [AuthFormCard].
///
/// Contient deux champs (mot de passe + confirmation), un indicateur de
/// force collé sous le premier champ, et utilise [AuthPasswordField] pour
/// le rendu cohérent V1.
///
/// Remplace fonctionnellement `core/components/password_fields.dart` dans
/// les vues d'auth V1, en conservant la validation via [ValidatorService].
class AuthPasswordSection extends StatefulWidget {
  final TextEditingController passwordController;
  final TextEditingController confirmController;
  final ValidatorService validatorService;
  final bool isUpdate;

  /// Overrides optionnels des labels (ex : « Confirmer le nouveau mot de
  /// passe » sur la page de changement de mot de passe). Si null, les
  /// labels par défaut (selon [isUpdate]) sont utilisés.
  final String? passwordLabel;
  final String? confirmLabel;

  const AuthPasswordSection({
    super.key,
    required this.passwordController,
    required this.confirmController,
    required this.validatorService,
    this.isUpdate = false,
    this.passwordLabel,
    this.confirmLabel,
  });

  @override
  State<AuthPasswordSection> createState() => _AuthPasswordSectionState();
}

class _AuthPasswordSectionState extends State<AuthPasswordSection> {
  late final FocusNode _confirmFocus;

  @override
  void initState() {
    super.initState();
    _confirmFocus = FocusNode();
    widget.passwordController.addListener(_onPasswordChange);
  }

  @override
  void dispose() {
    _confirmFocus.dispose();
    widget.passwordController.removeListener(_onPasswordChange);
    super.dispose();
  }

  void _onPasswordChange() {
    if (mounted) setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final passwordLabel = widget.passwordLabel ??
        (widget.isUpdate
            ? (l10n?.newPassword ?? 'Nouveau mot de passe')
            : (l10n?.password ?? 'Mot de passe'));
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        AuthPasswordField(
          label: passwordLabel,
          controller: widget.passwordController,
          validator: (v) =>
              widget.validatorService.validatePassword(v, context),
          textInputAction: TextInputAction.next,
          onSubmitted: () => _confirmFocus.requestFocus(),
          autofillHints: widget.isUpdate
              ? const [AutofillHints.newPassword]
              : const [AutofillHints.password],
        ),
        PasswordStrengthIndicator(value: widget.passwordController.text),
        // Petit séparateur visuel (le card parent gère le divider entre
        // sections — ici on est dans une sous-section interne).
        Container(
          height: 1,
          margin: const EdgeInsets.only(left: 16),
          color: Theme.of(context).dividerColor.withValues(alpha: 0.3),
        ),
        AuthPasswordField(
          label: widget.confirmLabel ?? l10n?.confirmPassword ?? 'Confirmation',
          controller: widget.confirmController,
          focusNode: _confirmFocus,
          validator: (v) => widget.validatorService.validateConfirmPassword(
            v,
            widget.passwordController,
            context,
          ),
          textInputAction: TextInputAction.done,
          autofillHints: widget.isUpdate
              ? const [AutofillHints.newPassword]
              : const [AutofillHints.password],
        ),
      ],
    );
  }
}
