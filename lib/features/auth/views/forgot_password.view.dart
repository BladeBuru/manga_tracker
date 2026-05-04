import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:mangatracker/core/components/auth_button.dart';
import 'package:mangatracker/core/components/intput_textfield.dart';
import 'package:mangatracker/core/service_locator/service_locator.dart';
import 'package:mangatracker/features/auth/presentation/cubit/forgot_password_cubit.dart';
import 'package:mangatracker/features/auth/services/email_auth.service.dart';
import 'package:mangatracker/features/auth/services/validator.service.dart';
import 'package:mangatracker/l10n/app_localizations.dart';

/// Vue « Mot de passe oublié » — saisie de l'email pour recevoir un lien.
///
/// Anti-énumération : après soumission, l'écran affiche TOUJOURS le même
/// message de succès (« Si un compte existe pour cet email… »), même si
/// l'email n'existe pas. Le serveur enforce aussi la même réponse.
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
    final l10n = AppLocalizations.of(context);
    return Scaffold(
      appBar: AppBar(
        title: Text(l10n?.forgotPasswordTitle ?? 'Mot de passe oublié'),
      ),
      body: BlocProvider<ForgotPasswordCubit>.value(
        value: _cubit,
        child: BlocBuilder<ForgotPasswordCubit, ForgotPasswordState>(
          builder: (context, state) {
            if (state.isSuccess) {
              return _buildSuccessView(state.submittedEmail, l10n);
            }
            return _buildForm(state, l10n);
          },
        ),
      ),
    );
  }

  Widget _buildForm(ForgotPasswordState state, AppLocalizations? l10n) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Form(
        key: _formKey,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const SizedBox(height: 16),
            Text(
              l10n?.forgotPasswordIntro ??
                  'Entrez votre email. Si un compte existe, vous recevrez un lien pour définir un nouveau mot de passe.',
              style: Theme.of(context).textTheme.bodyMedium,
            ),
            const SizedBox(height: 24),
            IntputTexteField(
              controller: _emailController,
              hintText: l10n?.email ?? 'Email',
              keyboardType: TextInputType.emailAddress,
              autofillHints: const [AutofillHints.email],
              validator: (v) => _validator.validateEmailAddress(v, context),
              textInputAction: TextInputAction.done,
              onSubmitted: _submit,
            ),
            const SizedBox(height: 24),
            AuthButton(
              text: l10n?.sendResetLink ?? 'Envoyer le lien',
              onTap: state.isLoading ? () {} : _submit,
              isLoading: state.isLoading,
            ),
            if (state.errorMessage != null && !state.isSuccess) ...[
              const SizedBox(height: 12),
              Text(
                l10n?.networkError ?? 'Erreur réseau. Réessayez plus tard.',
                textAlign: TextAlign.center,
                style: TextStyle(color: Colors.red[600], fontSize: 13),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildSuccessView(String email, AppLocalizations? l10n) {
    return Padding(
      padding: const EdgeInsets.all(24),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.mark_email_read_outlined,
            size: 72,
            color: Theme.of(context).colorScheme.primary,
          ),
          const SizedBox(height: 24),
          Text(
            l10n?.resetEmailSentTitle ?? 'Vérifiez votre boîte mail',
            style: Theme.of(context).textTheme.headlineSmall,
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 12),
          Text(
            l10n?.resetEmailSentMessage(email) ??
                'Si un compte existe pour $email, un email contenant un lien pour définir un nouveau mot de passe vient d\'être envoyé.\n\nLe lien expire dans 30 minutes.',
            textAlign: TextAlign.center,
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: Colors.grey[700],
                ),
          ),
          const SizedBox(height: 32),
          OutlinedButton(
            onPressed: () => Navigator.of(context).pop(),
            child: Text(l10n?.back ?? 'Retour'),
          ),
        ],
      ),
    );
  }
}
