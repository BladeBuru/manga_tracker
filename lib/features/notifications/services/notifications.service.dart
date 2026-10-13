import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:mangatracker/core/network/api_exception.dart';
import 'package:mangatracker/core/network/http_service.dart';
import 'package:mangatracker/core/network/uri_builder.dart';
import 'package:mangatracker/core/service_locator/service_locator.dart';
import 'package:mangatracker/core/storage/services/storage.service.dart';
import 'package:mangatracker/features/notifications/dto/app_notification.dto.dart';

/// Client du centre de notifications (`/notifications`).
///
/// | Appel                          | Réponse                                   |
/// |--------------------------------|-------------------------------------------|
/// | `GET /notifications`           | `{items, unreadCount, nextBefore}`        |
/// | `GET /notifications/unread-count` | `{count}`                              |
/// | `POST /notifications/:id/read` | 200 `{ok}`                                |
/// | `POST /notifications/read-all` | 200 `{updated}`                           |
///
/// Tout code 2xx est un succès (plusieurs POST de l'API renvoient 201). Un
/// autre code lève [ApiException] — jamais un corps d'erreur parsé comme une
/// page vide.
///
/// Cache hors ligne : la première page, sous `cached_notifications` (préfixe
/// `cached_` → purgée à la déconnexion et au changement de compte).
///
/// Dépendances résolues **à l'appel** (lazy singleton sans `dependsOn`,
/// cf. la régression d'écran blanc documentée dans `service_locator.dart`).
class NotificationsService {
  static const String cacheKey = 'cached_notifications';
  static const int pageSize = 30;

  final HttpService? _httpOverride;
  final StorageService? _storageOverride;

  NotificationsService({HttpService? http, StorageService? storage})
      : _httpOverride = http,
        _storageOverride = storage;

  HttpService get _http => _httpOverride ?? getIt<HttpService>();
  StorageService get _storage => _storageOverride ?? getIt<StorageService>();

  /// Une page, des plus récentes aux plus anciennes. [before] = curseur
  /// `nextBefore` de la page précédente.
  Future<NotificationsPageDto> fetchPage({
    int limit = pageSize,
    String? before,
  }) async {
    final res = await _http.getWithAuthTokens(
      buildApiUri('/notifications', {
        'limit': '$limit',
        if (before != null) 'before': before,
      }),
    );
    if (!isHttpSuccess(res.statusCode)) throw ApiException.fromResponse(res);
    return NotificationsPageDto.fromJson(jsonDecode(res.body));
  }

  /// Nombre de notifications non lues (pastille de la cloche).
  Future<int> fetchUnreadCount() async {
    final res = await _http.getWithAuthTokens(
      buildApiUri('/notifications/unread-count'),
    );
    if (!isHttpSuccess(res.statusCode)) throw ApiException.fromResponse(res);
    final data = jsonDecode(res.body);
    return data is Map ? (parseInt(data['count']) ?? 0) : 0;
  }

  Future<void> markRead(String id) async {
    final res = await _http.postWithAuthTokens(
      buildApiUri('/notifications/${Uri.encodeComponent(id)}/read'),
      headers: {'Content-Type': 'application/json'},
      body: '{}',
    );
    if (!isHttpSuccess(res.statusCode)) throw ApiException.fromResponse(res);
  }

  /// Marque tout comme lu ; renvoie le nombre de lignes modifiées.
  Future<int> markAllRead() async {
    final res = await _http.postWithAuthTokens(
      buildApiUri('/notifications/read-all'),
      headers: {'Content-Type': 'application/json'},
      body: '{}',
    );
    if (!isHttpSuccess(res.statusCode)) throw ApiException.fromResponse(res);
    try {
      final data = jsonDecode(res.body);
      return data is Map ? (parseInt(data['updated']) ?? 0) : 0;
    } catch (_) {
      return 0; // 204 / corps vide : succès quand même.
    }
  }

  // ─── Cache hors ligne ───

  Future<void> saveCache(NotificationsPageDto page) async {
    try {
      await _storage.writeSecureData(cacheKey, jsonEncode(page.toJson()));
    } catch (e) {
      debugPrint('NotificationsService: écriture du cache impossible ($e)');
    }
  }

  Future<NotificationsPageDto?> readCache() async {
    try {
      final raw = await _storage.readSecureData(cacheKey);
      if (raw == null) return null;
      return NotificationsPageDto.fromJson(jsonDecode(raw));
    } catch (e) {
      debugPrint('NotificationsService: lecture du cache impossible ($e)');
      return null;
    }
  }
}
