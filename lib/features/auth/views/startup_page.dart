import 'package:flutter/material.dart';
import 'package:mangatracker/core/service_locator/service_locator.dart';
import 'package:mangatracker/features/auth/services/auth.service.dart';
import 'package:mangatracker/features/auth/views/login.view.dart';
import 'package:mangatracker/features/home/views/bottom_navbar.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter_markdown/flutter_markdown.dart';


import '../../../core/services/app_update_service.dart';

class StartupPage extends StatefulWidget {
  const StartupPage({super.key});

  @override
  State<StartupPage> createState() => _StartupPageState();
}

class _StartupPageState extends State<StartupPage> {
  // On utilise le bon nom de service pour plus de clarté
  final AuthService authService = getIt<AuthService>();
  final AppUpdateService appUpdateService = getIt<AppUpdateService>();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _attemptAutoLogin();
    });
  }

  Future<void> _attemptAutoLogin() async {
    // La logique d'authentification reste la même
    final accessToken = await authService.storageService.readSecureData('accessToken');
    if (accessToken != null && !authService.isTokenExpired(accessToken)) {
      _onLoginSuccess();
      return;
    }
    final refreshed = await authService.refreshAccessToken();
    if (refreshed) {
      _onLoginSuccess();
      return;
    }
    // Note: `tryBiometricLogin` peut nécessiter un `context`, c'est une exception acceptable.
    final biometricSuccess = await authService.tryBiometricLogin(context);
    if (!mounted) return;
    if (biometricSuccess) {
      _onLoginSuccess();
      return;
    }
    _goToLogin();
  }

  /// Le chef d'orchestre : une logique claire et séquentielle après la connexion.
  Future<void> _onLoginSuccess() async {
    if (kIsWeb) {
      _navigateToHome();
      return;
    }
    // Étape 1 : Gérer le changelog. On attend que ce soit terminé.
    final changelogInfo = await appUpdateService.getNewChangelog();
    if (changelogInfo != null && changelogInfo.isEmpty == false && mounted) {
      await _showChangelogDialog(changelogInfo);
      await appUpdateService.markChangelogAsSeen();
    }

    // Étape 2 : Vérifier si une mise à jour est disponible.
    final updateAvailable = await appUpdateService.isUpdateAvailable();
    if (updateAvailable && mounted) {
      // Si oui, on affiche la proposition. L'utilisateur fait son choix.
      // L'await permet de s'assurer que la dialog est bien fermée avant de continuer.
      await _showUpdateDialog();
    }

    // ÉTAPE FINALE (LA CORRECTION) :
    // Que l'on ait montré une dialog ou non, maintenant que tout est terminé,
    // on navigue vers l'écran d'accueil.
    _navigateToHome();
  }

  // --- Fonctions dédiées à l'affichage (UI) ---

  /// Construit et affiche la boîte de dialogue des notes de version.
  Future<void> _showChangelogDialog(ChangelogInfo changelogInfo) {
    return showDialog(
      context: context,
      barrierDismissible: false, // L'utilisateur doit interagir
      builder: (ctx) => AlertDialog(
        title: const Text("Quoi de neuf ?"),
        content: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: changelogInfo.newVersions.map((changes) {
              return Padding(
                padding: const EdgeInsets.only(bottom: 16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Version ${changes.version}', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                    const SizedBox(height: 8),
                    ...changes.notes.map((note) => MarkdownBody(
                      data: "• $note",
                      styleSheet: MarkdownStyleSheet(p: const TextStyle(fontSize: 14)),
                    )),
                  ],
                ),
              );
            }).toList(),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: const Text("Super !"),
          )
        ],
      ),
    );
  }

  /// Construit et affiche la boîte de dialogue de proposition de mise à jour.
  Future<void> _showUpdateDialog() {
    return showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text("Mise à jour disponible"),
        content: const Text("Une nouvelle version de l'application est disponible."),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(), // On ferme juste la dialog
            child: const Text("Plus tard"),
          ),
          TextButton(
            onPressed: () {
              appUpdateService.downloadAndInstallUpdate();
              Navigator.of(ctx).pop(); // On ferme la dialog
            },
            child: const Text("Mettre à jour"),
          ),
        ],
      ),
    );
  }

  // --- Fonctions de navigation ---

  void _navigateToHome() {
    if (mounted) {
      Navigator.of(context).pushReplacement(
        MaterialPageRoute(builder: (_) => const BottomNavbar()),
      );
    }
  }

  void _goToLogin() {
    if (mounted) {
      Navigator.of(context).pushReplacement(
        MaterialPageRoute(builder: (_) => const LoginView()),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return const Scaffold(
      body: Center(child: CircularProgressIndicator()),
    );
  }
}