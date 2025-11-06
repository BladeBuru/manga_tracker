import 'package:flutter/material.dart';
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

class RegisterView extends StatefulWidget {
  final String emailText;

  const RegisterView({super.key, required this.emailText});

  @override
  State<RegisterView> createState() => _RegisterViewState();
}

class _RegisterViewState extends State<RegisterView> {
  late final GlobalKey<FormState> _formKey;
  
  @override
  void initState() {
    super.initState();
    // Créer une clé unique pour chaque instance
    _formKey = GlobalKey<FormState>();
  }
  final authService = getIt<AuthService>();
  final emailController = TextEditingController();
  final usernameController = TextEditingController();
  final passwordControler = TextEditingController();

  final ValidatorService validatorService = getIt<ValidatorService>();

  void singUpUser() async {
    FocusManager.instance.primaryFocus?.unfocus();

    if (!_formKey.currentState!.validate()) return;

    await authService.attemptSignUp(
      usernameController.text.trim().toLowerCase(),
      emailController.text.trim(),
      passwordControler.text,
    );

    if (!mounted) return;
    redirectToLoginPage();
  }

  void redirectToLoginPage() {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => const LoginView()),
    );
  }

  @override
  Widget build(BuildContext context) {
    /*
    WillPopScope forbids swipe back gesture to restrict user from going back to
    previous screen (which can be my account screen)
    */
     return PopScope(
       canPop: false,
       child: Container(
        color: Colors.grey[200],
        child: SafeArea(
          child: Scaffold(
            resizeToAvoidBottomInset: false,
            backgroundColor: Colors.grey[200],
            body: Stack(
              children: [
                SingleChildScrollView(
                  physics: const NeverScrollableScrollPhysics(),
                  child: SafeArea(
                    child: Center(
                      child: Form(
                        key: _formKey,
                        child: Column(
                          children: [
                            const SizedBox(height: 20),

                        Image.asset('assets/images/mask_logo.png', height: 150),

                            const SizedBox(height: 30),

                            Builder(
                              builder: (context) {
                                final l10n = AppLocalizations.of(context);
                                return Text(
                                  l10n?.startTrackingNow ?? "Commencez à suivre votre lecture maintenant",
                                  style: TextStyle(
                                    color: Colors.grey[500],
                                    fontSize: 16,
                                  ),
                                );
                              },
                            ),

                            const SizedBox(height: 50),

                            //Email texte field
                            Builder(
                              builder: (context) {
                                final l10n = AppLocalizations.of(context);
                                return IntputTexteField(
                                  controller: emailController,
                                  hintText: l10n?.emailAddress ?? "Adresse e-mail",
                                  obscureText: false,
                                  keyboardType: TextInputType.emailAddress,
                                  validator: validatorService.validateEmailAddress,
                                  autofillHints: const [AutofillHints.email],
                                  textInputAction: TextInputAction.next,
                                );
                              },
                            ),

                            const SizedBox(height: 15),

                            //Username texte field
                            Builder(
                              builder: (context) {
                                final l10n = AppLocalizations.of(context);
                                return IntputTexteField(
                                  controller: usernameController,
                                  hintText: l10n?.username ?? "Nom d'utilisateur",
                                  obscureText: false,
                                  validator: validatorService.noValidation,
                                  autofillHints: const [AutofillHints.username],
                                  textInputAction: TextInputAction.next,
                                );
                              },
                            ),

                            const SizedBox(height: 15),

                            PasswordFields(
                              passwordControler: passwordControler,
                              confirmPasswordControler: TextEditingController(),
                              validatorService: validatorService,
                            ),

                            const SizedBox(height: 30),

                            Builder(
                              builder: (context) {
                                final l10n = AppLocalizations.of(context);
                                return AuthButton(
                                  text: l10n?.signUp ?? "S'inscrire",
                                  onTap: singUpUser,
                                );
                              },
                            ),

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
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 10.0,
                                    ),
                                    child: Builder(
                                      builder: (context) {
                                        final l10n = AppLocalizations.of(context);
                                        return Text(
                                          l10n?.or ?? 'Ou',
                                          style: TextStyle(color: Colors.grey[600]),
                                        );
                                      },
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

                            Builder(
                              builder: (context) {
                                final l10n = AppLocalizations.of(context);
                                return Row(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    SquareTile(
                                      imagePath: 'assets/images/google_logo.png',
                                      onTap: () {
                                        getIt<Notifier>().info(l10n?.comingSoon ?? 'Fonctionnalité à venir');
                                      },
                                    ),
                                    const SizedBox(width: 20),
                                    SquareTile(
                                      imagePath: 'assets/images/apple_logo.png',
                                      onTap: () {
                                        getIt<Notifier>().info(l10n?.comingSoon ?? 'Fonctionnalité à venir');
                                      },
                                    ),
                                  ],
                                );
                              },
                            ),

                            const SizedBox(height: 40),

                            Builder(
                              builder: (context) {
                                final l10n = AppLocalizations.of(context);
                                return Row(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    Text(
                                      l10n?.alreadyHaveAccount ?? "Vous avez déjà un compte ?",
                                      style: TextStyle(color: Colors.grey[600]),
                                    ),
                                    const SizedBox(width: 3),
                                    GestureDetector(
                                      onTap: () {
                                        redirectToLoginPage();
                                      },
                                      child: Text(
                                        l10n?.login ?? "Se connecter",
                                        style: TextStyle(color: Colors.red[400]),
                                      ),
                                    ),
                                  ],
                                );
                              },
                            ),
                            const Padding(
                              padding: EdgeInsets.symmetric(vertical: 20.0),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
                // Bouton de sélection de langue en haut à droite
                Positioned(
                  top: 8,
                  right: 8,
                  child: const LanguageSelectorButton(),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
