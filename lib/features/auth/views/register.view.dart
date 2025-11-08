import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:mangatracker/core/service_locator/service_locator.dart';
import 'package:mangatracker/core/components/language_selector_button.dart';
import 'package:mangatracker/l10n/app_localizations.dart';
import 'package:mangatracker/core/notifier/notifier.dart';

import '../../../core/components/password_fields.dart';
import '../services/validator.service.dart';
import '../../../core/components/intput_textfield.dart';
import '../../../core/components/auth_button.dart';
import 'login.view.dart';
import '../widgets/square_tile.dart';
import '../services/auth.service.dart';
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
  final TextEditingController confirmPasswordController = TextEditingController();

  final ValidatorService validatorService = getIt<ValidatorService>();
  late final RegisterCubit _registerCubit;

  @override
  void initState() {
    super.initState();
    // Créer une clé unique pour chaque instance
    _formKey = GlobalKey<FormState>();
    emailController.text = widget.emailText;
    _registerCubit = RegisterCubit(authService: authService);
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
    Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => const LoginView()),
    );
  }

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: false,
      child: BlocProvider<RegisterCubit>.value(
        value: _registerCubit,
        child: BlocListener<RegisterCubit, RegisterState>(
          listenWhen: (previous, current) =>
              previous.status != current.status,
          listener: (context, state) {
            if (state.status == AuthSubmissionStatus.success) {
              redirectToLoginPage();
              _registerCubit.reset();
            }
          },
          child: Container(
            color: Colors.grey[200],
            child: SafeArea(
              child: Scaffold(
                resizeToAvoidBottomInset: false,
                backgroundColor: Colors.grey[200],
                body: Stack(
                  children: [
                    SingleChildScrollView(
                      child: SafeArea(
                        child: Center(
                          child: Form(
                            key: _formKey,
                            child: BlocBuilder<RegisterCubit, RegisterState>(
                              builder: (context, registerState) {
                                final l10n = AppLocalizations.of(context);
                                return Column(
                                  mainAxisSize: MainAxisSize.min,
                                  crossAxisAlignment: CrossAxisAlignment.stretch,
                                  children: [
                                    Row(
                                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                      children: [
                                        Semantics(
                                          button: true,
                                          label: l10n?.back ?? 'Retour',
                                          child: IconButton(
                                            icon: Icon(
                                              Icons.arrow_back,
                                              color: Colors.grey[600],
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
                                        semanticLabel: l10n?.appTitle ?? 'MangaTracker',
                                      ),
                                    ),
                                    const SizedBox(height: 30),
                                    Text(
                                      l10n?.startTrackingNow ?? "Commencez à suivre votre lecture maintenant",
                                      textAlign: TextAlign.center,
                                      style: TextStyle(
                                        color: Colors.grey[600],
                                        fontSize: 16,
                                      ),
                                    ),
                                    const SizedBox(height: 50),
                                    IntputTexteField(
                                      controller: emailController,
                                      hintText: l10n?.emailAddress ?? "Adresse e-mail",
                                      labelText: l10n?.emailAddress ?? "Adresse e-mail",
                                      obscureText: false,
                                      keyboardType: TextInputType.emailAddress,
                                      validator: (value) => validatorService.validateEmailAddress(value, context),
                                      autofillHints: const [AutofillHints.email],
                                      textInputAction: TextInputAction.next,
                                    ),
                                    const SizedBox(height: 20),
                                    IntputTexteField(
                                      controller: usernameController,
                                      hintText: l10n?.username ?? "Nom d'utilisateur",
                                      labelText: l10n?.username ?? "Nom d'utilisateur",
                                      obscureText: false,
                                      validator: validatorService.noValidation,
                                      autofillHints: const [AutofillHints.username],
                                      textInputAction: TextInputAction.next,
                                    ),
                                    const SizedBox(height: 20),
                                    PasswordFields(
                                      passwordControler: passwordControler,
                                      confirmPasswordControler: confirmPasswordController,
                                      validatorService: validatorService,
                                    ),
                                    const SizedBox(height: 30),
                                    AuthButton(
                                      text: l10n?.signUp ?? "S'inscrire",
                                      onTap: singUpUser,
                                      isLoading: registerState.isLoading,
                                    ),
                                    registerState.errorMessage != null
                                        ? Padding(
                                            padding: const EdgeInsets.only(top: 12.0),
                                            child: Text(
                                              registerState.errorMessage!,
                                              textAlign: TextAlign.center,
                                              style: TextStyle(
                                                color: Colors.red[600],
                                                fontSize: 13,
                                                fontWeight: FontWeight.w500,
                                              ),
                                            ),
                                          )
                                        : const SizedBox(height: 8),
                                    const SizedBox(height: 40),
                                    Padding(
                                      padding: const EdgeInsets.symmetric(horizontal: 40.0),
                                      child: Row(
                                        children: [
                                          Expanded(
                                            child: Divider(
                                              thickness: 0.5,
                                              color: Colors.grey[400],
                                            ),
                                          ),
                                          Padding(
                                            padding: const EdgeInsets.symmetric(horizontal: 10.0),
                                            child: Text(
                                              l10n?.or ?? 'Ou',
                                              style: TextStyle(color: Colors.grey[600]),
                                            ),
                                          ),
                                          Expanded(
                                            child: Divider(
                                              thickness: 0.5,
                                              color: Colors.grey[400],
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
                                          label: l10n?.comingSoon ?? 'Fonctionnalité à venir',
                                          child: SquareTile(
                                            imagePath: 'assets/images/google_logo.png',
                                            onTap: () {
                                              getIt<Notifier>().info(l10n?.comingSoon ?? 'Fonctionnalité à venir');
                                            },
                                          ),
                                        ),
                                        const SizedBox(width: 20),
                                        Semantics(
                                          button: true,
                                          label: l10n?.comingSoon ?? 'Fonctionnalité à venir',
                                          child: SquareTile(
                                            imagePath: 'assets/images/apple_logo.png',
                                            onTap: () {
                                              getIt<Notifier>().info(l10n?.comingSoon ?? 'Fonctionnalité à venir');
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
                                          l10n?.alreadyHaveAccount ?? "Vous avez déjà un compte ?",
                                          style: TextStyle(color: Colors.grey[600]),
                                        ),
                                        const SizedBox(width: 6),
                                        GestureDetector(
                                          onTap: redirectToLoginPage,
                                          child: Text(
                                            l10n?.login ?? "Se connecter",
                                            style: TextStyle(
                                              color: Colors.red[400],
                                              decoration: TextDecoration.underline,
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
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
