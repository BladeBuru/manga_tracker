import 'dart:convert';

import 'package:mangatracker/core/network/http_service.dart';
import 'package:mangatracker/core/network/network_compat.dart';
import 'package:mangatracker/core/network/uri_builder.dart';
import 'package:mangatracker/core/service_locator/service_locator.dart';
import 'package:mangatracker/features/sharing/dto/share.dto.dart';

/// Service de partage de manga entre amis (Phase 8).
///
/// Pas de cache local : l'inbox est par nature volatile (notif temps réel).
/// Le badge "X non-vues" est rafraîchi à chaque ouverture de l'app et
/// au tap sur l'icône notifications.
class SharingService {
  final HttpService _http = getIt<HttpService>();

  Future<SharingService> init() async => this;

  /// Partage un manga avec un ou plusieurs amis.
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
    if (res.statusCode == HttpStatus.ok ||
        res.statusCode == HttpStatus.created) {
      return (jsonDecode(res.body) as List<dynamic>)
          .map((e) => MangaShareDto.fromJson(e as Map<String, dynamic>))
          .toList();
    }
    throw Exception('shareManga failed: ${res.statusCode} ${res.body}');
  }

  /// Inbox : tous les shares reçus (limit 100, plus récents en premier).
  Future<List<MangaShareDto>> getInbox() async {
    final res = await _http.getWithAuthTokens(buildApiUri('/sharing/inbox'));
    if (res.statusCode != HttpStatus.ok) {
      throw Exception('getInbox failed: ${res.statusCode}');
    }
    return (jsonDecode(res.body) as List<dynamic>)
        .map((e) => MangaShareDto.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  /// Marque toutes les shares non-vues comme vues (badge à 0).
  Future<int> markAllSeen() async {
    final res = await _http.postWithAuthTokens(
      buildApiUri('/sharing/inbox/mark-seen'),
      headers: {'Content-Type': 'application/json'},
      body: '{}',
    );
    if (res.statusCode != HttpStatus.ok) {
      throw Exception('markAllSeen failed: ${res.statusCode}');
    }
    final data = jsonDecode(res.body) as Map<String, dynamic>;
    return (data['updated'] as num?)?.toInt() ?? 0;
  }

  /// Compteur "shares non-vues" — alimentation du badge BottomNavBar.
  Future<int> getUnseenCount() async {
    final res = await _http.getWithAuthTokens(
      buildApiUri('/sharing/inbox/unseen-count'),
    );
    if (res.statusCode != HttpStatus.ok) {
      throw Exception('getUnseenCount failed: ${res.statusCode}');
    }
    final data = jsonDecode(res.body) as Map<String, dynamic>;
    return (data['count'] as num?)?.toInt() ?? 0;
  }
}
