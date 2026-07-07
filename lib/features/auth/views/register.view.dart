import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:mangatracker/core/notifier/notifier.dart';
import 'package:mangatracker/core/service_locator/service_locator.dart';
import 'package:mangatracker/core/theme/app_spacing.dart';
import 'package:mangatracker/features/auth/presentation/cubit/auth_submission_status.dart';
import 'package:mangatracker/features/auth/presentation/cubit/register_cubit.dart';
import 'package:mangatracker/features/auth/presentation/cubit/register_state.dart';
import 'package:mangatracker/features/auth/services/auth.service.dart';
import 'package:mangatracker/features/auth/services/validator.service.dart';
import 'package:mangatracker/features/auth/widgets/auth_divider_with_label.dart';
import 'package:mangatracker/features/auth/widgets/auth_footer_link.dart';
import 'package:mangatracker/features/auth/widgets/auth_form_card.dart';
import 'package:mangatracker/features/auth/widgets/auth_form_field.dart';
import 'package:mangatracker/features/auth/widgets/auth_hero.dart';
import 'package:mangatracker/features/auth/widgets/auth_password_section.dart';
import 'package:mangatracker/features/auth/widgets/auth_scaffold.dart';
import 'package:mangatracker/features/auth/widgets/auth_submit_button.dart';
import 'package:mangatracker/features/auth/widgets/auth_top_bar.dart';
import 'package:mangatracker/features/auth/widgets/consent_checkbox.dart';
import 'package:mangatracker/features/auth/widgets/social_login_buttons.dart';
import 'package:mangatracker/features/profile/services/gdpr.service.dart';
import 'package:mangatracker/l10n/app_localizations.dart';

/// Page d'inscription — design V1 « Refined Classic ».
///
/// Préserve l'intégralité des comportements :
/// - `RegisterCubit` : submit + setAcceptedTos / setAcceptedPrivacy
/// - Validation email / mot de passe / confirmation via `ValidatorService`
/// - GDPR consent obligatoire (les deux checkboxes bloquent submit)
/// - `GdprService.recordConsent` après succès (via Cubit)
/// - Google OAuth (mobile + web idToken/WebView via `AuthService`)
/// - Navigation vers `/login` et `/home`
class RegisterView extends StatefulWidget {
  final String emailText;

  const RegisterView({super.key, required this.emailText});

  @override
  State<RegisterView> createState() => _RegisterViewState();
}

class _RegisterViewState extends State<RegisterView> {
  late final GlobalKey<FormState> _formKey;
  final AuthService _authService = getIt<AuthService>();
  final ValidatorService _validatorService = getIt<ValidatorService>();
  final _emailController = TextEditingController();
  final _usernameController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();
  late final RegisterCubit _registerCubit;

  @override
  void initState() {
    super.initState();
    _formKey = GlobalKey<FormState>();
    _emailController.text = widget.emailText;
    _registerCubit = RegisterCubit(
      authService: _authService,
      gdprService: getIt<GdprService>(),
    );
  }

  @override
  void dispose() {
    _emailController.dispose();
    _usernameController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    _registerCubit.close();
    super.dispose();
  }

  Future<void> _onSubmit() async {
    FocusManager.instance.primaryFocus?.unfocus();
    if (!_formKey.currentState!.validate()) return;
    if (!mounted) return;
    final l10n = AppLocalizations.of(context);
    await _registerCubit.submit(
      username: _usernameController.text.trim().toLowerCase(),
      email: _emailController.text.trim(),
      password: _passwordController.text,
      l10n: l10n,
    );
  }

  void _goToLogin() => context.push('/login');

