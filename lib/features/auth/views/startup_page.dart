import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:go_router/go_router.dart';
import 'package:mangatracker/core/components/changelog_dialog.dart';
import 'package:mangatracker/core/service_locator/service_locator.dart';
import 'package:mangatracker/core/services/app_update_service.dart';
import 'package:mangatracker/core/services/connectivity_service.dart';
import 'package:mangatracker/core/theme/app_colors.dart';
import 'package:mangatracker/core/theme/app_spacing.dart';
import 'package:mangatracker/features/auth/services/auth.service.dart';
import 'package:mangatracker/l10n/app_localizations.dart';

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
    // 1. Access token encore valide → fast path, pas besoin d'aller plus loin.
    final accessToken = await authService.storageService.readSecureData('accessToken');
    if (accessToken != null && !authService.isTokenExpired(accessToken)) {
      debugPrint('✅ StartupPage: Access token valide, connexion automatique');
      _onLoginSuccess();
      return;
    }

    // 2. Access expiré → on regarde le refresh token.
    final refreshToken = await authService.storageService.readSecureData('refreshToken');
    final isRefreshTokenValid =
        refreshToken != null && !authService.isTokenExpired(refreshToken);

    // 3. Connectivité (par défaut : on suppose connecté si le service n'est pas dispo)
    final isConnected = _connectivityService?.isConnected ?? true;

    if (isRefreshTokenValid) {
      if (isConnected) {
        // En ligne + refresh token valide → on tente le refresh.
        debugPrint('🔄 StartupPage: Tentative de refresh du token...');
        final result = await authService.refreshAccessToken();
        switch (result) {
          case RefreshResult.success:
            debugPrint('✅ StartupPage: Token rafraîchi avec succès');
            _onLoginSuccess();
            return;
          case RefreshResult.networkError:
            // Le réseau a flanché entre le check connectivity et l'appel HTTP,
            // ou le serveur a renvoyé un 5xx transitoire. On tolère et on
            // laisse passer en cache — le prochain appel HTTP retentera.
            debugPrint('⚠️ StartupPage: Refresh impossible (réseau), accès cache toléré');
            _onLoginSuccess();
            return;
          case RefreshResult.rejected:
            // 401/403 explicite du serveur : la session est morte (purge DB,
            // secret JWT changé, etc.). Pas la peine de naviguer dans le cache,
            // l'user n'est PAS authentifié — on purge et on renvoie au login.
            debugPrint('❌ StartupPage: Refresh rejeté par le serveur → logout + login');
            await authService.logout();
            // Avant de pousser vers /login, on tente quand même la biométrie
            // (si l'user l'a configurée, ça lui évite de retaper son mdp).
            await _tryBiometricThenGoToLogin();
            return;
        }
      } else {
        // Hors ligne + refresh token valide localement : on tolère l'accès
        // au cache. Le refresh sera retenté à la reconnexion par http_service.
        debugPrint('📱 StartupPage: Hors ligne, accès cache autorisé');
        _onLoginSuccess();
        return;
      }
    }

    // 4. Pas de refresh token valide → tentative biométrique puis login.
    await _tryBiometricThenGoToLogin();
  }

  /// Essaie la connexion biométrique, sinon redirige vers /login.
  /// Factorisation pour éviter de dupliquer le pattern dans 2 branches.
  Future<void> _tryBiometricThenGoToLogin() async {
    debugPrint('🔐 StartupPage: Tentative de connexion biométrique...');
    final biometricSuccess = await authService.tryBiometricLogin(context);
    if (!mounted) return;
    if (biometricSuccess) {
      debugPrint('✅ StartupPage: Connexion biométrique réussie');
      _onLoginSuccess();
      return;
    }
    debugPrint('⚠️ StartupPage: Aucune méthode d\'authentification → /login');
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
      // Marquer comme vu via `onClose` ET en backup après le `await`.
      // - `onClose` couvre le clic sur « Super ! » (cas nominal).
      // - Le `await` garantit le marquage si le dialog est fermé via le
      //   bouton retour Android (où `onClose` n'est pas déclenché).
      // Sans ce double appel, le dialog se réaffichait à chaque boot.
      await _showChangelogDialog(
        changelogInfo,
        onClose: () => appUpdateService.markChangelogAsSeen(),
      );
      await appUpdateService.markChangelogAsSeen();
    }

    _navigateToHome();
  }

  // --- Fonctions dédiées à l'affichage (UI) ---

  /// Construit et affiche la boîte de dialogue des notes de version.
  Future<void> _showChangelogDialog(
    ChangelogInfo changelogInfo, {
    VoidCallback? onClose,
  }) {
    return ChangelogDialog.show(
      context,
      changelogInfo,
      barrierDismissible: false,
      onClose: onClose,
    );
  }

  /// Construit et affiche la boîte de dialogue de proposition de mise à jour.
  Future<void> _showUpdateDialog() {
    return showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Mise à jour disponible'),
        content: const Text(
          "Une nouvelle version de l'application est disponible.",
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: const Text('Plus tard'),
          ),
          TextButton(
            onPressed: () {
              appUpdateService.downloadAndInstallUpdate();
              Navigator.of(ctx).pop();
            },
            child: const Text('Mettre à jour'),
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
    final brightness = Theme.of(context).brightness;
    final scheme = Theme.of(context).colorScheme;
    final l10n = AppLocalizations.of(context);
    return Scaffold(
      backgroundColor: brightness == Brightness.dark
          ? AppColors.dsBgDark
          : AppColors.dsBgLight,
      body: SafeArea(
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                width: 96,
                height: 96,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: AppColors.dsBgInset(brightness),
                  border: Border.all(
                    color: AppColors.dsHairline(brightness),
                    width: 1,
                  ),
                ),
                clipBehavior: Clip.antiAlias,
                child: Padding(
                  padding: const EdgeInsets.all(10),
                  child: Image.asset(
                    'assets/images/mask_logo.png',
                    semanticLabel: l10n?.appTitle ?? 'MangaTracker',
                    fit: BoxFit.contain,
                  ),
                ),
              ),
              const SizedBox(height: AppSpacing.xl),
              SizedBox(
                width: 28,
                height: 28,
                child: CircularProgressIndicator(
                  strokeWidth: 2.4,
                  color: scheme.primary,
                ),
              ),
              const SizedBox(height: AppSpacing.m),
              Text(
                l10n?.loadingApp ?? 'Chargement…',
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w500,
                  color: AppColors.dsText2(brightness),
                  letterSpacing: 0.2,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}