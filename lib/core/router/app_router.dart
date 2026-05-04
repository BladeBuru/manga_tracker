/// Router central — `go_router` pour Manga Tracker.
///
/// Migration depuis MaterialPageRoute pour permettre le **deep-linking web**
/// (URL stable par écran : `/manga/:muId`, partageable et bookmarkable).
///
/// Architecture :
/// - `/` → StartupPage (auto-login + redirect)
/// - Auth public : `/login`, `/register`, `/forgot-password`
/// - Auth deep-link : `/auth/verify`, `/auth/reset-password`
/// - Shell principal : `/home` (BottomNavbar avec PageView interne — 4 tabs)
/// - Routes manga : `/manga/:muId`, `/manga/:muId/read`, `/manga/:muId/read-offline`
/// - Profile sub-routes : `/downloads`, `/notifications-settings`,
///   `/my-data`, `/custom-selectors`
///
/// Sur **web**, l'URL reflète l'écran (F5, partage, bouton back marchent).
/// Sur **mobile**, comportement inchangé (push/replace/pop natifs).
library;

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

// Auth views
import 'package:mangatracker/features/auth/views/forgot_password.view.dart';
import 'package:mangatracker/features/auth/views/login.view.dart';
import 'package:mangatracker/features/auth/views/register.view.dart';
import 'package:mangatracker/features/auth/views/reset_password.view.dart';
import 'package:mangatracker/features/auth/views/startup_page.dart';
import 'package:mangatracker/features/auth/views/verify_email.view.dart';

// Shell
import 'package:mangatracker/features/home/views/bottom_navbar.dart';

// Manga
import 'package:mangatracker/features/manga/views/detail_bloc_view.dart';
import 'package:mangatracker/features/manga/views/web_view.dart';
import 'package:mangatracker/features/reader/views/offline_reader_view.dart';

// Profile sub-routes
import 'package:mangatracker/features/download/views/downloads_page.dart';
import 'package:mangatracker/features/profile/views/my_data_view.dart';
import 'package:mangatracker/features/profile/views/notifications_settings_page.dart';
import 'package:mangatracker/features/profile/views/custom_selectors_page.dart';

/// Clé globale du Navigator racine — utilisée par DeepLinkHandler et
/// SystemChrome (overlay style).
final GlobalKey<NavigatorState> rootNavigatorKey = GlobalKey<NavigatorState>();

/// Extras passés via `context.push('/manga/:muId', extra: ...)` — purement
/// pour pré-remplir l'UI avant que le BLoC charge les vraies données.
class MangaDetailExtras {
  final String? title;
  final String? coverPath;
  const MangaDetailExtras({this.title, this.coverPath});
}

/// Extras passés via `context.push('/manga/:muId/read', extra: ...)`.
class ReaderWebExtras {
  final String? mangaTitle;
  final int initialLastRead;
  final String initialUrl;
  final String baseUserLink;
  final bool autoDownload;
  final void Function(bool)? onDownloadComplete;
  const ReaderWebExtras({
    this.mangaTitle,
    required this.initialLastRead,
    required this.initialUrl,
    required this.baseUserLink,
    this.autoDownload = false,
    this.onDownloadComplete,
  });
}

/// Extras passés via `context.push('/manga/:muId/read-offline', extra: ...)`.
class OfflineReaderExtras {
  final String mangaTitle;
  const OfflineReaderExtras({required this.mangaTitle});
}

/// Helpers pour parser les path params (avec fallback safe).
int _parseMuId(String? raw) => int.tryParse(raw ?? '') ?? 0;

