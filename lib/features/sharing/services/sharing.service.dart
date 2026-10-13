import 'dart:convert';

import 'package:mangatracker/core/network/api_exception.dart';
import 'package:mangatracker/core/network/http_service.dart';
import 'package:mangatracker/core/network/uri_builder.dart';
import 'package:mangatracker/core/service_locator/service_locator.dart';
import 'package:mangatracker/features/sharing/dto/share.dto.dart';

/// Service de partage de manga entre amis (Phase 8) — « Recommander à un
/// ami » et « Recommandations reçues ».
///
/// Pas de cache persistant : l'inbox est par nature volatile. La dernière
/// réponse est gardée **en mémoire** (interrogée toutes les 60 s par
/// `NotificationCountsService`) pour que le bandeau « Recommandé par » de la
/// fiche ne refasse pas l'appel à chaque ouverture ([getInboxCached]). Ce
/// souvenir est effacé à la déconnexion ([clearCache]).
///
/// Tout code 2xx est un succès (`mark-seen` répond 201, ce qui faisait
/// échouer en silence le « tout vu » et laissait la pastille allumée).
class SharingService {
  final HttpService? _httpOverride;
  final DateTime Function() _now;

  SharingService({HttpService? http, DateTime Function()? now})
      : _httpOverride = http,
        _now = now ?? DateTime.now;

  HttpService get _http => _httpOverride ?? getIt<HttpService>();

  List<MangaShareDto>? _lastInbox;
  DateTime? _lastInboxAt;

  Future<SharingService> init() async => this;

  /// Recommande un manga à un ou plusieurs amis.
  Future<List<MangaShareDto>> shareMangaWithFriends(
    int muId, {
    required List<int> friendIds,
    String? message,
  }) async {
    final res = await _http.postWithAuthTokens(
      buildApiUri('/sharing/manga/$muId'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({
        'friendIds': friendIds,
        if (message != null) 'message': message,
      }),
    );
    if (!isHttpSuccess(res.statusCode)) throw ApiException.fromResponse(res);
    return (jsonDecode(res.body) as List<dynamic>)
        .map((e) => MangaShareDto.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  /// Inbox : tous les shares reçus (limit 100, plus récents en premier).
  Future<List<MangaShareDto>> getInbox() async {
    final res = await _http.getWithAuthTokens(buildApiUri('/sharing/inbox'));
    if (!isHttpSuccess(res.statusCode)) throw ApiException.fromResponse(res);
    final inbox = (jsonDecode(res.body) as List<dynamic>)
        .map((e) => MangaShareDto.fromJson(e as Map<String, dynamic>))
        .toList();
    _lastInbox = inbox;
    _lastInboxAt = _now();
    return inbox;
  }

  /// Inbox servie de mémoire si elle a moins de [maxAge], sinon rechargée.
  /// Sur échec réseau, la dernière réponse connue (même ancienne) est
  /// servie ; à défaut l'exception remonte.
  Future<List<MangaShareDto>> getInboxCached({
    Duration maxAge = const Duration(minutes: 2),
  }) async {
    final cached = _lastInbox;
    final at = _lastInboxAt;
    if (cached != null && at != null && _now().difference(at) < maxAge) {
      return cached;
    }
    try {
      return await getInbox();
    } catch (_) {
      if (cached != null) return cached;
      rethrow;
    }
  }

  /// Oublie l'inbox gardée en mémoire (déconnexion, changement de compte).
  void clearCache() {
    _lastInbox = null;
    _lastInboxAt = null;
  }

  /// Marque toutes les shares non-vues comme vues (badge à 0). Côté serveur,
  /// marque aussi lues les lignes « recommandation » du centre.
  Future<int> markAllSeen() async {
    final res = await _http.postWithAuthTokens(
      buildApiUri('/sharing/inbox/mark-seen'),
      headers: {'Content-Type': 'application/json'},
      body: '{}',
    );
    if (!isHttpSuccess(res.statusCode)) throw ApiException.fromResponse(res);
    final now = _now();
    _lastInbox = _lastInbox
        ?.map((s) => s.isNew ? s.markedSeen(now) : s)
        .toList(growable: false);
    try {
      final data = jsonDecode(res.body);
      return data is Map ? ((data['updated'] as num?)?.toInt() ?? 0) : 0;
    } catch (_) {
      return 0; // corps vide : succès quand même.
    }
  }

  /// Compteur "shares non-vues" — alimentation du badge BottomNavBar.
  Future<int> getUnseenCount() async {
    final res = await _http.getWithAuthTokens(
      buildApiUri('/sharing/inbox/unseen-count'),
    );
    if (!isHttpSuccess(res.statusCode)) throw ApiException.fromResponse(res);
    final data = jsonDecode(res.body) as Map<String, dynamic>;
    return (data['count'] as num?)?.toInt() ?? 0;
  }
}
