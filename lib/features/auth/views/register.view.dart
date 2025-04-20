import 'package:flutter/material.dart';
import 'package:mangatracker/core/service_locator/service_locator.dart';

import '../services/validator.service.dart';
import 'widgets/intput_textfield.dart';
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
  final confirmPasswordControler = TextEditingController();

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
                          "Start Reading Now",
                          style: TextStyle(
                            color: Colors.grey[500],
                            fontSize: 16,
                          ),
                        ),

                        const SizedBox(height: 50),

                        //Login texte field
                        IntputTexteField(
                          controller: emailController,
                          textField: "Email Address",
                          obscureText: false,
                          validator: validatorService.validateEmailAddress,
                        ),

                        const SizedBox(height: 15),

                        IntputTexteField(
                          controller: usernameController,
                          textField: "Username",
                          obscureText: false,
                          validator: validatorService.noValidation,
                        ),

                        const SizedBox(height: 15),

                        //Password texte field
                        IntputTexteField(
                          controller: passwordControler,
                          textField: "Password",
                          obscureText: true,
                          validator: validatorService.validatePassword,
                        ),

                        const SizedBox(height: 15),

                        //Confimr Password texte field
                        IntputTexteField(
                          controller: confirmPasswordControler,
                          textField: "Confirm password",
                          obscureText: true,
                          validator: (value) {
                            return validatorService.validateConfirmPassword(
                              value,
                              passwordControler,
                            );
                          },
                        ),

                        const SizedBox(height: 30),

                        AuthButton(text: "Sign Up", onTap: singUpUser),

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
                                  'Or',
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
                              "Already have an account?",
                              style: TextStyle(color: Colors.grey[600]),
                            ),
                            const SizedBox(width: 3),
                            GestureDetector(
                              onTap: () {
                                redirectToLoginPage();
                              },
                              child: Text(
                                "Log In",
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