GoRouter buildAppRouter() {
  return GoRouter(
    navigatorKey: rootNavigatorKey,
    initialLocation: '/',
    debugLogDiagnostics: false,
    routes: [
      // ──────────────────────────────────────────────────────────────
      // Root — StartupPage gère la redirection vers /login ou /home
      // ──────────────────────────────────────────────────────────────
      GoRoute(
        path: '/',
        name: 'root',
        builder: (context, state) => const StartupPage(),
      ),

      // ──────────────────────────────────────────────────────────────
      // Auth public
      // ──────────────────────────────────────────────────────────────
      GoRoute(
        path: '/login',
        name: 'login',
        builder: (context, state) => const LoginView(),
      ),
      GoRoute(
        path: '/register',
        name: 'register',
        builder: (context, state) {
          final emailText = state.uri.queryParameters['email'] ?? '';
          return RegisterView(emailText: emailText);
        },
      ),
      GoRoute(
        path: '/forgot-password',
        name: 'forgot-password',
        builder: (context, state) => const ForgotPasswordView(),
      ),

      // ──────────────────────────────────────────────────────────────
      // Auth deep-link (token via query param)
      // ──────────────────────────────────────────────────────────────
      GoRoute(
        path: '/auth/verify',
        name: 'auth-verify',
        builder: (context, state) {
          final token = state.uri.queryParameters['token'] ?? '';
          return VerifyEmailView(token: token);
        },
      ),
      GoRoute(
        path: '/auth/reset-password',
        name: 'auth-reset-password',
        builder: (context, state) {
          final token = state.uri.queryParameters['token'] ?? '';
          return ResetPasswordView(token: token);
        },
      ),

      // ──────────────────────────────────────────────────────────────
      // Shell principal — BottomNavbar avec PageView interne
      // (4 tabs : Home / Library / Search / Profile)
      // ──────────────────────────────────────────────────────────────
      GoRoute(
        path: '/home',
        name: 'home',
        builder: (context, state) => const BottomNavbar(),
      ),

      // ──────────────────────────────────────────────────────────────
      // Manga
      // ──────────────────────────────────────────────────────────────
      GoRoute(
        path: '/manga/:muId',
        name: 'manga-detail',
        builder: (context, state) {
          final muId = _parseMuId(state.pathParameters['muId']);
          final extras = state.extra as MangaDetailExtras?;
          return DetailBlocView(
            muId: muId,
            mangaTitle: extras?.title,
            coverPath: extras?.coverPath,
          );
        },
        routes: [
          // /manga/:muId/read — webview de lecture (mobile complet, web =
          // bouton "ouvrir dans un onglet" via stub web_view_web.dart)
          GoRoute(
            path: 'read',
            name: 'manga-read',
            builder: (context, state) {
              final muId = _parseMuId(state.pathParameters['muId']);
              final extras = state.extra as ReaderWebExtras?;
              if (extras == null) {
                // F5 sur cette URL sans extras — fallback vers la fiche manga
                return DetailBlocView(muId: muId);
              }
              return ReaderWebView(
                muId: muId,
                mangaTitle: extras.mangaTitle,
                initialLastRead: extras.initialLastRead,
                initialUrl: extras.initialUrl,
                baseUserLink: extras.baseUserLink,
                autoDownload: extras.autoDownload,
                onDownloadComplete: extras.onDownloadComplete,
              );
            },
          ),

          // /manga/:muId/read-offline?chapter=N — lecteur offline
          GoRoute(
            path: 'read-offline',
            name: 'manga-read-offline',
            builder: (context, state) {
              final muId = _parseMuId(state.pathParameters['muId']);
              final chapter = int.tryParse(
                    state.uri.queryParameters['chapter'] ?? '',
                  ) ??
                  1;
              final extras = state.extra as OfflineReaderExtras?;
              return OfflineReaderView(
                muId: muId,
                chapterNumber: chapter,
                mangaTitle: extras?.mangaTitle ?? '',
              );
            },
          ),
        ],
      ),

      // ──────────────────────────────────────────────────────────────
      // Profile sub-routes
      // ──────────────────────────────────────────────────────────────
      GoRoute(
        path: '/downloads',
        name: 'downloads',
        builder: (context, state) => const DownloadsPage(),
      ),
      GoRoute(
        path: '/notifications-settings',
        name: 'notifications-settings',
        builder: (context, state) => const NotificationsSettingsPage(),
      ),
      GoRoute(
        path: '/my-data',
        name: 'my-data',
        builder: (context, state) => const MyDataView(),
      ),
      GoRoute(
        path: '/custom-selectors',
        name: 'custom-selectors',
        builder: (context, state) => const CustomSelectorsPage(),
      ),
    ],
    errorBuilder: (context, state) => Scaffold(
      appBar: AppBar(title: const Text('Page introuvable')),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.error_outline, size: 64),
              const SizedBox(height: 16),
              Text('Route inconnue : ${state.uri}'),
              const SizedBox(height: 24),
              FilledButton(
                onPressed: () => context.go('/'),
                child: const Text('Retour à l\'accueil'),
              ),
            ],
          ),
        ),
      ),
    ),
  );
}
