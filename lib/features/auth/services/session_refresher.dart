import 'dart:async';
import 'dart:convert';

import 'package:http/http.dart' as http;

/// Issue d'un rafraîchissement de session.
enum RefreshResult {
  /// Nouveaux jetons enregistrés.
  success,

  /// Serveur injoignable ou réponse inexploitable : la session reste
  /// plausible, on réessaiera.
  networkError,

  /// Le serveur a **explicitement** refusé la session : reconnexion requise.
  rejected,
}

/// Rafraîchit la session (échange du refresh token). Sans Flutter ni GetIt :
/// testé seul (`test/features/auth/session_refresher_test.dart`).
///
/// Causes des déconnexions « au hasard » corrigées ici :
/// 1. **Un seul échange à la fois, vraiment.** Le verrou était posé APRÈS
///    une lecture asynchrone : deux requêtes simultanées échangeaient le même
///    jeton, le serveur refusait la seconde et l'application effaçait la
///    session. L'échange en cours est désormais mémorisé synchroniquement :
///    tous les appels simultanés partagent le même résultat.
/// 2. **Seul un refus explicite du serveur est un refus** : 401/403 avec la
///    réponse JSON de l'API. Une coupure au réveil (`ClientException`), une
///    page de pare-feu (403 HTML), une écriture de stockage ratée… sont des
///    pannes passagères, plus des déconnexions.
/// 3. **Échange déjà fait ailleurs** : si le jeton stocké a changé pendant
///    l'échange (un autre appel l'a renouvelé), ce n'est pas un refus.
/// 4. Le **refresh token est écrit avant** l'access token : une écriture
///    interrompue laisse au pire un access token périmé, jamais un refresh
///    token mort.
class SessionRefresher {
  static const String refreshTokenKey = 'refreshToken';
  static const String accessTokenKey = 'accessToken';

  final Future<String?> Function(String key) read;
  final Future<void> Function(String key, String value) write;
  final Future<http.Response> Function(String refreshToken) post;
  final bool Function() isConnected;
  final bool Function(String token) isExpired;
  final void Function(String accessToken)? onAccessToken;
  final Duration timeout;

  SessionRefresher({
    required this.read,
    required this.write,
    required this.post,
    required this.isConnected,
    required this.isExpired,
    this.onAccessToken,
    this.timeout = const Duration(seconds: 15),
  });

  Future<RefreshResult>? _inflight;

  /// Échange le refresh token ([token] ou celui stocké). Les appels faits
  /// pendant un échange en cours en partagent le résultat.
  Future<RefreshResult> refresh({String? token}) {
    final running = _inflight;
    if (running != null) return running;
    final started = _refresh(token);
    _inflight = started;
    started.whenComplete(() {
      if (identical(_inflight, started)) _inflight = null;
    });
    return started;
  }

  Future<RefreshResult> _refresh(String? token) async {
    final String? sent;
    try {
      sent = token ?? await read(refreshTokenKey);
    } catch (_) {
      return RefreshResult.networkError;
    }
    if (sent == null || isExpired(sent)) return RefreshResult.rejected;
    if (!isConnected()) return RefreshResult.networkError;

    try {
      final res = await post(sent).timeout(timeout);
      if (res.statusCode == 200 || res.statusCode == 201) {
        return await _store(res.body);
      }
      if (isExplicitRejection(res)) {
        // Un autre échange a pu aboutir pendant celui-ci (autre isolat,
        // autre onglet) : le jeton stocké a changé, la session est vivante.
        final stored = await read(refreshTokenKey);
        if (stored != null && stored != sent && !isExpired(stored)) {
          return RefreshResult.success;
        }
        return RefreshResult.rejected;
      }
      return RefreshResult.networkError;
    } catch (_) {
      // Réseau coupé, délai dépassé, réponse tronquée, stockage indisponible :
      // jamais une raison de déconnecter.
      return RefreshResult.networkError;
    }
  }

  Future<RefreshResult> _store(String body) async {
    final data = jsonDecode(body);
    if (data is! Map) return RefreshResult.networkError;
    final access = data['accessToken'];
    final refresh = data['refreshToken'];
    if (access is! String || access.isEmpty) return RefreshResult.networkError;
    if (refresh is String && refresh.isNotEmpty) {
      await write(refreshTokenKey, refresh);
    }
    await write(accessTokenKey, access);
    onAccessToken?.call(access);
    return RefreshResult.success;
  }

  /// Refus émis par l'API elle-même : 401/403 avec son corps JSON
  /// (`{"statusCode": 401, …}`). Une page HTML de pare-feu ou de proxy
  /// (Cloudflare) n'en est pas un.
  static bool isExplicitRejection(http.Response res) {
    if (res.statusCode != 401 && res.statusCode != 403) return false;
    if (res.headers.containsKey('cf-mitigated')) return false;
    try {
      final body = jsonDecode(res.body);
      return body is Map && body['statusCode'] == res.statusCode;
    } catch (_) {
      return false;
    }
  }
}
