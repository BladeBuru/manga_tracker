import 'package:google_fonts/google_fonts.dart';
import 'package:mangatracker/core/components/auth_button.dart';
import 'package:mangatracker/features/auth/exceptions/invalid_credentials.exception.dart';
import 'package:mangatracker/features/profile/helpers/user.helper.dart';
import 'package:mangatracker/core/errors/error_notifier.dart';
import '../../../core/service_locator/service_locator.dart';
import '../../../core/storage/model/storage_item.model.dart';
import '../../../core/storage/services/storage.service.dart';
import '../services/validator.service.dart';
import 'register.view.dart';
import 'package:flutter/material.dart';
import 'widgets/square_tile.dart';
import '../../home/views/bottom_navbar.dart';
import 'widgets/intput_textfield.dart';
import '../services/auth.service.dart';

class LoginView extends StatefulWidget {
  const LoginView({Key? key}) : super(key: key);
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
  final ErrorNotifier errorNotification = ErrorNotifier();

  onPressed() async {
    String email = _emailController.text.toLowerCase();
    String password = _passwordControler.text;
    dynamic payload;

    if (!context.mounted) return;

    // Close keyboard for allowing a better view of error messages
    FocusManager.instance.primaryFocus?.unfocus();

    if (!_formKey.currentState!.validate()) return;

    try {
      payload = await authService.attemptLogIn(email, password);
    } on InvalidCredentialsException {
      errorNotification.showErrorSnackBar('Invalid Credentials', context);
      return;
    } on Exception {
      errorNotification.showErrorSnackBar('Unknown Error', context);
    }

    final List<StorageItem> tokens = <StorageItem>[
      StorageItem('accessToken', payload['accessToken']),
      StorageItem('refreshToken', payload['refreshToken'])
    ];
    storageService.writeAllSecureData(tokens);

    if (context.mounted) {
      Navigator.of(context)
          .push(MaterialPageRoute(builder: (context) => const BottomNavbar()));
    }
  }

  void redirectToRegisterPage() {
    Navigator.push(
        context,
        MaterialPageRoute(
            builder: (context) =>
                RegisterView(emailText: _emailController.text)));
  }

  @override
  Widget build(BuildContext context) {
    /*
    WillPopScope forbids swipe back gesture to restrict user from going back to
    previous screen (which can be my account screen)
    */
    return WillPopScope(
        onWillPop: () async => false,
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

                      Image.asset(
                        'assets/images/mask_logo.png',
                        height: 150,
                      ),

                      const SizedBox(height: 20),

                      Text(
                        "Welcome Back",
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

                      const SizedBox(height: 50),

                      //Login texte field
                      IntputTexteField(
                        controller: _emailController,
                        textField: "Email Address",
                        obscureText: false,
                        validator: validatorService.validateEmailAddress,
                      ),

                      const SizedBox(height: 15),

                      //Password texte field
                      IntputTexteField(
                        controller: _passwordControler,
                        textField: "Password",
                        obscureText: true,
                        validator: validatorService.noValidation,
                      ),

                      const SizedBox(height: 15),

                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 30.0),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.end,
                          children: [
                            Text("Forgot Password?",
                                style: TextStyle(
                                  color: Colors.grey[600],
                                )),
                          ],
                        ),
                      ),

                      const SizedBox(height: 30),

                      AuthButton(
                        text: "Log In",
                        onTap: onPressed,
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
                              padding:
                                  const EdgeInsets.symmetric(horizontal: 10.0),
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
                              imagePath: 'assets/images/google_logo.png'),
                          SizedBox(
                            width: 20,
                          ),
                          SquareTile(imagePath: 'assets/images/apple_logo.png'),
                        ],
                      ),

                      const SizedBox(height: 40),

                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Text(
                            "Don't have an account?",
                            style: TextStyle(color: Colors.grey[600]),
                          ),
                          const SizedBox(width: 3),
                          GestureDetector(
                            onTap: () {
                              redirectToRegisterPage();
                            },
                            child: Text(
                              "Sign Up",
                              style: TextStyle(color: Colors.red[400]),
                            ),
                          ),
                        ],
                      ),
                      const Padding(
                          padding: EdgeInsets.symmetric(vertical: 20.0))
                    ]),
                  ),
                ),
              ),
            )));
  }
}
