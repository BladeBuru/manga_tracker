import 'package:flutter/material.dart';
import 'package:mangatracker/core/service_locator/service_locator.dart';

import '../../../core/components/password_fields.dart';
import '../services/validator.service.dart';
import '../../../core/components/intput_textfield.dart';
import '../../../core/components/auth_button.dart';
import 'login.view.dart';
import 'widgets/square_tile.dart';
import '../services/auth.service.dart';

class RegisterView extends StatefulWidget {
  final String emailText;

  const RegisterView({Key? key, required this.emailText}) : super(key: key);

  @override
  State<RegisterView> createState() => _RegisterViewState();
}

class _RegisterViewState extends State<RegisterView> {
  final _formKey = GlobalKey<FormState>();
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
    this.redirectToLoginPage();
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
    return WillPopScope(
      onWillPop: () async => false,
      child: Container(
        color: Colors.grey[200],
        child: SafeArea(
          child: Scaffold(
            resizeToAvoidBottomInset: false,
            backgroundColor: Colors.grey[200],
            body: SingleChildScrollView(
              child: SafeArea(
                child: Center(
                  child: Form(
                    key: _formKey,
                    child: Column(
                      children: [
                        const SizedBox(height: 20),

                        Image.asset('assets/images/mask_logo.png', height: 150),

                        const SizedBox(height: 30),

                        Text(
                          "Commencez à suivre votre lecture maintenant",
                          style: TextStyle(
                            color: Colors.grey[500],
                            fontSize: 16,
                          ),
                        ),

                        const SizedBox(height: 50),

                        //Login texte field
                      IntputTexteField(
                        controller: emailController,
                        hintText: "Adresse e-mail",
                        obscureText: false,
                        keyboardType: TextInputType.emailAddress,
                        validator: validatorService.validateEmailAddress,
                        autofillHints: const [AutofillHints.email],
                      ),


                        const SizedBox(height: 15),

                        IntputTexteField(
                          controller: usernameController,
                          hintText: "Nom d'utilisateur",
                          obscureText: false,
                          validator: validatorService.noValidation,
                          autofillHints: const [AutofillHints.username],
                        ),


                        const SizedBox(height: 15),

                        PasswordFields(
                          passwordControler: passwordControler,
                          confirmPasswordControler: TextEditingController(),
                          validatorService: validatorService,
                        ),

                        const SizedBox(height: 30),

                        AuthButton(text: "S'inscrire", onTap: singUpUser),

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
                                child: Text(
                                  'Ou',
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
                          children: const [
                            SquareTile(
                              imagePath: 'assets/images/google_logo.png',
                            ),
                            SizedBox(width: 20),
                            SquareTile(
                              imagePath: 'assets/images/apple_logo.png',
                            ),
                          ],
                        ),

                        const SizedBox(height: 40),

                        Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Text(
                              "Vous avez déjà un compte ?",
                              style: TextStyle(color: Colors.grey[600]),
                            ),
                            const SizedBox(width: 3),
                            GestureDetector(
                              onTap: () {
                                redirectToLoginPage();
                              },
                              child: Text(
                                "Se connecter",
                                style: TextStyle(color: Colors.red[400]),
                              ),
                            ),
                          ],
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
        ),
      ),
    );
  }
}
