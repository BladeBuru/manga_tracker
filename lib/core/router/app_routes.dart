/// Routes de l'application hors onglets (cf. `main_shell_route.dart`).
///
/// Chaque page doit se reconstruire depuis son URL seule (F5, lien direct,
/// retour du navigateur) : les `extra` ne font que pré-remplir l'écran.
library;

import 'package:flutter/widgets.dart';
import 'package:go_router/go_router.dart';
import 'package:mangatracker/core/router/auth_redirect.dart';
import 'package:mangatracker/core/router/route_extras.dart';
import 'package:mangatracker/features/auth/views/forgot_password.view.dart';
import 'package:mangatracker/features/auth/views/login.view.dart';
import 'package:mangatracker/features/auth/views/register.view.dart';
import 'package:mangatracker/features/auth/views/reset_password.view.dart';
import 'package:mangatracker/features/auth/views/startup_page.dart';
import 'package:mangatracker/features/auth/views/verify_email.view.dart';
import 'package:mangatracker/features/authors/views/author_page.dart';
import 'package:mangatracker/features/download/views/downloads_page.dart';
import 'package:mangatracker/features/friends/views/friend_profile_view.dart';
import 'package:mangatracker/features/friends/views/friends_list_page.dart';
import 'package:mangatracker/features/friends/widgets/friends_tab_segmented.dart';
import 'package:mangatracker/features/manga/views/detail_bloc_view.dart';
import 'package:mangatracker/features/manga/views/web_view.dart';
import 'package:mangatracker/features/notifications/views/notifications_page.dart';
import 'package:mangatracker/features/profile/views/change_password.view.dart';
import 'package:mangatracker/features/profile/views/custom_selectors_page.dart';
import 'package:mangatracker/features/profile/views/my_data_view.dart';
import 'package:mangatracker/features/profile/views/notifications_settings_page.dart';
import 'package:mangatracker/features/reader/views/offline_reader_view.dart';
import 'package:mangatracker/features/recommendations/views/paginated_recommendations_view.dart';
import 'package:mangatracker/features/recommendations/views/recommendations_by_genre_view.dart';
import 'package:mangatracker/features/sharing/views/inbox_page.dart';
import 'package:mangatracker/features/sharing/views/reading_group_detail_page.dart';
import 'package:mangatracker/features/sharing/views/reading_groups_list_page.dart';
import 'package:mangatracker/features/stats/views/stats_view.dart';

int _intParam(GoRouterState state, String name) =>
    int.tryParse(state.pathParameters[name] ?? '') ?? 0;

String? _returnTo(GoRouterState state) =>
    state.uri.queryParameters[returnToParam];

/// `/` (démarrage) et pages d'authentification — publiques.
List<RouteBase> buildAuthRoutes() => [
      // StartupPage gère la restauration de session puis remplace l'entrée.
      GoRoute(
        path: '/',
        name: 'root',
        builder: (context, state) => const StartupPage(),
      ),
      GoRoute(
        path: '/login',
        name: 'login',
        builder: (context, state) => LoginView(returnTo: _returnTo(state)),
      ),
      GoRoute(
        path: '/register',
        name: 'register',
        builder: (context, state) => RegisterView(
          emailText: state.uri.queryParameters['email'] ?? '',
          returnTo: _returnTo(state),
        ),
      ),
      GoRoute(
        path: '/forgot-password',
        name: 'forgot-password',
        builder: (context, state) => const ForgotPasswordView(),
      ),
      // Liens reçus par email (jeton en paramètre).
      GoRoute(
        path: '/auth/verify',
        name: 'auth-verify',
        builder: (context, state) =>
            VerifyEmailView(token: state.uri.queryParameters['token'] ?? ''),
      ),
      GoRoute(
        path: '/auth/reset-password',
        name: 'auth-reset-password',
        builder: (context, state) =>
            ResetPasswordView(token: state.uri.queryParameters['token'] ?? ''),
      ),
    ];

