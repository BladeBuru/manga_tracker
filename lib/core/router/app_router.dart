/// Router central — `go_router` pour Manga Tracker.
///
/// Architecture :
/// - `/` → StartupPage (restauration de session, biométrie, « Quoi de
///   neuf ? ») puis accueil ou connexion ;
/// - authentification (publique) : `/login`, `/register`,
///   `/forgot-password`, `/auth/verify`, `/auth/reset-password` ;
/// - onglets (`StatefulShellRoute`, une URL par onglet) : `/home`
///   (+ `/home/section/:id`), `/library`, `/search`, `/profile`
///   (+ `/profile/edit`) — cf. `main_shell_route.dart` ;
/// - pages plein écran : `/manga/:muId` (+ `/read`, `/read-offline`),
///   `/authors/:authorId`, `/friends`, `/stats`… — cf. `app_routes.dart`.
///
/// **Web** : URL réelles (`usePathUrlStrategy`, dans `main.dart`), y compris
/// pour les pages empilées (`optionURLReflectsImperativeAPIs`) ; F5, lien
/// partagé et boutons du navigateur rouvrent l'écran affiché. L'historique
/// du navigateur est tenu cohérent par
/// `HistoryAwareRouteInformationProvider`.
/// **Mobile** : comportement inchangé (push / pop natifs).
///
/// Garde d'authentification : [resolveAuthRedirect] (pure), réévaluée à
/// chaque navigation et à la perte de session (`AuthSession.routerRefresh`).
library;

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:mangatracker/core/router/app_routes.dart';
import 'package:mangatracker/core/router/auth_redirect.dart';
import 'package:mangatracker/core/router/main_shell_route.dart';
import 'package:mangatracker/core/router/route_extras_codec.dart';
import 'package:mangatracker/core/router/route_not_found_page.dart';
import 'package:mangatracker/core/service_locator/service_locator.dart';
import 'package:mangatracker/features/auth/services/auth_session.dart';

export 'route_extras.dart';

/// Clé globale du Navigator racine — utilisée par DeepLinkHandler et
/// SystemChrome (overlay style).
final GlobalKey<NavigatorState> rootNavigatorKey = GlobalKey<NavigatorState>();

/// Pages de lecture : plein écran, rien n'y est réservé aux barres système
/// (cf. `SystemBarsInset.enabled`, `ReaderAutoHideBar`).
const Set<String> fullscreenReaderRouteNames = {
  'manga-read',
  'manga-read-offline',
};

/// La page affichée ([route] = `currentConfiguration.lastOrNull?.route`,
/// pages ouvertes par `push` comprises) est-elle un lecteur plein écran ?
bool isFullscreenReaderRoute(RouteBase? route) =>
    route is GoRoute && fullscreenReaderRouteNames.contains(route.name);

/// [session] : session observée par le garde (par défaut celle de GetIt).
/// [initialLocation] : pour les tests (sur le web, l'URL du navigateur
/// prime de toute façon).
GoRouter buildAppRouter({AuthSession? session, String initialLocation = '/'}) {
  final auth = session ??
      (getIt.isRegistered<AuthSession>() ? getIt<AuthSession>() : AuthSession());
  return GoRouter(
    navigatorKey: rootNavigatorKey,
    initialLocation: initialLocation,
    debugLogDiagnostics: false,
    extraCodec: const RouteExtrasCodec(),
    refreshListenable: auth.routerRefresh,
    redirect: (context, state) => resolveAuthRedirect(
      state.uri,
      status: auth.current,
      startupCompleted: auth.startupCompleted,
    ),
    routes: [
      ...buildAuthRoutes(),
      buildMainShellRoute(rootNavigatorKey),
      ...buildDetailRoutes(),
    ],
    errorBuilder: (context, state) => const RouteNotFoundPage(),
  );
}
