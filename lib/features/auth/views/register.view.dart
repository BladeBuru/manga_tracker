import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:mangatracker/core/service_locator/service_locator.dart';
import 'package:mangatracker/core/components/language_selector_button.dart';
import 'package:mangatracker/l10n/app_localizations.dart';
import 'package:mangatracker/core/notifier/notifier.dart';

import '../../../core/components/password_fields.dart';
import '../services/validator.service.dart';
import '../../../core/components/intput_textfield.dart';
import '../../../core/components/auth_button.dart';
import '../widgets/square_tile.dart';
import '../services/auth.service.dart';
import '../../profile/services/gdpr.service.dart';
import '../presentation/cubit/auth_submission_status.dart';
import '../presentation/cubit/register_cubit.dart';
import '../presentation/cubit/register_state.dart';

class RegisterView extends StatefulWidget {
  final String emailText;

  const RegisterView({super.key, required this.emailText});

  @override
  State<RegisterView> createState() => _RegisterViewState();
}

class _RegisterViewState extends State<RegisterView> {
  late final GlobalKey<FormState> _formKey;
  final authService = getIt<AuthService>();
  final emailController = TextEditingController();
  final usernameController = TextEditingController();
  final passwordControler = TextEditingController();
  final TextEditingController confirmPasswordController =
      TextEditingController();

  final ValidatorService validatorService = getIt<ValidatorService>();
  late final RegisterCubit _registerCubit;

  @override
  void initState() {
    super.initState();
    // Créer une clé unique pour chaque instance
    _formKey = GlobalKey<FormState>();
    emailController.text = widget.emailText;
    _registerCubit = RegisterCubit(
      authService: authService,
      gdprService: getIt<GdprService>(),
    );
  }

  @override
  void dispose() {
    emailController.dispose();
    usernameController.dispose();
    passwordControler.dispose();
    confirmPasswordController.dispose();
    _registerCubit.close();
    super.dispose();
  }

  void singUpUser() async {
    FocusManager.instance.primaryFocus?.unfocus();

    if (!_formKey.currentState!.validate()) return;

    final l10n = AppLocalizations.of(context);

    await _registerCubit.submit(
      username: usernameController.text.trim().toLowerCase(),
      email: emailController.text.trim(),
      password: passwordControler.text,
      l10n: l10n,
    );
  }

  void redirectToLoginPage() {
    context.push('/login');
  }

