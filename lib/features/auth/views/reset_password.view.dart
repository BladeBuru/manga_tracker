import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:mangatracker/core/service_locator/service_locator.dart';
import 'package:mangatracker/core/theme/app_colors.dart';
import 'package:mangatracker/core/theme/app_spacing.dart';
import 'package:mangatracker/features/auth/presentation/cubit/reset_password_cubit.dart';
import 'package:mangatracker/features/auth/services/auth.service.dart';
import 'package:mangatracker/features/auth/services/email_auth.service.dart';
import 'package:mangatracker/features/auth/services/validator.service.dart';
import 'package:mangatracker/features/auth/widgets/auth_form_card.dart';
import 'package:mangatracker/features/auth/widgets/auth_hero.dart';
import 'package:mangatracker/features/auth/widgets/auth_password_section.dart';
import 'package:mangatracker/features/auth/widgets/auth_scaffold.dart';
import 'package:mangatracker/features/auth/widgets/auth_submit_button.dart';
import 'package:mangatracker/features/auth/widgets/auth_top_bar.dart';
import 'package:mangatracker/l10n/app_localizations.dart';

/// Vue « Définir un nouveau mot de passe » — design V1.
///
/// Atteignable via deep link `https://bladeburu.com/auth/reset-password?token=XXX`.
/// Après succès l'utilisateur est auto-loggué (les JWT sont persistés via
/// `AuthService.persistTokens` dans le Cubit).
class ResetPasswordView extends StatefulWidget {
  final String token;

  const ResetPasswordView({super.key, required this.token});

  @override
  State<ResetPasswordView> createState() => _ResetPasswordViewState();
}

class _ResetPasswordViewState extends State<ResetPasswordView> {
  final _formKey = GlobalKey<FormState>();
  final _passwordController = TextEditingController();
  final _confirmController = TextEditingController();
  late final ResetPasswordCubit _cubit;
  late final ValidatorService _validator;

  @override
  void initState() {
    super.initState();
    _cubit = ResetPasswordCubit(
      emailAuth: getIt<EmailAuthService>(),
      authService: getIt<AuthService>(),
    );
    _validator = getIt<ValidatorService>();
  }

  @override
  void dispose() {
    _cubit.close();
    _passwordController.dispose();
    _confirmController.dispose();
    super.dispose();
  }

  void _submit() {
    if (!_formKey.currentState!.validate()) return;
    FocusManager.instance.primaryFocus?.unfocus();
    _cubit.submit(
      token: widget.token,
      newPassword: _passwordController.text,
    );
  }

  void _goHome() => context.go('/home');

  @override
  Widget build(BuildContext context) {
    return AuthScaffold(
      child: BlocProvider<ResetPasswordCubit>.value(
        value: _cubit,
        child: BlocConsumer<ResetPasswordCubit, ResetPasswordState>(
          listener: (context, state) {
            if (state.isSuccess) {
              Future.delayed(const Duration(milliseconds: 800), _goHome);
            }
          },
          builder: (context, state) {
            final l10n = AppLocalizations.of(context);
            if (state.isSuccess) return _ResetPasswordSuccess(l10n: l10n);
            return Form(
              key: _formKey,
              child: _ResetPasswordForm(
                state: state,
                passwordController: _passwordController,
                confirmController: _confirmController,
                validator: _validator,
                onSubmit: _submit,
                onBack: () => Navigator.of(context).pop(),
                l10n: l10n,
              ),
            );
          },
        ),
      ),
    );
  }
}

class _ResetPasswordForm extends StatelessWidget {
  final ResetPasswordState state;
  final TextEditingController passwordController;
  final TextEditingController confirmController;
  final ValidatorService validator;
  final VoidCallback onSubmit;
  final VoidCallback onBack;
  final AppLocalizations? l10n;

  const _ResetPasswordForm({
    required this.state,
    required this.passwordController,
    required this.confirmController,
    required this.validator,
    required this.onSubmit,
    required this.onBack,
    required this.l10n,
  });

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      mainAxisSize: MainAxisSize.min,
      children: [
        AuthTopBar(onBack: onBack, backTooltip: l10n?.back ?? 'Retour'),
        const SizedBox(height: AppSpacing.s),
        AuthHero(
          title: l10n?.resetPasswordTitle ?? 'Nouveau mot de passe',
          subtitle: l10n?.resetPasswordIntro,
          logoSemanticLabel: l10n?.appTitle ?? 'MangaTracker',
        ),
        const SizedBox(height: AppSpacing.xl),
        AuthFormCard(
          children: [
            AuthPasswordSection(
              passwordController: passwordController,
              confirmController: confirmController,
              validatorService: validator,
              isUpdate: true,
            ),
          ],
        ),
        const SizedBox(height: AppSpacing.l),
        AuthSubmitButton(
          text: l10n?.confirmReset ?? 'Confirmer',
          onPressed: state.isLoading ? null : onSubmit,
          isLoading: state.isLoading,
        ),
        if (state.errorMessage != null) ...[
          const SizedBox(height: AppSpacing.s),
          Text(
            state.tokenExpired
                ? (l10n?.resetTokenExpired ??
                    'Lien invalide ou expiré. Refaites une demande.')
                : (l10n?.networkError ??
                    'Erreur réseau. Réessayez plus tard.'),
            textAlign: TextAlign.center,
            style: TextStyle(
              color: scheme.error,
              fontSize: 13,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
        const SizedBox(height: AppSpacing.l),
      ],
    );
  }
}

class _ResetPasswordSuccess extends StatelessWidget {
  final AppLocalizations? l10n;

  const _ResetPasswordSuccess({required this.l10n});

  @override
  Widget build(BuildContext context) {
    final brightness = Theme.of(context).brightness;
    final scheme = Theme.of(context).colorScheme;
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        const SizedBox(height: AppSpacing.jumbo),
        Container(
          width: 80,
          height: 80,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: AppColors.dsRedSoft(brightness),
            border: Border.all(
              color: AppColors.dsHairline(brightness),
              width: 1,
            ),
          ),
          child: Icon(
            Icons.check_circle_outline,
            size: 40,
            color: scheme.primary,
          ),
        ),
        const SizedBox(height: AppSpacing.l),
        Text(
          l10n?.resetPasswordSuccess ?? 'Mot de passe modifié',
          textAlign: TextAlign.center,
          style: TextStyle(
            fontSize: 22,
            fontWeight: FontWeight.w800,
            letterSpacing: -0.5,
            color: scheme.onSurface,
          ),
        ),
        const SizedBox(height: AppSpacing.s),
        Text(
          l10n?.resetPasswordSuccessHint ??
              'Vous êtes maintenant connecté. Redirection en cours…',
          textAlign: TextAlign.center,
          style: TextStyle(
            fontSize: 14,
            color: AppColors.dsText2(brightness),
            height: 1.5,
          ),
        ),
      ],
    );
  }
}
