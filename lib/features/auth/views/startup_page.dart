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
  bool _biometricTriggered = false;

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<bool>(
      future: authService.isUserAuthenticated(),
      builder: (context, snapshot) {
        if (snapshot.connectionState != ConnectionState.done) {
          return const Scaffold(
            body: Center(child: CircularProgressIndicator()),
          );
        }

        if (!snapshot.hasData || snapshot.data == false) {
          return const LoginView();
        }

        // ✅ Exécuter _checkBiometric uniquement après que le build est fini
        if (!_biometricTriggered) {
          _biometricTriggered = true;
          WidgetsBinding.instance.addPostFrameCallback((_) {
            _checkBiometric();
          });
        }

        return const Scaffold(
          body: Center(child: CircularProgressIndicator()),
        );
      },
    );
  }

  void _checkBiometric() async {
    final token = await authService.getTokenWithBiometric();

    if (token != null && !authService.isTokenExpired(token)) {
      Navigator.of(context).pushReplacement(
        MaterialPageRoute(builder: (context) => const BottomNavbar()),
      );
    } else {
      Navigator.of(context).pushReplacement(
        MaterialPageRoute(builder: (context) => const LoginView()),
      );
    }
  }
}