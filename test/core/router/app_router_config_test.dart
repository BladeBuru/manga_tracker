import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:mangatracker/core/router/app_router.dart';
import 'package:mangatracker/features/auth/services/auth_session.dart';
import 'package:mangatracker/features/home/views/main_tab.dart';

/// Les URL de l'application se résolvent toutes seules (F5, lien direct).
void main() {
  late GoRouter router;

  setUp(() => router = buildAppRouter(session: AuthSession()));
  tearDown(() => router.dispose());

  RouteMatchList match(String location) =>
      router.configuration.findMatch(Uri.parse(location));

  String? lastName(RouteMatchList list) => list.last.route.name;

  test('chaque onglet a son URL, dans la coque des onglets', () {
    for (final tab in MainTab.values) {
      final list = match(tab.path);
      expect(list.isError, isFalse, reason: tab.path);
      expect(list.matches.single, isA<ShellRouteMatch>(), reason: tab.path);
      expect(lastName(list), tab.name);
    }
  });

  test('les sous-pages d\'onglet s\'ouvrent par-dessus la barre', () {
    for (final (location, name) in [
      ('/home/section/genre%3AAction', 'home-section'),
      ('/profile/edit', 'profile-edit'),
    ]) {
      final list = match(location);
      expect(list.isError, isFalse, reason: location);
      // [coque (onglet reconstruit dessous), page plein écran]
      expect(list.matches.first, isA<ShellRouteMatch>(), reason: location);
      expect(list.matches.last, isNot(isA<ShellRouteMatch>()));
      expect(lastName(list), name);
    }
  });

  test('pages plein écran et paramètres', () {
    expect(lastName(match('/manga/42')), 'manga-detail');
    expect(lastName(match('/manga/42/read-offline?chapter=3')),
        'manga-read-offline');
    expect(lastName(match('/friends/7')), 'friend-profile');
    expect(lastName(match('/login?from=%2Fstats')), 'login');
    expect(match('/nexiste/pas').isError, isTrue);
  });
}
