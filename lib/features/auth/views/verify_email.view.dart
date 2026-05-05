import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:mangatracker/core/service_locator/service_locator.dart';
import 'package:mangatracker/features/auth/services/auth.service.dart';
import 'package:mangatracker/features/auth/services/email_auth.service.dart';
import 'package:mangatracker/features/home/bloc/homepage_bloc.dart';
import 'package:mangatracker/features/home/bloc/homepage_event.dart';
import 'package:mangatracker/features/profile/services/user.service.dart';
import 'package:mangatracker/l10n/app_localizations.dart';

/// Vue intermédiaire qui consomme le token reçu dans le mail de
/// vérification, persiste les JWT auto-login retournés et redirige vers
/// la home.
///
/// Atteignable via deep link : `https://bladeburu.com/auth/verify?token=XXX`
/// → l'app intercepte (App Links Android) et navigue ici avec le token.
///
/// L'écran a 3 états :
///  - chargement (vérification en cours)
///  - succès (redirection auto vers BottomNavbar)
///  - erreur (token invalide → bouton « Renvoyer le mail »)
class VerifyEmailView extends StatefulWidget {
  /// Token brut reçu dans le lien email (64 hex chars).
  final String token;

  const VerifyEmailView({super.key, required this.token});

  @override
  State<VerifyEmailView> createState() => _VerifyEmailViewState();
}

class _VerifyEmailViewState extends State<VerifyEmailView> {
  late Future<bool> _verifyFuture;

  @override
  void initState() {
    super.initState();
    _verifyFuture = _verify();
  }

  Future<bool> _verify() async {
    try {
      final emailAuth = getIt<EmailAuthService>();
      final auth = getIt<AuthService>();
      final tokens = await emailAuth.verifyEmail(widget.token);
      await auth.persistTokens(
        accessToken: tokens.accessToken,
        refreshToken: tokens.refreshToken,
      );
      // L'API a flippé `emailVerifiedAt` côté serveur. Force un fetch réseau
      // (forceRefresh) pour que `UserInformationDto.emailVerified` soit
      // à jour. Sans `forceRefresh`, le cache 7j retournait l'ancienne valeur
      // et la banner « Vérifiez votre email » restait affichée.
      try {
        final userService = getIt<UserService>();
        await userService.getUserInformation(forceRefresh: true);
      } catch (_) {
        // Erreur réseau silencieuse : si le refetch échoue, la HomePage
        // refera l'appel à son tour. Le succès de la vérif n'en dépend pas.
      }
      // Rafraîchir le HomePageBloc s'il est déjà instancié (lazy singleton),
      // pour que la banner de vérif disparaisse immédiatement à l'arrivée
      // sur la home.
      try {
        if (getIt.isRegistered<HomePageBloc>()) {
          getIt<HomePageBloc>().add(const RefreshHomePage());
        }
      } catch (_) {}
      return true;
    } on InvalidEmailTokenException {
      return false;
    } catch (e) {
      return false;
    }
  }

  void _goHome() {
    context.go('/home');
  }

  void _goLogin() {
    context.go('/login');
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return Scaffold(
      body: SafeArea(
        child: FutureBuilder<bool>(
          future: _verifyFuture,
          builder: (context, snapshot) {
            if (snapshot.connectionState != ConnectionState.done) {
              return _buildLoading(l10n);
            }
            if (snapshot.data == true) {
              // Redirection auto après un court délai (le user voit le check)
              WidgetsBinding.instance.addPostFrameCallback((_) {
                Future.delayed(const Duration(milliseconds: 800), _goHome);
              });
              return _buildSuccess(l10n);
            }
            return _buildError(l10n);
          },
        ),
      ),
    );
  }

  Widget _buildConstrained({required Widget child}) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final horizontalPadding = constraints.maxWidth >= 600 ? 24.0 : 16.0;
        return Padding(
          padding: EdgeInsets.symmetric(horizontal: horizontalPadding, vertical: 24),
          child: Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 480),
              child: child,
            ),
          ),
        );
      },
    );
  }

  Widget _buildLoading(AppLocalizations? l10n) {
    return _buildConstrained(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const CircularProgressIndicator(),
          const SizedBox(height: 24),
          Text(
            l10n?.verifyingEmail ?? 'Vérification en cours…',
            style: Theme.of(context).textTheme.bodyMedium,
          ),
        ],
      ),
    );
  }

  Widget _buildSuccess(AppLocalizations? l10n) {
    return _buildConstrained(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.check_circle_outline,
            size: 72,
            color: Theme.of(context).colorScheme.primary,
          ),
          const SizedBox(height: 24),
          Text(
            l10n?.emailVerifiedSuccess ?? 'Email vérifié !',
            style: Theme.of(context).textTheme.headlineSmall,
          ),
          const SizedBox(height: 8),
          Text(
            l10n?.emailVerifiedHint ?? 'Connexion en cours…',
            style: Theme.of(context)
                .textTheme
                .bodyMedium
                ?.copyWith(color: Colors.grey[700]),
          ),
        ],
      ),
    );
  }

  Widget _buildError(AppLocalizations? l10n) {
    return _buildConstrained(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.error_outline, size: 72, color: Colors.red[400]),
          const SizedBox(height: 24),
          Text(
            l10n?.emailVerifyFailedTitle ?? 'Lien invalide ou expiré',
            style: Theme.of(context).textTheme.headlineSmall,
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 12),
          Text(
            l10n?.emailVerifyFailedHint ??
                'Le lien que vous avez utilisé n\'est plus valide. Connectez-vous et demandez un nouveau lien depuis votre profil.',
            textAlign: TextAlign.center,
            style: Theme.of(context)
                .textTheme
                .bodyMedium
                ?.copyWith(color: Colors.grey[700]),
          ),
          const SizedBox(height: 32),
          OutlinedButton(
            onPressed: _goLogin,
            child: Text(l10n?.backToLogin ?? 'Retour à la connexion'),
          ),
        ],
      ),
    );
  }
}
