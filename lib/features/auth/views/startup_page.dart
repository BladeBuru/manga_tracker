import 'package:flutter/material.dart';
import 'package:mangatracker/core/service_locator/service_locator.dart';
import 'package:mangatracker/features/auth/services/auth.service.dart';
import 'package:mangatracker/features/auth/views/login.view.dart';
import 'package:mangatracker/features/home/views/bottom_navbar.dart';
import '../../../core/services/version_checker.dart';
import 'package:flutter/foundation.dart' show kIsWeb;

class StartupPage extends StatefulWidget {
  const StartupPage({super.key});

  @override
  State<StartupPage> createState() => _StartupPageState();
}

class _StartupPageState extends State<StartupPage> {
  final authService = getIt<AuthService>();
  final versionChecker = getIt<VersionCheckerService>();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _attemptAutoLogin(context);
    });
  }


  void _attemptAutoLogin(BuildContext context) async {
    final accessToken = await authService.storageService.readSecureData('accessToken');
    if (accessToken != null && !authService.isTokenExpired(accessToken)) {
      _goToApp();
      return;
    }
    final refreshed = await authService.refreshAccessToken();
    if (refreshed) {
      _goToApp();
      return;
    }
    final biometricSuccess = await authService.tryBiometricLogin(context);
    if (biometricSuccess) {
      _goToApp();
      return;
    }
    _goToLogin();
  }

  void _goToApp() async {
    if (kIsWeb) {
      _navigateToHome(); // On va directement à l'écran d'accueil
      return;
    }

    final updateAvailable = await versionChecker.isUpdateAvailable();

    if (updateAvailable) {
      if (!mounted) return;
      showDialog(
        context: context,
        builder: (_) => AlertDialog(
          title: const Text("Mise à jour disponible"),
          content: const Text("Une nouvelle version de l'application est disponible."),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
                _navigateToHome();
              },
              child: const Text("Plus tard"),
            ),
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
                versionChecker.downloadAndInstallApk(); // Lance la MAJ en arrière-plan
                _navigateToHome();
              },
              child: const Text("Mettre à jour"),
            ),
          ],
        ),
      );
      return;
    }

    _navigateToHome();
  }

  void _navigateToHome() {
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