import 'package:flutter/material.dart';
import 'package:mangatracker/core/service_locator/service_locator.dart';
import 'package:mangatracker/features/auth/services/auth.service.dart';
import 'package:mangatracker/features/auth/views/login.view.dart';
import 'package:mangatracker/features/home/views/bottom_navbar.dart';

class StartupPage extends StatefulWidget {
  const StartupPage({super.key});

  @override
  State<StartupPage> createState() => _StartupPageState();
}

class _StartupPageState extends State<StartupPage> {
  final authService = getIt<AuthService>();

  @override
  void initState() {
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder(
        future: authService.isUserAuthenticated(),
        builder: (context, snapshot) {
          if (snapshot.hasData) {
            if (snapshot.data as bool == true) {
              // User credentials still valid
              return const BottomNavbar();
            } else {
              // User credentials not valid anymore
              return const LoginView();
            }
          }
          return const SizedBox(
            height: 200.0,
            width: 200.0,
            child: Center(
              child: CircularProgressIndicator(),
            ),
          );
        });
  }
}
