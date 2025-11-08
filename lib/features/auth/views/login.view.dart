import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:mangatracker/core/components/auth_button.dart';
import 'package:mangatracker/core/components/language_selector_button.dart';
import 'package:mangatracker/features/profile/helpers/user.helper.dart';
import '../../../core/notifier/notifier.dart';
import '../../../core/service_locator/service_locator.dart';
import '../presentation/cubit/auth_submission_status.dart';
import '../presentation/cubit/login_cubit.dart';
import '../presentation/cubit/login_state.dart';
import '../services/validator.service.dart';
import 'register.view.dart';
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
  late final GlobalKey<FormState> _formKey;
  bool _obscurePassword = true;
  late final String _callname;
  final _emailController = TextEditingController();
  final _passwordControler = TextEditingController();
  late final LoginCubit _loginCubit;
  final authService = getIt<AuthService>();
  final ValidatorService validatorService = getIt<ValidatorService>();
  final Notifier notifier = Notifier();

  @override
  void initState() {
    super.initState();
    // Créer une clé unique pour chaque instance
    _formKey = GlobalKey<FormState>();
    _callname = UserHelper.getRandomCallname();
    _loginCubit = LoginCubit(authService: authService);
  }

  @override
  void dispose() {
    _emailController.dispose();
    _passwordControler.dispose();
    _loginCubit.close();
    super.dispose();
  }

  Future<void> onPressed() async {
    final email = _emailController.text.toLowerCase();
    final password = _passwordControler.text;

    if (!context.mounted) return;

    // Fermer le clavier pour afficher les messages d'erreur
    FocusManager.instance.primaryFocus?.unfocus();

    if (!_formKey.currentState!.validate()) return;

    final l10n = AppLocalizations.of(context);
    await _loginCubit.submit(email, password, l10n);
  }

  Future<bool?> _showBiometricActivationDialog(AppLocalizations? l10n) async {
    if (!context.mounted) return false;

    return showDialog<bool>(
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
    return PopScope(
      canPop: false,
      child: BlocProvider<LoginCubit>.value(
        value: _loginCubit,
        child: BlocListener<LoginCubit, LoginState>(
          listenWhen: (previous, current) =>
              previous.status != current.status ||
              previous.requiresBiometricPrompt !=
                  current.requiresBiometricPrompt,
          listener: (context, state) async {
            if (state.status == AuthSubmissionStatus.success) {
              final l10n = AppLocalizations.of(context);

              if (state.requiresBiometricPrompt) {
                final choice = await _showBiometricActivationDialog(l10n);
                await _loginCubit.completeBiometricPrompt(choice ?? false);
                return;
              }

              if (!context.mounted) return;
              Navigator.of(context).pushReplacement(
                MaterialPageRoute(builder: (_) => const BottomNavbar()),
              );
              _loginCubit.reset();
            }
          },
          child: Scaffold(
            backgroundColor: Colors.grey[200],
            resizeToAvoidBottomInset: true,
            body: SafeArea(
              child: LayoutBuilder(
                builder: (context, constraints) {
                  final bottomInset = MediaQuery.of(context).viewInsets.bottom;
                  final horizontalPadding = _horizontalPadding(constraints.maxWidth);
                  final l10n = AppLocalizations.of(context);
                  final loginState = context.watch<LoginCubit>().state;

                  return SingleChildScrollView(
                    padding: EdgeInsets.fromLTRB(
                      horizontalPadding,
                      24,
                      horizontalPadding,
                      24 + bottomInset,
                    ),
                    child: Center(
                      child: ConstrainedBox(
                        constraints: const BoxConstraints(maxWidth: 480),
                        child: Form(
                          key: _formKey,
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.stretch,
                            children: [
                              const Row(
                                mainAxisAlignment: MainAxisAlignment.end,
                                children: [
                                  LanguageSelectorButton(),
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
                              const SizedBox(height: 24),
                              Text(
                                l10n?.welcomeBack ?? "Content de vous revoir",
                                textAlign: TextAlign.center,
                                style: TextStyle(color: Colors.grey[600], fontSize: 16),
                              ),
                              const SizedBox(height: 8),
                              Text(
                                _callname,
                                textAlign: TextAlign.center,
                                style: GoogleFonts.poppins(
                                  fontSize: 22,
                                  fontWeight: FontWeight.w600,
                                  color: const Color(0xff1f1f39),
                                ),
                              ),
                              const SizedBox(height: 32),
                              IntputTexteField(
                                controller: _emailController,
                                hintText: l10n?.emailAddress ?? "Adresse e-mail",
                                labelText: l10n?.emailAddress ?? "Adresse e-mail",
                                obscureText: false,
                                autofillHints: const [AutofillHints.email],
                                validator: (value) => validatorService.validateEmailAddress(value, context),
                                keyboardType: TextInputType.emailAddress,
                                textInputAction: TextInputAction.next,
                              ),
                              const SizedBox(height: 20),
                              IntputTexteField(
                                controller: _passwordControler,
                                hintText: l10n?.password ?? "Mot de passe",
                                labelText: l10n?.password ?? "Mot de passe",
                                obscureText: _obscurePassword,
                                autofillHints: const [AutofillHints.password],
                                validator: validatorService.noValidation,
                                textInputAction: TextInputAction.done,
                                onSubmitted: onPressed,
                                suffixIcon: Semantics(
                                  button: true,
                                  label: _obscurePassword
                                      ? (l10n?.showPassword ?? 'Afficher le mot de passe')
                                      : (l10n?.hidePassword ?? 'Masquer le mot de passe'),
                                  child: GestureDetector(
                                    onLongPressStart: (_) {
                                      setState(() {
                                        _obscurePassword = false;
                                      });
                                    },
                                    onLongPressEnd: (_) {
                                      setState(() {
                                        _obscurePassword = true;
                                      });
                                    },
                                    child: IconButton(
                                      icon: Icon(
                                        _obscurePassword ? Icons.visibility_outlined : Icons.visibility_off_outlined,
                                        color: Colors.grey[600],
                                      ),
                                      onPressed: () {
                                        setState(() {
                                          _obscurePassword = !_obscurePassword;
                                        });
                                      },
                                    ),
                                  ),
                                ),
                              ),
                              const SizedBox(height: 12),
                              Align(
                                alignment: Alignment.centerRight,
                                child: TextButton(
                                  onPressed: () {},
                                  child: Text(
                                    l10n?.forgotPassword ?? "Mot de passe oublié ?",
                                    style: TextStyle(color: Colors.grey[600]),
                                  ),
                                ),
                              ),
                              const SizedBox(height: 16),
                              AuthButton(
                                text: l10n?.login ?? "Se connecter",
                                onTap: onPressed,
                                isLoading: loginState.isLoading,
                              ),
                              loginState.errorMessage != null
                                   ? Padding(
                                       padding: const EdgeInsets.only(top: 12.0),
                                       child: Text(
                                         loginState.errorMessage!,
                                         textAlign: TextAlign.center,
                                         style: TextStyle(
                                           color: Colors.red[600],
                                           fontSize: 13,
                                           fontWeight: FontWeight.w500,
                                         ),
                                       ),
                                     )
                                   : const SizedBox(height: 8),
                              const SizedBox(height: 20),
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
                                          final localization = AppLocalizations.of(context);
                                          notifier.error(
                                            localization?.biometricAuthFailed ??
                                                'Echec de l\'authentification biométrique',
                                          );
                                        }
                                      },
                                      icon: const Icon(Icons.fingerprint, color: Colors.grey),
                                      label: Text(
                                        l10n?.biometricAuth ?? "Connexion biométrique",
                                        style: const TextStyle(color: Colors.grey),
                                      ),
                                    );
                                  }
                                  return const SizedBox.shrink();
                                },
                              ),
                              const SizedBox(height: 24),
                              Row(
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
                                      style: const TextStyle(color: Colors.grey),
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
                              const SizedBox(height: 24),
                              Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Semantics(
                                    button: true,
                                    label: l10n?.comingSoon ?? 'Fonctionnalité à venir',
                                    child: SquareTile(
                                      imagePath: 'assets/images/google_logo.png',
                                      onTap: () {
                                        notifier.info(l10n?.comingSoon ?? 'Fonctionnalité à venir');
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
                                        notifier.info(l10n?.comingSoon ?? 'Fonctionnalité à venir');
                                      },
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 24),
                              Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Text(
                                    l10n?.noAccount ?? "Vous n'avez pas de compte ?",
                                    style: TextStyle(color: Colors.grey[600]),
                                  ),
                                  const SizedBox(width: 6),
                                  GestureDetector(
                                    onTap: redirectToRegisterPage,
                                    child: Text(
                                      l10n?.signUp ?? "S'inscrire",
                                      style: TextStyle(
                                        color: Colors.red[400],
                                        decoration: TextDecoration.underline,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ],
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