  void _onConsentRefused(AppLocalizations? l10n) {
    final theme = Theme.of(context);
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          l10n?.consentRequired ??
              'Vous devez accepter les CGU et la Politique de confidentialité.',
          style: TextStyle(color: theme.colorScheme.onTertiaryContainer),
        ),
        backgroundColor: theme.colorScheme.tertiaryContainer,
      ),
    );
  }

  void _showLegalDoc(String kind, AppLocalizations? l10n) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(
          kind == 'tos'
              ? (l10n?.termsOfServiceTitle ?? "Conditions d'utilisation")
              : (l10n?.privacyPolicyTitle ?? 'Politique de confidentialité'),
        ),
        content: SingleChildScrollView(
          child: Text(
            kind == 'tos'
                ? (l10n?.tosShortVersion ?? '')
                : (l10n?.privacyShortVersion ?? ''),
            style: const TextStyle(fontSize: 13),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: Text(l10n?.close ?? 'Fermer'),
          ),
        ],
      ),
    );
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
        getIt<Notifier>().error(
          l10n?.googleLoginConfigError ??
              "Connexion Google indisponible (erreur de configuration de l'app)",
        );
      case GoogleLoginResult.popupBlocked:
        getIt<Notifier>().error(
          l10n?.googlePopupBlocked ??
              'Fenêtre bloquée par le navigateur — autorisez les pop-ups pour ce site',
        );
      case GoogleLoginResult.failed:
        getIt<Notifier>().error(
          l10n?.googleLoginFailed ?? 'Échec de la connexion Google',
        );
    }
  }

  void _onAppleLogin(AppLocalizations? l10n) {
    getIt<Notifier>().info(l10n?.comingSoon ?? 'Fonctionnalité à venir');
  }

  @override
  Widget build(BuildContext context) {
    return BlocProvider<RegisterCubit>.value(
      value: _registerCubit,
      child: BlocListener<RegisterCubit, RegisterState>(
        listenWhen: (prev, curr) => prev.status != curr.status,
        listener: (context, state) {
          if (state.status == AuthSubmissionStatus.success) {
            // Propose l'enregistrement des identifiants au gestionnaire de
            // mots de passe (hotfix-v0-10-1 US-1).
            TextInput.finishAutofillContext();
            context.go('/home');
          }
        },
        child: AuthScaffold(
          canPop: false,
          child: Form(
            key: _formKey,
            // Indispensable pour que les autofillHints soient agrégés par
            // les gestionnaires de mots de passe (hotfix-v0-10-1 US-1).
            child: AutofillGroup(
              child: BlocBuilder<RegisterCubit, RegisterState>(
              builder: (context, state) {
                final l10n = AppLocalizations.of(context);
                return _RegisterContent(
                  state: state,
                  emailController: _emailController,
                  usernameController: _usernameController,
                  passwordController: _passwordController,
                  confirmController: _confirmPasswordController,
                  validatorService: _validatorService,
                  onBack: _goToLogin,
                  onSubmit: _onSubmit,
                  onConsentRefused: () => _onConsentRefused(l10n),
                  onToggleTos: (v) => _registerCubit.setAcceptedTos(v),
                  onTogglePrivacy: (v) =>
                      _registerCubit.setAcceptedPrivacy(v),
                  onTapTos: () => _showLegalDoc('tos', l10n),
                  onTapPrivacy: () => _showLegalDoc('privacy', l10n),
                  onGoogle: (l10n) => _onGoogleLogin(l10n),
                  onApple: _onAppleLogin,
                );
              },
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// Contenu du formulaire d'inscription — extrait pour rester sous 150 lignes.
class _RegisterContent extends StatelessWidget {
  final RegisterState state;
  final TextEditingController emailController;
  final TextEditingController usernameController;
  final TextEditingController passwordController;
  final TextEditingController confirmController;
  final ValidatorService validatorService;
  final VoidCallback onBack;
  final Future<void> Function() onSubmit;
  final VoidCallback onConsentRefused;
  final ValueChanged<bool> onToggleTos;
  final ValueChanged<bool> onTogglePrivacy;
  final VoidCallback onTapTos;
  final VoidCallback onTapPrivacy;
  final Future<void> Function(AppLocalizations?) onGoogle;
  final void Function(AppLocalizations?) onApple;

  const _RegisterContent({
    required this.state,
    required this.emailController,
    required this.usernameController,
    required this.passwordController,
    required this.confirmController,
    required this.validatorService,
    required this.onBack,
    required this.onSubmit,
    required this.onConsentRefused,
    required this.onToggleTos,
    required this.onTogglePrivacy,
    required this.onTapTos,
    required this.onTapPrivacy,
    required this.onGoogle,
    required this.onApple,
  });

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
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
          title: l10n?.createAccountTitle ?? 'Créer un compte',
          subtitle:
              l10n?.registerSubtitle ?? 'Commencez à suivre vos lectures',
          logoSemanticLabel: l10n?.appTitle ?? 'MangaTracker',
        ),
        const SizedBox(height: AppSpacing.xl),
        AuthFormCard(
          children: [
            AuthFormField(
              label: l10n?.username ?? "Nom d'utilisateur",
              controller: usernameController,
              autofillHints: const [AutofillHints.username],
              textInputAction: TextInputAction.next,
              validator: validatorService.noValidation,
            ),
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
            AuthPasswordSection(
              passwordController: passwordController,
              confirmController: confirmController,
              validatorService: validatorService,
            ),
          ],
        ),
        const SizedBox(height: AppSpacing.m),
        ConsentCheckbox(
          checked: state.acceptedTos,
          onChanged: (v) => onToggleTos(v ?? false),
          label: l10n?.iAcceptTos ?? "J'accepte les Conditions d'utilisation",
          onTapLabel: onTapTos,
        ),
        const SizedBox(height: 4),
        ConsentCheckbox(
          checked: state.acceptedPrivacy,
          onChanged: (v) => onTogglePrivacy(v ?? false),
          label: l10n?.iAcceptPrivacy ??
              "J'accepte la Politique de confidentialité",
          onTapLabel: onTapPrivacy,
        ),
        const SizedBox(height: AppSpacing.m),
        AuthSubmitButton(
          text: l10n?.signUp ?? "S'inscrire",
          onPressed: state.isLoading
              ? null
              : (state.canSubmit ? onSubmit : onConsentRefused),
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
        const SizedBox(height: AppSpacing.xl),
        AuthDividerWithLabel(label: l10n?.orSignUpWith ?? "ou s'inscrire avec"),
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
          message: l10n?.alreadyHaveAccount ?? 'Vous avez déjà un compte ?',
          actionLabel: l10n?.login ?? 'Se connecter',
          onTap: onBack,
        ),
        const SizedBox(height: AppSpacing.s),
      ],
    );
  }
}
