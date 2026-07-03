import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:mangatracker/core/notifier/notifier.dart';
import 'package:mangatracker/core/service_locator/service_locator.dart';
import 'package:mangatracker/core/theme/app_spacing.dart';
import 'package:mangatracker/features/auth/presentation/cubit/auth_submission_status.dart';
import 'package:mangatracker/features/auth/presentation/cubit/login_cubit.dart';
import 'package:mangatracker/features/auth/presentation/cubit/login_state.dart';
import 'package:mangatracker/features/auth/services/auth.service.dart';
import 'package:mangatracker/features/auth/services/validator.service.dart';
import 'package:mangatracker/features/auth/widgets/auth_divider_with_label.dart';
import 'package:mangatracker/features/auth/widgets/auth_footer_link.dart';
import 'package:mangatracker/features/auth/widgets/auth_form_card.dart';
import 'package:mangatracker/features/auth/widgets/auth_form_field.dart';
import 'package:mangatracker/features/auth/widgets/auth_hero.dart';
import 'package:mangatracker/features/auth/widgets/auth_password_field.dart';
import 'package:mangatracker/features/auth/widgets/auth_scaffold.dart';
import 'package:mangatracker/features/auth/widgets/auth_submit_button.dart';
import 'package:mangatracker/features/auth/widgets/auth_top_bar.dart';
import 'package:mangatracker/features/auth/widgets/biometric_login_button.dart';
import 'package:mangatracker/features/auth/widgets/social_login_buttons.dart';
import 'package:mangatracker/l10n/app_localizations.dart';

/// Page de connexion — design V1 « Refined Classic ».
///
/// Préserve l'intégralité des comportements :
/// - `LoginCubit` avec submit / requiresBiometricPrompt
/// - `ValidatorService` pour validation email
/// - Activation biométrique au premier login réussi (dialog)
/// - Google OAuth (mobile + web idToken/WebView via `AuthService`)
/// - Biometric login si activé
/// - Navigation vers `/register` et `/forgot-password`
class LoginView extends StatefulWidget {
  const LoginView({super.key});

  @override
  State<LoginView> createState() => _LoginViewState();
}

class _LoginViewState extends State<LoginView> {
  late final GlobalKey<FormState> _formKey;
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  late final LoginCubit _loginCubit;
  final AuthService _authService = getIt<AuthService>();
  final ValidatorService _validatorService = getIt<ValidatorService>();
  final Notifier _notifier = Notifier();