  /// Ouvre une dialog résumant le contenu du document légal demandé.
  /// Le document complet doit être hébergé en ligne (URL publique stable).
  void _showLegalDoc(
    BuildContext context,
    String kind,
    AppLocalizations? l10n,
  ) {
    showDialog(
      context: context,
      builder:
          (ctx) => AlertDialog(
            title: Text(
              kind == 'tos'
                  ? (l10n?.termsOfServiceTitle ?? "Conditions d'utilisation")
                  : (l10n?.privacyPolicyTitle ??
                      'Politique de confidentialité'),
            ),
            content: SingleChildScrollView(
              child: Text(
                kind == 'tos'
                    ? (l10n?.tosShortVersion ??
                        "Manga Tracker est fourni en l'état, sans garantie. "
                            "L'éditeur décline toute responsabilité pour l'utilisation "
                            "non conforme par l'utilisateur (contenu illégal, scraping, etc.).\n\n"
                            "Document complet sur le site officiel.")
                    : (l10n?.privacyShortVersion ??
                        "Données collectées : email, mot de passe (hashé), bibliothèque manga, préférences. "
                            "Aucune donnée n'est vendue à des tiers. Vous pouvez exporter ou supprimer vos données à tout moment.\n\n"
                            "Document complet sur le site officiel."),
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

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: false,
      child: BlocProvider<RegisterCubit>.value(
        value: _registerCubit,
        child: BlocListener<RegisterCubit, RegisterState>(
          listenWhen: (previous, current) => previous.status != current.status,
          listener: (context, state) {
            if (state.status == AuthSubmissionStatus.success) {
              context.go('/home');
            }
          },
          child: Scaffold(
            resizeToAvoidBottomInset: true,
            body: SafeArea(
              child: LayoutBuilder(
                builder: (context, constraints) {
                  final bottomInset = MediaQuery.of(context).viewInsets.bottom;
                  final horizontalPadding = _horizontalPadding(
                    constraints.maxWidth,
                  );
                  return SingleChildScrollView(
                    padding: EdgeInsets.fromLTRB(
                      horizontalPadding,
                      0,
                      horizontalPadding,
                      bottomInset,
                    ),
                    child: Center(
                      child: ConstrainedBox(
                        constraints: const BoxConstraints(maxWidth: 480),
                        child: Form(
                          key: _formKey,
                          child: BlocBuilder<RegisterCubit, RegisterState>(
                            builder: (context, registerState) {
                              final l10n = AppLocalizations.of(context);
                              final theme = Theme.of(context);
                              final mutedColor = theme.colorScheme.onSurface
                                  .withValues(alpha: 0.6);
                              final dividerColor = theme.colorScheme.outline
                                  .withValues(alpha: 0.4);
                              return Column(
                                mainAxisSize: MainAxisSize.min,
                                crossAxisAlignment: CrossAxisAlignment.stretch,
                                children: [
                                  Row(
                                    mainAxisAlignment:
                                        MainAxisAlignment.spaceBetween,
                                    children: [
                                      Semantics(
                                        button: true,
                                        label: l10n?.back ?? 'Retour',
                                        child: IconButton(
                                          icon: Icon(
                                            Icons.arrow_back,
                                            color: mutedColor,
                                          ),
                                          tooltip: l10n?.back ?? 'Retour',
                                          onPressed: redirectToLoginPage,
                                        ),
                                      ),
                                      const LanguageSelectorButton(),
                                    ],
                                  ),
                                  const SizedBox(height: 20),
                                  Align(
                                    child: Image.asset(
                                      'assets/images/mask_logo.png',
                                      height: 150,
                                      semanticLabel:
                                          l10n?.appTitle ?? 'MangaTracker',
                                    ),
                                  ),
                                  const SizedBox(height: 30),
                                  Text(
                                    l10n?.startTrackingNow ??
                                        "Commencez à suivre votre lecture maintenant",
                                    textAlign: TextAlign.center,
                                    style: TextStyle(
                                      color: mutedColor,
                                      fontSize: 16,
                                    ),
                                  ),
                                  const SizedBox(height: 50),
                                  IntputTexteField(
                                    controller: emailController,
                                    hintText:
                                        l10n?.emailAddress ?? "Adresse e-mail",
                                    labelText:
                                        l10n?.emailAddress ?? "Adresse e-mail",
                                    obscureText: false,
                                    keyboardType: TextInputType.emailAddress,
                                    validator:
                                        (value) => validatorService
                                            .validateEmailAddress(
                                              value,
                                              context,
                                            ),
                                    autofillHints: const [AutofillHints.email],
                                    textInputAction: TextInputAction.next,
                                  ),
                                  const SizedBox(height: 20),
                                  IntputTexteField(
                                    controller: usernameController,
                                    hintText:
                                        l10n?.username ?? "Nom d'utilisateur",
                                    labelText:
                                        l10n?.username ?? "Nom d'utilisateur",
                                    obscureText: false,
                                    validator: validatorService.noValidation,
                                    autofillHints: const [
                                      AutofillHints.username,
                                    ],
                                    textInputAction: TextInputAction.next,
                                  ),
                                  const SizedBox(height: 20),
                                  PasswordFields(
                                    passwordControler: passwordControler,
                                    confirmPasswordControler:
                                        confirmPasswordController,
                                    validatorService: validatorService,
                                  ),
                                  const SizedBox(height: 20),

                                  // ─── Consentement RGPD obligatoire ───
                                  _ConsentCheckbox(
                                    checked: registerState.acceptedTos,
                                    onChanged:
                                        (v) => _registerCubit.setAcceptedTos(
                                          v ?? false,
                                        ),
                                    label:
                                        l10n?.iAcceptTos ??
                                        "J'accepte les Conditions d'utilisation",
                                    onTapLabel:
                                        () =>
                                            _showLegalDoc(context, 'tos', l10n),
                                  ),
                                  _ConsentCheckbox(
                                    checked: registerState.acceptedPrivacy,
                                    onChanged:
                                        (v) => _registerCubit
                                            .setAcceptedPrivacy(v ?? false),
                                    label:
                                        l10n?.iAcceptPrivacy ??
                                        "J'accepte la Politique de confidentialité",
                                    onTapLabel:
                                        () => _showLegalDoc(
                                          context,
                                          'privacy',
                                          l10n,
                                        ),
                                  ),
                                  const SizedBox(height: 16),

                                  AuthButton(
                                    text: l10n?.signUp ?? "S'inscrire",
                                    onTap:
                                        registerState.canSubmit
                                            ? singUpUser
                                            : () {
                                              ScaffoldMessenger.of(
                                                context,
                                              ).showSnackBar(
                                                SnackBar(
                                                  content: Text(
                                                    l10n?.consentRequired ??
                                                        'Vous devez accepter les CGU et la Politique de confidentialité.',
                                                  ),
                                                  backgroundColor:
                                                      Colors.orange,
                                                ),
                                              );
                                            },
                                    isLoading: registerState.isLoading,
                                  ),
                                  registerState.errorMessage != null
                                      ? Padding(
                                        padding: const EdgeInsets.only(
                                          top: 12.0,
                                        ),
                                        child: Text(
                                          registerState.errorMessage!,
                                          textAlign: TextAlign.center,
                                          style: TextStyle(
                                            color: theme.colorScheme.error,
                                            fontSize: 13,
                                            fontWeight: FontWeight.w500,
                                          ),
                                        ),
                                      )
                                      : const SizedBox(height: 8),
                                  const SizedBox(height: 40),
                                  Padding(
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 40.0,
                                    ),
                                    child: Row(
                                      children: [
                                        Expanded(
                                          child: Divider(
                                            thickness: 0.5,
                                            color: dividerColor,
                                          ),
                                        ),
                                        Padding(
                                          padding: const EdgeInsets.symmetric(
                                            horizontal: 10.0,
                                          ),
                                          child: Text(
                                            l10n?.or ?? 'Ou',
                                            style: TextStyle(color: mutedColor),
                                          ),
                                        ),
                                        Expanded(
                                          child: Divider(
                                            thickness: 0.5,
                                            color: dividerColor,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                  const SizedBox(height: 40),
                                  Row(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: [
                                      Semantics(
                                        button: true,
                                        label:
                                            l10n?.loginWithGoogle ??
                                            'Se connecter avec Google',
                                        child: SquareTile(
                                          imagePath:
                                              'assets/images/google_logo.png',
                                          onTap:
                                              registerState.isLoading
                                                  ? null
                                                  : () async {
                                                    final success =
                                                        await authService
                                                            .loginWithGoogle(
                                                              context,
                                                            );
                                                    if (!context.mounted) {
                                                      return;
                                                    }
                                                    if (success) {
                                                      context.go('/home');
                                                    } else {
                                                      getIt<Notifier>().error(
                                                        l10n?.googleLoginFailed ??
                                                            'Échec de la connexion Google',
                                                      );
                                                    }
                                                  },
                                        ),
                                      ),
                                      const SizedBox(width: 20),
                                      Semantics(
                                        button: true,
                                        label:
                                            l10n?.comingSoon ??
                                            'Fonctionnalité à venir',
                                        child: SquareTile(
                                          imagePath:
                                              'assets/images/apple_logo.png',
                                          onTap: () {
                                            getIt<Notifier>().info(
                                              l10n?.comingSoon ??
                                                  'Fonctionnalité à venir',
                                            );
                                          },
                                        ),
                                      ),
                                    ],
                                  ),
                                  const SizedBox(height: 40),
                                  Row(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: [
                                      Text(
                                        l10n?.alreadyHaveAccount ??
                                            "Vous avez déjà un compte ?",
                                        style: TextStyle(color: mutedColor),
                                      ),
                                      const SizedBox(width: 6),
                                      GestureDetector(
                                        onTap: redirectToLoginPage,
                                        child: Text(
                                          l10n?.login ?? "Se connecter",
                                          style: TextStyle(
                                            color: theme.colorScheme.primary,
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                  const SizedBox(height: 20),
                                ],
                              );
                            },
                          ),
                        ),
                      ),
                    ),
                  );
                },
              ),
            ),
          ),
        ),
      ),
    );
  }

  double _horizontalPadding(double maxWidth) {
    if (maxWidth >= 1200) return (maxWidth - 640) / 2;
    if (maxWidth >= 900) return 96;
    if (maxWidth >= 600) return 48;
    return 24;
  }
}

/// Case à cocher de consentement RGPD avec libellé cliquable (ouvre la
/// dialog d'aperçu du document légal).
class _ConsentCheckbox extends StatelessWidget {
  final bool checked;
  final ValueChanged<bool?> onChanged;
  final String label;
  final VoidCallback onTapLabel;

  const _ConsentCheckbox({
    required this.checked,
    required this.onChanged,
    required this.label,
    required this.onTapLabel,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Checkbox(
            value: checked,
            onChanged: onChanged,
            visualDensity: VisualDensity.compact,
          ),
          Expanded(
            child: GestureDetector(
              onTap: () => onChanged(!checked),
              child: Padding(
                padding: const EdgeInsets.symmetric(vertical: 12),
                child: Text.rich(
                  TextSpan(
                    children: [
                      TextSpan(text: label, style: theme.textTheme.bodySmall),
                      TextSpan(
                        text: '  →',
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: theme.colorScheme.primary,
                          fontWeight: FontWeight.w600,
                          decoration: TextDecoration.underline,
                        ),
                        recognizer: _OnTap(onTapLabel),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// Petit helper pour TextSpan tappable sans dépendance externe.
class _OnTap extends TapGestureRecognizer {
  _OnTap(VoidCallback handler) {
    onTap = handler;
  }
}
