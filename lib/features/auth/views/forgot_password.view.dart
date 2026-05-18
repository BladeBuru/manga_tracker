import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:mangatracker/core/service_locator/service_locator.dart';
import 'package:mangatracker/core/theme/app_colors.dart';
import 'package:mangatracker/core/theme/app_spacing.dart';
import 'package:mangatracker/features/auth/presentation/cubit/forgot_password_cubit.dart';
import 'package:mangatracker/features/auth/services/email_auth.service.dart';
import 'package:mangatracker/features/auth/services/validator.service.dart';
import 'package:mangatracker/features/auth/widgets/auth_form_card.dart';
import 'package:mangatracker/features/auth/widgets/auth_form_field.dart';
import 'package:mangatracker/features/auth/widgets/auth_hero.dart';
import 'package:mangatracker/features/auth/widgets/auth_scaffold.dart';
import 'package:mangatracker/features/auth/widgets/auth_submit_button.dart';
import 'package:mangatracker/features/auth/widgets/auth_top_bar.dart';
import 'package:mangatracker/l10n/app_localizations.dart';

/// Vue « Mot de passe oublié » — design V1.
///
/// Anti-énumération : après soumission, l'écran affiche TOUJOURS le même
/// message de succès (« Si un compte existe pour cet email… »).
class ForgotPasswordView extends StatefulWidget {
  const ForgotPasswordView({super.key});

  @override
  State<ForgotPasswordView> createState() => _ForgotPasswordViewState();
}

class _ForgotPasswordViewState extends State<ForgotPasswordView> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  late final ForgotPasswordCubit _cubit;
  late final ValidatorService _validator;

  @override
  void initState() {
    super.initState();
    _cubit = ForgotPasswordCubit(service: getIt<EmailAuthService>());
    _validator = getIt<ValidatorService>();
  }

  @override
  void dispose() {
    _cubit.close();
    _emailController.dispose();
    super.dispose();
  }

  void _submit() {
    if (!_formKey.currentState!.validate()) return;
    FocusManager.instance.primaryFocus?.unfocus();
    _cubit.submit(_emailController.text);
  }

  @override
  Widget build(BuildContext context) {
    return AuthScaffold(
      child: BlocProvider<ForgotPasswordCubit>.value(
        value: _cubit,
        child: BlocBuilder<ForgotPasswordCubit, ForgotPasswordState>(
          builder: (context, state) {
            final l10n = AppLocalizations.of(context);
            if (state.isSuccess) {
              return _ForgotPasswordSuccess(
                email: state.submittedEmail,
                onBack: () => Navigator.of(context).pop(),
              );
            }
            return Form(
              key: _formKey,
              child: _ForgotPasswordForm(
                state: state,
                emailController: _emailController,
                onSubmit: _submit,
                validator: (v) => _validator.validateEmailAddress(v, context),
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

class _ForgotPasswordForm extends StatelessWidget {
  final ForgotPasswordState state;
  final TextEditingController emailController;
  final VoidCallback onSubmit;
  final String? Function(String?) validator;
  final VoidCallback onBack;
  final AppLocalizations? l10n;

  const _ForgotPasswordForm({
    required this.state,
    required this.emailController,
    required this.onSubmit,
    required this.validator,
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
        AuthTopBar(
          onBack: onBack,
          backTooltip: l10n?.back ?? 'Retour',
        ),
        const SizedBox(height: AppSpacing.s),
        AuthHero(
          title: l10n?.forgotPasswordTitle ?? 'Mot de passe oublié',
          subtitle: l10n?.forgotPasswordIntro,
          logoSemanticLabel: l10n?.appTitle ?? 'MangaTracker',
        ),
        const SizedBox(height: AppSpacing.xl),
        AuthFormCard(
          children: [
            AuthFormField(
              label: l10n?.emailAddress ?? 'Adresse e-mail',
              controller: emailController,
              hintText: 'vous@example.com',
              keyboardType: TextInputType.emailAddress,
              autofillHints: const [AutofillHints.email],
              textInputAction: TextInputAction.done,
              validator: validator,
              onSubmitted: onSubmit,
            ),
          ],
        ),
        const SizedBox(height: AppSpacing.l),
        AuthSubmitButton(
          text: l10n?.sendResetLink ?? 'Envoyer le lien',
          onPressed: state.isLoading ? null : onSubmit,
          isLoading: state.isLoading,
        ),
        if (state.errorMessage != null && !state.isSuccess) ...[
          const SizedBox(height: AppSpacing.s),
          Text(
            l10n?.networkError ??
                'Erreur réseau. Réessayez plus tard.',
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

class _ForgotPasswordSuccess extends StatelessWidget {
  final String email;
  final VoidCallback onBack;

  const _ForgotPasswordSuccess({required this.email, required this.onBack});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final brightness = Theme.of(context).brightness;
    final scheme = Theme.of(context).colorScheme;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        AuthTopBar(onBack: onBack, backTooltip: l10n?.back ?? 'Retour'),
        const SizedBox(height: AppSpacing.s),
        Center(
          child: Container(
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
              Icons.mark_email_read_outlined,
              size: 40,
              color: scheme.primary,
            ),
          ),
        ),
        const SizedBox(height: AppSpacing.l),
        Text(
          l10n?.resetEmailSentTitle ?? 'Vérifiez votre boîte mail',
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
          l10n?.resetEmailSentMessage(email) ?? '',
          textAlign: TextAlign.center,
          style: TextStyle(
            fontSize: 14,
            color: AppColors.dsText2(brightness),
            height: 1.5,
          ),
        ),
        const SizedBox(height: AppSpacing.xl),
        OutlinedButton(
          onPressed: onBack,
          style: OutlinedButton.styleFrom(
            minimumSize: const Size.fromHeight(48),
            side: BorderSide(color: AppColors.dsBorder(brightness)),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(14),
            ),
            foregroundColor: scheme.onSurface,
          ),
          child: Text(l10n?.back ?? 'Retour'),
        ),
      ],
    );
  }
}