/// Pages plein écran ouvertes par-dessus les onglets.
List<RouteBase> buildDetailRoutes() => [
      // Auteurs — mini bio + œuvres (noms cliquables de la fiche manga).
      GoRoute(
        path: '/authors/:authorId',
        name: 'author',
        builder: (context, state) => AuthorPage(
          authorId: _intParam(state, 'authorId'),
          initialName: (state.extra as AuthorPageExtras?)?.name,
        ),
      ),
      GoRoute(
        path: '/manga/:muId',
        name: 'manga-detail',
        builder: (context, state) {
          final extras = state.extra as MangaDetailExtras?;
          return DetailBlocView(
            muId: _intParam(state, 'muId'),
            mangaTitle: extras?.title,
            coverPath: extras?.coverPath,
          );
        },
        routes: [
          // Lecteur WebView (mobile) ; sur web, stub « ouvrir dans un
          // onglet » (web_view_web.dart).
          GoRoute(
            path: 'read',
            name: 'manga-read',
            builder: (context, state) {
              final muId = _intParam(state, 'muId');
              final extras = state.extra as ReaderWebExtras?;
              // F5 / lien direct : extras non sérialisables → fiche manga.
              if (extras == null) return DetailBlocView(muId: muId);
              return ReaderWebView(
                muId: muId,
                mangaTitle: extras.mangaTitle,
                initialLastRead: extras.initialLastRead,
                initialUrl: extras.initialUrl,
                baseUserLink: extras.baseUserLink,
                initialPositionPercent: extras.initialPositionPercent,
                autoDownload: extras.autoDownload,
                onDownloadComplete: extras.onDownloadComplete,
                linkDiscovery: extras.linkDiscovery,
              );
            },
          ),
          // /manga/:muId/read-offline?chapter=N — lecteur hors ligne.
          GoRoute(
            path: 'read-offline',
            name: 'manga-read-offline',
            builder: (context, state) => OfflineReaderView(
              muId: _intParam(state, 'muId'),
              chapterNumber:
                  int.tryParse(state.uri.queryParameters['chapter'] ?? '') ??
                      1,
              mangaTitle:
                  (state.extra as OfflineReaderExtras?)?.mangaTitle ?? '',
            ),
          ),
        ],
      ),
      _page('/downloads', 'downloads', const DownloadsPage()),
      _page(
        '/notifications-settings',
        'notifications-settings',
        const NotificationsSettingsPage(),
      ),
      // Centre de notifications — ouvert par la cloche de l'accueil.
      _page('/notifications', 'notifications', const NotificationsPage()),
      _page('/my-data', 'my-data', const MyDataView()),
      _page('/change-password', 'change-password', const ChangePasswordView()),
      _page('/custom-selectors', 'custom-selectors', const CustomSelectorsPage()),
      _page(
        '/recommendations',
        'recommendations',
        const PaginatedRecommendationsView(),
      ),
      _page(
        '/recommendations/by-genre',
        'recommendations-by-genre',
        const RecommendationsByGenreView(),
      ),
      _page('/stats', 'stats', const StatsView()),
      // `?tab=pending` : arrivée depuis une pastille / une notification.
      GoRoute(
        path: '/friends',
        name: 'friends',
        builder: (context, state) => FriendsListPage(
          initialTab: state.uri.queryParameters['tab'] == 'pending'
              ? FriendsTab.pending
              : FriendsTab.accepted,
        ),
      ),
      // Profil d'un ami : sa bibliothèque (amitié acceptée requise côté API).
      // Sans extra (lien direct), la page retrouve le nom de l'ami.
      GoRoute(
        path: '/friends/:userId',
        name: 'friend-profile',
        builder: (context, state) {
          final extras = state.extra as FriendProfileExtras?;
          return FriendProfileView(
            friendUserId: _intParam(state, 'userId'),
            displayName: extras?.displayName,
            avatarUrl: extras?.avatarUrl,
          );
        },
      ),
      _page('/inbox', 'inbox', const InboxPage()),
      _page(
        '/reading-groups',
        'reading-groups',
        const ReadingGroupsListPage(),
      ),
      GoRoute(
        path: '/reading-groups/:groupId',
        name: 'reading-group-detail',
        builder: (context, state) =>
            ReadingGroupDetailPage(groupId: _intParam(state, 'groupId')),
      ),
    ];

GoRoute _page(String path, String name, Widget page) =>
    GoRoute(path: path, name: name, builder: (context, state) => page);
