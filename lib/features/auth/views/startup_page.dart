import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:go_router/go_router.dart';
import 'package:mangatracker/core/service_locator/service_locator.dart';
import 'package:mangatracker/features/auth/services/auth.service.dart';

import '../../../core/services/app_update_service.dart';
import '../../../core/services/connectivity_service.dart';
import '../../../core/components/changelog_dialog.dart';

class StartupPage extends StatefulWidget {
  const StartupPage({super.key});

  @override
  State<StartupPage> createState() => _StartupPageState();
}

class _StartupPageState extends State<StartupPage> {
  // On utilise le bon nom de service pour plus de clarté
  final AuthService authService = getIt<AuthService>();
  final AppUpdateService appUpdateService = getIt<AppUpdateService>();
  ConnectivityService? _connectivityService;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _initializeAndAttemptLogin();
    });
  }

  Future<void> _initializeAndAttemptLogin() async {
    // Initialiser le service de connectivité si disponible
    try {
      _connectivityService = getIt<ConnectivityService>();
    } catch (e) {
      debugPrint('⚠️ StartupPage: ConnectivityService non disponible: $e');
    }

    // PRIORITÉ ABSOLUE : vérifier les mises à jour AVANT toute tentative
    // d'authentification. Si l'auth est cassée par un bug (ex: l'API n'est
    // pas joignable, ou un fix est attendu côté serveur), l'utilisateur
    // doit toujours pouvoir installer la nouvelle version. Sans cette
    // vérif au boot, l'utilisateur reste bloqué sur la version buggée.
    if (!kIsWeb) {
      await _checkForUpdateBeforeAuth();
    }
    if (!mounted) return;

    await _attemptAutoLogin();
  }

  /// Vérifie l'update GitHub Releases et propose la maj si dispo.
  /// Indépendant du flow d'auth : tourne au boot pour ne jamais bloquer
  /// l'utilisateur sur une version buggée.
  Future<void> _checkForUpdateBeforeAuth() async {
    try {
      final updateAvailable = await appUpdateService.isUpdateAvailable();
      if (updateAvailable && mounted) {
        await _showUpdateDialog();
      }
    } catch (e) {
      // Pas grave : si la vérif update échoue (offline, GH Pages down,
      // etc.), on ne bloque pas le boot — on tente l'auto-login.
      debugPrint('⚠️ StartupPage: vérif update au boot échouée : $e');
    }
  }

  Future<void> _attemptAutoLogin() async {
    // 1. Vérifier si l'access token est valide
    final accessToken = await authService.storageService.readSecureData('accessToken');
    if (accessToken != null && !authService.isTokenExpired(accessToken)) {
      debugPrint('✅ StartupPage: Access token valide, connexion automatique');
      _onLoginSuccess();
      return;
    }

    // 2. Vérifier si le refresh token est valide
    final refreshToken = await authService.storageService.readSecureData('refreshToken');
    final isRefreshTokenValid = refreshToken != null && !authService.isTokenExpired(refreshToken);
    
    // 3. Vérifier la connectivité
    final isConnected = _connectivityService?.isConnected ?? true; // Par défaut, supposer connecté
    
    if (isRefreshTokenValid) {
      if (isConnected) {
        // Tentative de refresh si connecté
        debugPrint('🔄 StartupPage: Tentative de refresh du token...');
        final refreshed = await authService.refreshAccessToken();
        if (refreshed) {
          debugPrint('✅ StartupPage: Token rafraîchi avec succès');
          _onLoginSuccess();
          return;
        } else {
          // Le refresh a échoué mais le refreshToken est toujours valide
          // Permettre l'accès en mode hors ligne (le token sera rafraîchi plus tard)
          debugPrint('⚠️ StartupPage: Échec du refresh mais refreshToken valide, accès autorisé en mode hors ligne');
          debugPrint('   Le token sera rafraîchi automatiquement à la reconnexion');
          _onLoginSuccess();
          return;
        }
      } else {
        // Mode hors ligne avec refreshToken valide : permettre l'accès
        debugPrint('📱 StartupPage: Mode hors ligne avec refreshToken valide, accès autorisé');
        debugPrint('   Le token sera rafraîchi automatiquement à la reconnexion');
        _onLoginSuccess();
        return;
      }
    }

    // 4. Tentative de connexion biométrique
    debugPrint('🔐 StartupPage: Tentative de connexion biométrique...');
    final biometricSuccess = await authService.tryBiometricLogin(context);
    if (!mounted) return;
    if (biometricSuccess) {
      debugPrint('✅ StartupPage: Connexion biométrique réussie');
      _onLoginSuccess();
      return;
    } else {
      debugPrint('⚠️ StartupPage: Échec de la connexion biométrique');
    }
    
    // 5. Aucune méthode d'authentification disponible
    debugPrint('⚠️ StartupPage: Aucune méthode d\'authentification disponible');
    _goToLogin();
  }

  /// Le chef d'orchestre : une logique claire et séquentielle après la connexion.
  ///
  /// Note : la vérification des mises à jour (`isUpdateAvailable`) est faite
  /// AU BOOT (`_checkForUpdateBeforeAuth`), AVANT toute tentative d'auth,
  /// pour ne pas bloquer l'utilisateur si l'auth est cassée. Ici on ne fait
  /// plus que le changelog post-update (état "Quoi de neuf ?").
  Future<void> _onLoginSuccess() async {
    if (kIsWeb) {
      _navigateToHome();
      return;
    }
    // Affichage du changelog si nouvelle version installée depuis le dernier login.
    final changelogInfo = await appUpdateService.getNewChangelog();
    if (changelogInfo != null && changelogInfo.isEmpty == false && mounted) {
      await _showChangelogDialog(changelogInfo);
      await appUpdateService.markChangelogAsSeen();
    }

    _navigateToHome();
  }

  // --- Fonctions dédiées à l'affichage (UI) ---

  /// Construit et affiche la boîte de dialogue des notes de version.
  Future<void> _showChangelogDialog(ChangelogInfo changelogInfo) {
    return ChangelogDialog.show(
      context,
      changelogInfo,
      barrierDismissible: false,
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
      context.go('/home');
    }
  }

  void _goToLogin() {
    if (mounted) {
      context.go('/login');
    }
  }

  @override
  Widget build(BuildContext context) {
    return const Scaffold(
      body: Center(child: CircularProgressIndicator()),
    );
  }
}