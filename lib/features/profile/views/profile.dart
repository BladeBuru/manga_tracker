import 'package:flutter/material.dart';
import 'package:fancy_button_flutter/fancy_button_flutter.dart';
import 'package:flutter/services.dart';
import 'package:mangatracker/core/service_locator/service_locator.dart';
import 'package:mangatracker/features/auth/services/auth.service.dart';
import 'package:mangatracker/features/auth/views/login.view.dart';

class Profile extends StatefulWidget {
  const Profile({super.key});

  @override
  State<Profile> createState() => _ProfileState();
}

class _ProfileState extends State<Profile> {
  Color logoutBtnColor = Colors.black;
  Color logoutBtnTextColor = Colors.white;
  AuthService authService = getIt<AuthService>();

  void redirectToLoginPage() {
    HapticFeedback.lightImpact();
    Navigator.push(
        context, MaterialPageRoute(builder: (context) => const LoginView()));
  }

  @override
  Widget build(BuildContext context) {
    return Center(
        child: FancyButton(
            button_icon: Icons.logout,
            button_text: "  Logout  ",
            button_height: 40,
            button_width: 150,
            button_radius: 50,
            button_color: logoutBtnColor,
            button_outline_color: logoutBtnColor,
            button_outline_width: 1,
            button_text_color: logoutBtnTextColor,
            button_icon_color: logoutBtnTextColor,
            icon_size: 22,
            button_text_size: 15,
            onClick: () {
              setState(() {
                logoutBtnColor = Colors.white;
                logoutBtnTextColor = Colors.black;

                redirectToLoginPage();
                authService.logout();
              });
            }));
  }
}
