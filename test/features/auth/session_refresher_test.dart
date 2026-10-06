import 'dart:async';
import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:mangatracker/features/auth/services/session_refresher.dart';

/// Stockage sécurisé en mémoire.
class _Store {
  final Map<String, String> values = {'refreshToken': 'r1'};
  Future<String?> read(String k) async => values[k];
  Future<void> write(String k, String v) async => values[k] = v;
}

http.Response _json(int status, Map<String, dynamic> body,
        {Map<String, String> headers = const {}}) =>
    http.Response(jsonEncode(body), status, headers: headers);

void main() {
  late _Store store;
  late int posts;

  SessionRefresher build(Future<http.Response> Function(String) post) {
    return SessionRefresher(
      read: store.read,
      write: store.write,
      post: (token) {
        posts++;
        return post(token);
      },
      isConnected: () => true,
      isExpired: (_) => false,
    );
  }

  setUp(() {
    store = _Store();
    posts = 0;
  });

  test('requêtes simultanées : UN seul échange, résultat partagé', () async {
    final answer = Completer<http.Response>();
    final refresher = build((_) => answer.future);

    final results = [
      refresher.refresh(),
      refresher.refresh(),
      refresher.refresh(),
    ];
    answer.complete(
      _json(201, {'accessToken': 'a2', 'refreshToken': 'r2'}),
    );

    expect(await Future.wait(results), everyElement(RefreshResult.success));
    expect(posts, 1);
    expect(store.values['refreshToken'], 'r2');
    expect(store.values['accessToken'], 'a2');
  });

  test('refus explicite de l\'API (JSON) → rejet', () async {
    final refresher = build(
      (_) async => _json(401, {'statusCode': 401, 'message': 'Session'}),
    );
    expect(await refresher.refresh(), RefreshResult.rejected);
  });

  test('403 HTML (pare-feu) ou défi Cloudflare → panne passagère', () async {
    final html = build(
      (_) async => http.Response('<html>Access denied</html>', 403),
    );
    expect(await html.refresh(), RefreshResult.networkError);

    final challenge = build(
      (_) async => _json(
        403,
        {'statusCode': 403},
        headers: {'cf-mitigated': 'challenge'},
      ),
    );
    expect(await challenge.refresh(), RefreshResult.networkError);
  });

  test('coupure au réveil, délai, 5xx, 429 → jamais une déconnexion', () async {
    for (final failure in <Future<http.Response> Function(String)>[
      (_) async => throw http.ClientException('Connection closed'),
      (_) async => throw TimeoutException('lent'),
      (_) async => http.Response('oops', 502),
      (_) async => _json(429, {'statusCode': 429}),
    ]) {
      expect(await build(failure).refresh(), RefreshResult.networkError);
    }
  });

  test('stockage indisponible pendant l\'écriture → passager, pas un rejet',
      () async {
    final refresher = SessionRefresher(
      read: store.read,
      write: (_, __) async => throw Exception('Keystore'),
      post: (_) async => _json(201, {'accessToken': 'a', 'refreshToken': 'r'}),
      isConnected: () => true,
      isExpired: (_) => false,
    );
    expect(await refresher.refresh(), RefreshResult.networkError);
  });

  test('jeton renouvelé ailleurs pendant l\'échange → la session est vivante',
      () async {
    final refresher = build((_) async {
      store.values['refreshToken'] = 'r-autre';
      return _json(401, {'statusCode': 401});
    });
    expect(await refresher.refresh(), RefreshResult.success);
  });

  test('le refresh token est écrit AVANT l\'access token', () async {
    final order = <String>[];
    final refresher = SessionRefresher(
      read: store.read,
      write: (k, v) async => order.add(k),
      post: (_) async => _json(201, {'accessToken': 'a', 'refreshToken': 'r'}),
      isConnected: () => true,
      isExpired: (_) => false,
    );
    await refresher.refresh();
    expect(order, ['refreshToken', 'accessToken']);
  });

  test('après un échange terminé, un nouvel appel en relance un', () async {
    final refresher = build(
      (_) async => _json(201, {'accessToken': 'a', 'refreshToken': 'r'}),
    );
    await refresher.refresh();
    await refresher.refresh();
    expect(posts, 2);
  });

  test('aucun jeton, ou hors ligne : pas d\'appel réseau', () async {
    store.values.clear();
    expect(
      await build((_) async => _json(201, {})).refresh(),
      RefreshResult.rejected,
    );
    store.values['refreshToken'] = 'r1';
    final offline = SessionRefresher(
      read: store.read,
      write: store.write,
      post: (_) async => _json(201, {}),
      isConnected: () => false,
      isExpired: (_) => false,
    );
    expect(await offline.refresh(), RefreshResult.networkError);
  });
}
