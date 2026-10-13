import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:go_router/go_router.dart';
import 'package:mangatracker/core/router/app_router.dart';
import 'package:mangatracker/core/router/auth_redirect.dart';
import 'package:mangatracker/core/router/navigation_helpers.dart';
import 'package:mangatracker/core/router/web_history/history_aware_route_information_provider.dart';
import 'package:mangatracker/core/service_locator/service_locator.dart';
import 'package:mangatracker/features/auth/services/auth.service.dart';
import 'package:mangatracker/features/auth/services/auth_session.dart';

/// Navigations des transitions d'authentification.
///
/// Toutes REMPLACENT l'entrée d'historique du navigateur : ni `/`, ni
/// `/login` ne restent derrière l'application, et après une déconnexion le
/// bouton retour ne rouvre aucune page de l'app (le garde les renvoie, en
/// remplaçant, vers la connexion).
abstract final class AuthNavigation {
  /// Fin de `StartupPage` : accueil (ou connexion), sans laisser `/`.
  static void finishStartup(BuildContext context, String location) {
    if (getIt.isRegistered<AuthSession>()) {
      getIt<AuthSession>().markStartupCompleted();
    }
    goReplacing(context, location);
  }

  /// Après une connexion réussie : la page demandée avant la connexion
  /// ([returnTo], validée — chemin interne uniquement), sinon l'accueil.
  ///
  /// Sur le web, les pages d'authentification empilées (connexion →
  /// inscription) sont d'abord dépilées — vrai retour arrière du navigateur
  /// — pour que la destination remplace l'entrée de la connexion elle-même.
  static Future<void> completeSignIn(
    BuildContext context, {
    String? returnTo,
  }) async {
    final target = safeReturnPath(returnTo) ?? homeLocation;
    if (getIt.isRegistered<AuthSession>()) getIt<AuthSession>().markSignedIn();
    final router = GoRouter.of(context);
    if (kIsWeb && router.canPop()) {
      while (router.canPop()) {
        router.pop();
      }
      // Le retour est signalé au navigateur en fin d'image, puis traité par
      // lui de façon asynchrone.
      await WidgetsBinding.instance.endOfFrame;
      await HistoryAwareRouteInformationProvider.settled();
    }
    final rootContext = rootNavigatorKey.currentContext;
    if (rootContext == null || !rootContext.mounted) return;
    goReplacing(rootContext, target);
  }

  /// Déconnexion **explicite** (purge du cache comprise, cf.
  /// `AuthService.logout`) puis retour à la connexion.
  ///
  /// Ne dépend pas du widget appelant : la perte de session retire déjà
  /// l'application de l'écran (garde du routeur).
  static Future<void> signOut([AuthService? authService]) async {
    await (authService ?? getIt<AuthService>()).logout();
    final rootContext = rootNavigatorKey.currentContext;
    if (rootContext == null || !rootContext.mounted) return;
    goReplacing(rootContext, '/login');
  }
}
