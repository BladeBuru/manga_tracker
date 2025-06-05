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
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _attemptAutoLogin(context); // ici tu peux passer le context en toute sécurité
    });
  }


  void _attemptAutoLogin(BuildContext context) async {
    // Étape 1 : accessToken valide ?
    final accessToken = await authService.storageService.readSecureData('accessToken');
    if (accessToken != null && !authService.isTokenExpired(accessToken)) {
      _goToApp();
      return;
    }

    // Étape 2 : refreshToken ?
    final refreshed = await authService.refreshAccessToken();
    if (refreshed) {
      _goToApp();
      return;
    }

    // Étape 3 : tentative de login biométrique
    final biometricSuccess = await authService.tryBiometricLogin(context);
    if (biometricSuccess) {
      _goToApp();
      return;
    }
    // Sinon → écran de login
    _goToLogin();
  }

  void _goToApp() {
    Navigator.of(context).pushReplacement(
      MaterialPageRoute(builder: (_) => const BottomNavbar()),
    );
  }

  void _goToLogin() {
    Navigator.of(context).pushReplacement(
      MaterialPageRoute(builder: (_) => const LoginView()),
    );
  }

  @override
  Widget build(BuildContext context) {
    return const Scaffold(
      body: Center(child: CircularProgressIndicator()),
    );
  }
}
