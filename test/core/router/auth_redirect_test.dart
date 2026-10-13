import 'package:flutter_test/flutter_test.dart';
import 'package:mangatracker/core/router/auth_redirect.dart';
import 'package:mangatracker/features/auth/services/auth_session.dart';

/// Garde d'authentification du routeur (logique pure).
void main() {
  String? redirect(
    String location, {
    required AuthStatus status,
    bool startupCompleted = true,
  }) =>
      resolveAuthRedirect(
        Uri.parse(location),
        status: status,
        startupCompleted: startupCompleted,
      );

  group('sans session', () {
    test('un lien direct vers une page protégée mène à /login?from=…', () {
      expect(
        redirect('/manga/42', status: AuthStatus.signedOut),
        '/login?from=%2Fmanga%2F42',
      );
      expect(
        redirect('/friends?tab=pending', status: AuthStatus.signedOut),
        '/login?from=%2Ffriends%3Ftab%3Dpending',
      );
    });

    test("l'accueil ne porte pas de from (destination par défaut)", () {
      expect(redirect('/home', status: AuthStatus.signedOut), '/login');
    });

    test('les onglets sont protégés', () {
      for (final tab in ['/library', '/search', '/profile', '/profile/edit']) {
        expect(
          redirect(tab, status: AuthStatus.signedOut),
          startsWith('/login?from='),
          reason: tab,
        );
      }
    });

    test('les pages publiques restent accessibles', () {
      for (final path in [
        '/',
        '/login',
        '/register?email=a%40b.c',
        '/forgot-password',
        '/auth/verify?token=x',
        '/auth/reset-password?token=x',
      ]) {
        expect(redirect(path, status: AuthStatus.signedOut), isNull,
            reason: path);
      }
    });
  });

  group('connecté', () {
    test('/login, /register, /forgot-password renvoient à /home', () {
      for (final path in ['/login', '/register', '/forgot-password']) {
        expect(redirect(path, status: AuthStatus.authenticated), '/home',
            reason: path);
      }
    });

    test('aller-retour from : la page demandée est rouverte', () {
      final login = redirect('/stats', status: AuthStatus.signedOut)!;
      expect(redirect(login, status: AuthStatus.authenticated), '/stats');
    });

    test('from externe ou détourné : ignoré, accueil', () {
      for (final from in [
        'https://evil.example/x',
        '//evil.example/x',
        r'/\evil.example',
        'javascript:alert(1)',
        'manga/42',
        '/login',
        '/',
      ]) {
        final location = Uri(
          path: '/login',
          queryParameters: {returnToParam: from},
        ).toString();
        expect(redirect(location, status: AuthStatus.authenticated), '/home',
            reason: from);
      }
    });

    test('/ attend la fin du démarrage (biométrie, « Quoi de neuf ? »)', () {
      expect(
        redirect('/', status: AuthStatus.authenticated, startupCompleted: false),
        isNull,
      );
      expect(redirect('/', status: AuthStatus.authenticated), '/home');
    });

    test('les pages protégées sont accessibles', () {
      expect(redirect('/manga/42', status: AuthStatus.authenticated), isNull);
    });
  });

  test('session rejetée : jamais de redirection forcée (offline-first)', () {
    for (final path in ['/home', '/library', '/manga/42', '/login']) {
      expect(redirect(path, status: AuthStatus.rejected), isNull, reason: path);
    }
  });

  group('safeReturnPath', () {
    test('garde le chemin et la requête internes', () {
      expect(safeReturnPath('/friends?tab=pending'), '/friends?tab=pending');
      expect(safeReturnPath('/home/section/genre%3AAction'),
          '/home/section/genre%3AAction');
    });

    test('refuse vide et nul', () {
      expect(safeReturnPath(null), isNull);
      expect(safeReturnPath('  '), isNull);
    });
  });

  group('AuthSession', () {
    test('restore : jeton utilisable = connecté, sinon déconnecté', () async {
      final session = AuthSession();
      await session.restore(
        read: (key) async => key == 'refreshToken' ? 'ok' : null,
        isExpired: (token) => token == null,
      );
      expect(session.current, AuthStatus.authenticated);
      await session.restore(read: (_) async => null, isExpired: (_) => true);
      expect(session.current, AuthStatus.signedOut);
    });

    test('le routeur n\'est rafraîchi qu\'à la perte de session', () {
      final session = AuthSession(initial: AuthStatus.authenticated);
      var refreshes = 0;
      session.routerRefresh.addListener(() => refreshes++);
      session.markRejected();
      session.markSignedIn();
      expect(refreshes, 0);
      session.markSignedOut();
      session.markSignedOut();
      expect(refreshes, 1);
    });

    test('un rejet sans session ne la fait pas « exister »', () {
      final session = AuthSession();
      session.markRejected();
      expect(session.current, AuthStatus.signedOut);
    });
  });
}
