import 'package:flutter/widgets.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:mangatracker/core/router/route_extras.dart';
import 'package:mangatracker/core/service_locator/service_locator.dart';
import 'package:mangatracker/features/home/bloc/homepage_bloc.dart';
import 'package:mangatracker/features/home/views/bottom_navbar.dart';
import 'package:mangatracker/features/home/views/home_section_page.dart';
import 'package:mangatracker/features/home/views/homepage_bloc_view.dart';
import 'package:mangatracker/features/home/views/main_tab.dart';
import 'package:mangatracker/features/home/views/main_tabs_pager.dart';
import 'package:mangatracker/features/library/bloc/library_bloc.dart';
import 'package:mangatracker/features/library/views/library_bloc_view.dart';
import 'package:mangatracker/features/profile/dto/user_information.dto.dart';
import 'package:mangatracker/features/profile/views/profile.dart';
import 'package:mangatracker/features/profile/views/profile_edit_loader.dart';
import 'package:mangatracker/features/search/views/search.dart';

/// Onglets principaux : une branche (et une URL) par onglet.
///
/// Les sous-pages d'un onglet (`/home/section/:id`, `/profile/edit`)
/// s'ouvrent en plein écran par-dessus la barre ([rootNavigatorKey]), comme
/// avant ; ouvertes par lien direct, l'onglet est reconstruit dessous — la
/// flèche retour y ramène.
StatefulShellRoute buildMainShellRoute(GlobalKey<NavigatorState> rootNavigatorKey) {
  return StatefulShellRoute(
    builder: (context, state, navigationShell) =>
        BottomNavbar(navigationShell: navigationShell),
    navigatorContainerBuilder: (context, navigationShell, children) =>
        MainTabsPager(shell: navigationShell, children: children),
    branches: [
      StatefulShellBranch(routes: [
        GoRoute(
          path: MainTab.home.path,
          name: 'home',
          // `.value` : ces BLoCs sont des singletons GetIt. Avec `create`,
          // le provider en devenait propriétaire et les fermait.
          builder: (context, state) => BlocProvider<HomePageBloc>.value(
            value: getIt<HomePageBloc>(),
            child: const HomePageBlocView(),
          ),
          routes: [
            // Page « Tout voir » d'une section de l'accueil catalogue.
            // L'id est encodé côté appelant (`type%3AManhwa`).
            GoRoute(
              path: 'section/:id',
              name: 'home-section',
              parentNavigatorKey: rootNavigatorKey,
              builder: (context, state) => HomeSectionPage(
                sectionId: state.pathParameters['id'] ?? '',
                extras: state.extra as HomeSectionExtras?,
              ),
            ),
          ],
        ),
      ]),
      StatefulShellBranch(routes: [
        GoRoute(
          path: MainTab.library.path,
          name: 'library',
          builder: (context, state) => BlocProvider<LibraryBloc>.value(
            value: getIt<LibraryBloc>(),
            child: const LibraryBlocView(),
          ),
        ),
      ]),
      StatefulShellBranch(routes: [
        GoRoute(
          path: MainTab.search.path,
          name: 'search',
          builder: (context, state) => const Search(),
        ),
      ]),
      StatefulShellBranch(routes: [
        GoRoute(
          path: MainTab.profile.path,
          name: 'profile',
          builder: (context, state) => Profile(
            focusPendingRequests: MainShellScope.profileFocusRequestsOf(context),
          ),
          routes: [
            // Formulaire d'édition : sans extra (lien direct, F5), le profil
            // est rechargé au lieu d'un écran « données manquantes ».
            GoRoute(
              path: 'edit',
              name: 'profile-edit',
              parentNavigatorKey: rootNavigatorKey,
              builder: (context, state) => ProfileEditLoader(
                initialUser: state.extra as UserInformationDto?,
              ),
            ),
          ],
        ),
      ]),
    ],
  );
}