  @override
  void initState() {
    super.initState();
    _formKey = GlobalKey<FormState>();
    _loginCubit = LoginCubit(authService: _authService);
  }

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    _loginCubit.close();
    super.dispose();
  }

  Future<void> _onSubmit() async {
    FocusManager.instance.primaryFocus?.unfocus();
    if (!_formKey.currentState!.validate()) return;
    if (!mounted) return;
    final l10n = AppLocalizations.of(context);
    await _loginCubit.submit(
      _emailController.text.toLowerCase(),
      _passwordController.text,
      l10n,
    );
  }

  Future<bool?> _showBiometricActivationDialog(AppLocalizations? l10n) async {
    if (!mounted) return false;
    return showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => AlertDialog(
        title: Text(
          l10n?.biometricAuthFirstTimeTitle ??
              "Activer l'authentification biométrique ?",
        ),
        content: Text(
          l10n?.biometricAuthFirstTimeMessage ??
              "Souhaitez-vous utiliser votre empreinte digitale ou Face ID pour vous connecter rapidement à l'avenir ?",
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: Text(l10n?.cancel ?? 'Annuler'),
          ),
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(true),
            child: Text(l10n?.save ?? 'Activer'),
          ),
        ],
      ),
    );
  }

  void _goToRegister() {
    final email = _emailController.text;
    final encoded = Uri.encodeQueryComponent(email);
    context.push('/register?email=$encoded');
  }

  Future<void> _onBiometricLogin() async {
    final success = await _authService.tryBiometricLogin(context);
    if (!mounted) return;
    if (success) {
      context.go('/home');
    } else {
      final l10n = AppLocalizations.of(context);
      _notifier.error(
        l10n?.biometricAuthFailed ??
            "Echec de l'authentification biométrique",
      );
    }
  }

  Future<void> _onGoogleLogin(AppLocalizations? l10n) async {
    final result = await _authService.loginWithGoogle(context);
    if (!mounted) return;
    switch (result) {
      case GoogleLoginResult.success:
        context.go('/home');
      case GoogleLoginResult.cancelled:
        break; // fermeture volontaire du sélecteur — pas un échec
      case GoogleLoginResult.configError:
        _notifier.error(
          l10n?.googleLoginConfigError ??
              "Connexion Google indisponible (erreur de configuration de l'app)",
        );
      case GoogleLoginResult.failed:
        _notifier.error(
          l10n?.googleLoginFailed ?? 'Échec de la connexion Google',
        );
    }
  }

  void _onAppleLogin(AppLocalizations? l10n) {
    _notifier.info(l10n?.comingSoon ?? 'Fonctionnalité à venir');
  }

  @override
  Widget build(BuildContext context) {
    return BlocProvider<LoginCubit>.value(
      value: _loginCubit,
      child: BlocListener<LoginCubit, LoginState>(
        listenWhen: (prev, curr) =>
            prev.status != curr.status ||
            prev.requiresBiometricPrompt != curr.requiresBiometricPrompt,
        listener: (context, state) async {
          if (state.status == AuthSubmissionStatus.success) {
            final l10n = AppLocalizations.of(context);
            if (state.requiresBiometricPrompt) {
              final choice = await _showBiometricActivationDialog(l10n);
              await _loginCubit.completeBiometricPrompt(choice ?? false);
              return;
            }
            if (!context.mounted) return;
            // Signale aux gestionnaires de mots de passe que le formulaire
            // est validé → propose d'enregistrer/mettre à jour les
            // identifiants (hotfix-v0-10-1 US-1, fonctionne avec
            // AutofillGroup ci-dessous).
            TextInput.finishAutofillContext();
            context.go('/home');
            _loginCubit.reset();
          }
        },
        child: AuthScaffold(
          canPop: false,
          child: Form(
            key: _formKey,
            // AutofillGroup : sans lui, les autofillHints des champs sont
            // ignorés par Chrome/gestionnaires Android — le formulaire doit
            // être agrégé pour que l'autofill email+password fonctionne.
            child: AutofillGroup(
              child: _LoginContent(
                emailController: _emailController,
                passwordController: _passwordController,
                validatorService: _validatorService,
                onSubmit: _onSubmit,
                onRegister: _goToRegister,
                onForgotPassword: () => context.push('/forgot-password'),
                onBiometric: _onBiometricLogin,
                onGoogle: _onGoogleLogin,
                onApple: _onAppleLogin,
                authService: _authService,
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// Contenu de la page de connexion — extrait pour rester sous 150 lignes.
class _LoginContent extends StatelessWidget {
  final TextEditingController emailController;
  final TextEditingController passwordController;
  final ValidatorService validatorService;
  final Future<void> Function() onSubmit;
  final VoidCallback onRegister;
  final VoidCallback onForgotPassword;
  final Future<void> Function() onBiometric;
  final Future<void> Function(AppLocalizations?) onGoogle;
  final void Function(AppLocalizations?) onApple;
  final AuthService authService;

  const _LoginContent({
    required this.emailController,
    required this.passwordController,
    required this.validatorService,
    required this.onSubmit,
    required this.onRegister,
    required this.onForgotPassword,
    required this.onBiometric,
    required this.onGoogle,
    required this.onApple,
    required this.authService,
  });

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final state = context.watch<LoginCubit>().state;
    final scheme = Theme.of(context).colorScheme;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      mainAxisSize: MainAxisSize.min,
      children: [
        const AuthTopBar(),
        const SizedBox(height: AppSpacing.s),
        AuthHero(
          title: l10n?.welcomeTitle ?? 'Bienvenue !',
          subtitle: l10n?.loginSubtitle ?? 'Connectez-vous à votre compte',
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
              textInputAction: TextInputAction.next,
              validator: (v) =>
                  validatorService.validateEmailAddress(v, context),
            ),
            AuthPasswordField(
              label: l10n?.password ?? 'Mot de passe',
              controller: passwordController,
              validator: validatorService.noValidation,
              textInputAction: TextInputAction.done,
              onSubmitted: onSubmit,
            ),
          ],
        ),
        const SizedBox(height: AppSpacing.s),
        Align(
          alignment: Alignment.centerRight,
          child: TextButton(
            onPressed: onForgotPassword,
            style: TextButton.styleFrom(
              foregroundColor: scheme.primary,
              textStyle: const TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w600,
              ),
            ),
            child: Text(l10n?.forgotPassword ?? 'Mot de passe oublié ?'),
          ),
        ),
        const SizedBox(height: AppSpacing.m),
        AuthSubmitButton(
          text: l10n?.login ?? 'Se connecter',
          onPressed: state.isLoading ? null : onSubmit,
          isLoading: state.isLoading,
        ),
        if (state.errorMessage != null) ...[
          const SizedBox(height: AppSpacing.s),
          Text(
            state.errorMessage!,
            textAlign: TextAlign.center,
            style: TextStyle(
              color: scheme.error,
              fontSize: 13,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
        FutureBuilder<bool>(
          future: authService.isBiometricEnabled(),
          builder: (context, snapshot) {
            if (snapshot.hasData && snapshot.data == true) {
              return Padding(
                padding: const EdgeInsets.only(top: AppSpacing.m),
                child: BiometricLoginButton(
                  label: l10n?.biometricAuth ?? 'Connexion biométrique',
                  onTap: onBiometric,
                ),
              );
            }
            return const SizedBox.shrink();
          },
        ),
        const SizedBox(height: AppSpacing.xl),
        AuthDividerWithLabel(label: l10n?.orLoginWith ?? 'ou se connecter avec'),
        const SizedBox(height: AppSpacing.l),
        SocialLoginButtons(
          googleLabel: l10n?.loginWithGoogle ?? 'Se connecter avec Google',
          appleLabel: l10n?.continueWithApple ?? 'Continuer avec Apple',
          onGoogle: state.isLoading ? null : () => onGoogle(l10n),
          onApple: () => onApple(l10n),
          disabled: state.isLoading,
        ),
        const SizedBox(height: AppSpacing.xl),
        AuthFooterLink(
          message: l10n?.noAccount ?? "Vous n'avez pas de compte ?",
          actionLabel: l10n?.signUp ?? "S'inscrire",
          onTap: onRegister,
        ),
        const SizedBox(height: AppSpacing.s),
      ],
    );
  }
}
