import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:mangatracker/core/components/auth_button.dart';
import 'package:mangatracker/core/components/password_fields.dart';
import 'package:mangatracker/core/service_locator/service_locator.dart';
import 'package:mangatracker/features/auth/presentation/cubit/reset_password_cubit.dart';
import 'package:mangatracker/features/auth/services/auth.service.dart';
import 'package:mangatracker/features/auth/services/email_auth.service.dart';
import 'package:mangatracker/features/auth/services/validator.service.dart';
import 'package:mangatracker/l10n/app_localizations.dart';

/// Vue « Définir un nouveau mot de passe ».
///
/// Atteignable via :
///  - Deep link : `https://bladeburu.com/auth/reset-password?token=XXX`
///    → l'app intercepte (App Links Android) et navigue ici avec le token.
///  - Saisie manuelle (cas du fallback web → l'utilisateur copie-colle).
///
/// Après succès, l'utilisateur est auto-loggué (les JWT retournés par
/// l'API sont persistés via `AuthService.persistTokens`).
class ResetPasswordView extends StatefulWidget {
  /// Token brut reçu dans le lien email (64 hex chars).
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

  void _goHome() {
    context.go('/home');
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return Scaffold(
      appBar: AppBar(
        title: Text(l10n?.resetPasswordTitle ?? 'Nouveau mot de passe'),
      ),
      body: BlocProvider<ResetPasswordCubit>.value(
        value: _cubit,
        child: BlocConsumer<ResetPasswordCubit, ResetPasswordState>(
          listener: (context, state) {
            if (state.isSuccess) {
              // Petite pause pour que l'utilisateur voit le succès, puis nav
              Future.delayed(const Duration(milliseconds: 800), _goHome);
            }
          },
          builder: (context, state) {
            if (state.isSuccess) return _buildSuccessView(l10n);
            return _buildForm(state, l10n);
          },
        ),
      ),
    );
  }

  Widget _buildForm(ResetPasswordState state, AppLocalizations? l10n) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final horizontalPadding = constraints.maxWidth >= 600 ? 24.0 : 16.0;
        return SingleChildScrollView(
          padding: EdgeInsets.symmetric(horizontal: horizontalPadding, vertical: 24),
          child: Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 480),
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    const SizedBox(height: 16),
                    Text(
                      l10n?.resetPasswordIntro ??
                          'Définissez un nouveau mot de passe pour votre compte. Une fois validé, vous serez automatiquement connecté.',
                      style: Theme.of(context).textTheme.bodyMedium,
                    ),
                    const SizedBox(height: 24),
                    PasswordFields(
                      passwordControler: _passwordController,
                      confirmPasswordControler: _confirmController,
                      validatorService: _validator,
                    ),
                    const SizedBox(height: 24),
                    AuthButton(
                      text: l10n?.confirmReset ?? 'Confirmer',
                      onTap: state.isLoading ? () {} : _submit,
                      isLoading: state.isLoading,
                    ),
                    if (state.errorMessage != null) ...[
                      const SizedBox(height: 12),
                      Text(
                        state.tokenExpired
                            ? (l10n?.resetTokenExpired ??
                                'Lien invalide ou expiré. Refaites une demande.')
                            : (l10n?.networkError ?? 'Erreur réseau. Réessayez plus tard.'),
                        textAlign: TextAlign.center,
                        style: TextStyle(color: Colors.red[600], fontSize: 13),
                      ),
                    ],
                  ],
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildSuccessView(AppLocalizations? l10n) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final horizontalPadding = constraints.maxWidth >= 600 ? 24.0 : 16.0;
        return Padding(
          padding: EdgeInsets.symmetric(horizontal: horizontalPadding, vertical: 24),
          child: Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 480),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.check_circle_outline,
                    size: 72,
                    color: Theme.of(context).colorScheme.primary,
                  ),
                  const SizedBox(height: 24),
                  Text(
                    l10n?.resetPasswordSuccess ?? 'Mot de passe modifié',
                    style: Theme.of(context).textTheme.headlineSmall,
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 12),
                  Text(
                    l10n?.resetPasswordSuccessHint ??
                        'Vous êtes maintenant connecté. Redirection en cours…',
                    textAlign: TextAlign.center,
                    style: Theme.of(context)
                        .textTheme
                        .bodyMedium
                        ?.copyWith(color: Colors.grey[700]),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}
