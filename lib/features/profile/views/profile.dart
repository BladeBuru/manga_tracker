import 'package:flutter/material.dart';
import 'package:fancy_button_flutter/fancy_button_flutter.dart';
import 'package:flutter/services.dart';
import 'package:mangatracker/core/service_locator/service_locator.dart';
import 'package:mangatracker/features/auth/services/auth.service.dart';
import 'package:mangatracker/features/auth/views/login.view.dart';
import 'package:mangatracker/features/profile/services/user.service.dart';

import '../../../core/components/password_fields.dart';
import '../../auth/services/validator.service.dart';

class Profile extends StatefulWidget {
  const Profile({super.key});

  @override
  State<Profile> createState() => _ProfileState();
}

class _ProfileState extends State<Profile> {
  final AuthService authService = getIt<AuthService>();
  final UserService userService = getIt<UserService>();

  final Color logoutBtnColor = Colors.black;
  final Color deleteAccountBtnColor = Colors.red;
  final Color changePasswordBtnColor = Colors.orange;
  final Color buttonTextColor = Colors.white;

  void redirectToLoginPage() {
    HapticFeedback.lightImpact();
    Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => const LoginView()),
    );
  }

  Widget cancelButton() {
    return TextButton(
      child: Text('Annuler'),
      onPressed: () {
        Navigator.of(context).pop();
      },
    );
  }

  Widget fancyButton(icon, text, backgroundColor, textColor, onClick) {
    return FancyButton(
      button_icon: icon,
      button_text: text,
      button_height: 40,
      button_width: 250,
      button_radius: 50,
      button_color: backgroundColor,
      button_outline_color: backgroundColor,
      button_outline_width: 1,
      button_text_color: textColor,
      button_icon_color: textColor,
      icon_size: 22,
      button_text_size: 15,
      onClick: onClick,
    );
  }

  void showConfirmDeleteAccount() {
    Widget continueButton = TextButton(
      style: ButtonStyle(
        backgroundColor: MaterialStateProperty.all<Color>(
          deleteAccountBtnColor,
        ),
      ),
      onPressed: () {
        redirectToLoginPage();
        userService.deleteAccount();
      },
      child: Text('Continuer', style: TextStyle(color: buttonTextColor)),
    );

    AlertDialog alert = AlertDialog(
      title: Text('Supprimer le compte'),
      content: Text(
        'Cette action est irréversible. Toutes vos données seront définitivement supprimées et ne pourront pas être récupérées.',
      ),
      actions: [cancelButton(), continueButton],
    );

    showDialog(context: context, builder: (context) => alert);
  }

  void showConfirmChangePassword() {
    final formKey = GlobalKey<FormState>();
    final passwordControler = TextEditingController();

    Widget saveButton = TextButton(
      style: ButtonStyle(
        backgroundColor: MaterialStateProperty.all<Color>(
          changePasswordBtnColor,
        ),
      ),
      onPressed: () {
        if (!formKey.currentState!.validate()) return;
        userService.changePassword(passwordControler.text);
        Navigator.of(context).pop();
      },
      child: Text('Enregistrer', style: TextStyle(color: buttonTextColor)),
    );

    AlertDialog alert = AlertDialog(
      title: Text('Modifier le mot de passe'),
      content: Form(
        key: formKey,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            PasswordFields(
              passwordControler: passwordControler,
              confirmPasswordControler: TextEditingController(),
              validatorService: getIt<ValidatorService>(),
              update: true,
            ),
          ],
        ),
      ),
      actions: [cancelButton(), saveButton],
    );

    showDialog(context: context, builder: (context) => alert);
  }

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          fancyButton(
            Icons.logout,
            '  Se déconnecter  ',
            logoutBtnColor,
            buttonTextColor,
            () {
              redirectToLoginPage();
              authService.logout();
            },
          ),
          const SizedBox(height: 16),
          fancyButton(
            Icons.delete,
            '  Supprimer le compte  ',
            deleteAccountBtnColor,
            buttonTextColor,
            () {
              showConfirmDeleteAccount();
            },
          ),
          const SizedBox(height: 16),
          fancyButton(
            Icons.password,
            '  Modifier le mot de passe  ',
            changePasswordBtnColor,
            buttonTextColor,
            () {
              showConfirmChangePassword();
            },
          ),
        ],
      ),
    );
  }
}
