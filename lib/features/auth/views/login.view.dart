import 'package:google_fonts/google_fonts.dart';
import 'package:mangatracker/core/components/auth_button.dart';
import 'package:mangatracker/features/auth/exceptions/invalid_credentials.exception.dart';
import 'package:mangatracker/features/profile/helpers/user.helper.dart';
import '../../../core/notifier/notifier.dart';
import '../../../core/service_locator/service_locator.dart';
import '../../../core/storage/model/storage_item.model.dart';
import '../../../core/storage/services/storage.service.dart';
import '../services/validator.service.dart';
import 'register.view.dart';
import 'package:flutter/material.dart';
import '../widgets/square_tile.dart';
import '../../home/views/bottom_navbar.dart';
import '../../../core/components/intput_textfield.dart';
import '../services/auth.service.dart';
import 'package:mangatracker/l10n/app_localizations.dart';

class LoginView extends StatefulWidget {
  const LoginView({super.key});

  @override
  State<StatefulWidget> createState() => _LoginViewState();
}

class _LoginViewState extends State<LoginView> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _passwordControler = TextEditingController();
  final authService = getIt<AuthService>();
  final StorageService storageService = getIt<StorageService>();
  final ValidatorService validatorService = getIt<ValidatorService>();
  final Notifier notifier = Notifier();

  onPressed() async {
    String email = _emailController.text.toLowerCase();
    String password = _passwordControler.text;
    dynamic payload;

    if (!context.mounted) return;

    // Close keyboard for allowing a better view of error messages
    FocusManager.instance.primaryFocus?.unfocus();

    if (!_formKey.currentState!.validate()) return;

    final l10n = AppLocalizations.of(context);
    try {
      payload = await authService.attemptLogIn(email, password);
    } on InvalidCredentialsException {
      notifier.error(l10n?.invalidCredentials ?? 'Identifiants invalides');
      return;
    } on Exception {
      notifier.error(l10n?.unknownError ?? 'Erreur inconnue');
      return;
    }

    final List<StorageItem> tokens = <StorageItem>[
      StorageItem('accessToken', payload['accessToken']),
      StorageItem('refreshToken', payload['refreshToken']),
    ];
    storageService.writeAllSecureData(tokens);

    if (!context.mounted) return;

    // Vérifier si c'est la première fois (pas de préférence) et si la biométrie est disponible
    final hasPreference = await authService.hasBiometricPreference();
    if (!hasPreference) {
      final isBiometricAvailable = await authService.biometricService.hasBiometricSupport();
      if (isBiometricAvailable && context.mounted) {
        // Afficher la dialog de proposition
        await _showBiometricActivationDialog(email, password, l10n);
      }
    }

    if (context.mounted) {
      Navigator.of(
        context,
      ).push(MaterialPageRoute(builder: (context) => const BottomNavbar()));
    }
  }

  Future<void> _showBiometricActivationDialog(
    String email,
    String password,
    AppLocalizations? l10n,
  ) async {
    if (!context.mounted) return;

    final result = await showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text(
            l10n?.biometricAuthFirstTimeTitle ?? 'Activer l\'authentification biométrique ?',
          ),
          content: Text(
            l10n?.biometricAuthFirstTimeMessage ??
                'Souhaitez-vous utiliser votre empreinte digitale ou Face ID pour vous connecter rapidement à l\'avenir ?',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(false),
              child: Text(l10n?.cancel ?? 'Annuler'),
            ),
            TextButton(
              onPressed: () => Navigator.of(context).pop(true),
              child: Text(l10n?.save ?? 'Activer'),
            ),
          ],
        );
      },
    );

    if (result == true) {
      // L'utilisateur a accepté : activer la biométrie et sauvegarder les identifiants
      await authService.setBiometricEnabled(true, email: email, password: password);
    } else {
      // L'utilisateur a refusé : sauvegarder la préférence comme "refusé"
      await authService.setBiometricEnabled(false);
    }
  }

  void redirectToRegisterPage() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => RegisterView(emailText: _emailController.text),
      ),
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
      child: Scaffold(
        backgroundColor: Colors.grey[200],
        body: SafeArea(
          child: SingleChildScrollView(
            child: Center(
              child: Form(
                key: _formKey,
                child: Column(
                  children: [
                    const SizedBox(height: 50),

                    Image.asset('assets/images/mask_logo.png', height: 150),

                    const SizedBox(height: 20),

                    Builder(
                      builder: (context) {
                        final l10n = AppLocalizations.of(context);
                        return Column(
                          children: [
                            Text(
                              l10n?.welcomeBack ?? "Content de vous revoir",
                              style: TextStyle(color: Colors.grey[500], fontSize: 16),
                            ),

                            //const SizedBox(height: 20),
                            Text(
                              UserHelper.getRandomCallname(),
                              style: GoogleFonts.poppins(
                                fontSize: 22,
                                fontWeight: FontWeight.w600,
                                color: const Color(0xff1f1f39),
                              ),
                            ),
                          ],
                        );
                      },
                    ),

                    const SizedBox(height: 50),

                    Builder(
                      builder: (context) {
                        final l10n = AppLocalizations.of(context);
                        return Column(
                          children: [
                            //Login texte field
                            IntputTexteField(
                              controller: _emailController,
                              hintText: l10n?.emailAddress ?? "Adresse e-mail",
                              obscureText: false,
                              autofillHints: const [AutofillHints.email],
                              validator: validatorService.validateEmailAddress,
                              keyboardType: TextInputType.emailAddress
                            ),

                            const SizedBox(height: 15),

                            //Password texte field
                            IntputTexteField(
                              controller: _passwordControler,
                              hintText: l10n?.password ?? "Mot de passe",
                              obscureText: true,
                              autofillHints: const [AutofillHints.password],
                              validator: validatorService.noValidation,
                            ),

                            const SizedBox(height: 15),

                            Padding(
                              padding: const EdgeInsets.symmetric(horizontal: 30.0),
                              child: Row(
                                mainAxisAlignment: MainAxisAlignment.end,
                                children: [
                                  Text(
                                    l10n?.forgotPassword ?? "Mot de passe oublié ?",
                                    style: TextStyle(color: Colors.grey[600]),
                                  ),
                                ],
                              ),
                            ),

                            const SizedBox(height: 30),

                            AuthButton(
                              text: l10n?.login ?? "Se connecter",
                              onTap: onPressed,
                            ),
                          ],
                        );
                      },
                    ),
                    const SizedBox(height: 15),

                    // Afficher le bouton biométrique uniquement si l'option est activée
                    FutureBuilder<bool>(
                      future: authService.isBiometricEnabled(),
                      builder: (context, snapshot) {
                        if (snapshot.hasData && snapshot.data == true) {
                          return TextButton.icon(
                            onPressed: () async {
                              final success = await authService.tryBiometricLogin(context);
                              if (!mounted) return;

                              if (success) {
                                Navigator.of(context).pushReplacement(
                                  MaterialPageRoute(builder: (_) => const BottomNavbar()),
                                );
                              } else {
                                final l10n = AppLocalizations.of(context);
                                notifier.error(l10n?.biometricAuthFailed ?? 'Echec de l\'authentification biometrique');
                              }
                            },
                            icon: const Icon(Icons.fingerprint, color: Colors.grey),
                            label: Builder(
                              builder: (context) {
                                final l10n = AppLocalizations.of(context);
                                return Text(
                                  l10n?.biometricAuth ?? "Connexion biométrique",
                                  style: const TextStyle(color: Colors.grey),
                                );
                              },
                            ),
                          );
                        }
                        return const SizedBox.shrink();
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
                          child: const Text(
                            'Ou', // Ce texte peut rester tel quel, c'est un séparateur
                            style: TextStyle(color: Colors.grey),
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
                      children: const [
                        SquareTile(imagePath: 'assets/images/google_logo.png'),
                        SizedBox(width: 20),
                        SquareTile(imagePath: 'assets/images/apple_logo.png'),
                      ],
                    ),

                    const SizedBox(height: 40),

                    Builder(
                      builder: (context) {
                        final l10n = AppLocalizations.of(context);
                        return Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Text(
                              l10n?.noAccount ?? "Vous n'avez pas de compte ?",
                              style: TextStyle(color: Colors.grey[600]),
                            ),
                            const SizedBox(width: 3),
                            GestureDetector(
                              onTap: () {
                                redirectToRegisterPage();
                              },
                              child: Text(
                                l10n?.signUp ?? "S'inscrire",
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
      ),
    );
  }
}
