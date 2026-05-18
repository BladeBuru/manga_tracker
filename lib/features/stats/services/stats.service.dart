import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:http/http.dart' show Response;
import 'package:mangatracker/core/network/http_service.dart';
import 'package:mangatracker/core/network/network_compat.dart';
import 'package:mangatracker/core/network/uri_builder.dart';
import 'package:mangatracker/core/service_locator/service_locator.dart';
import 'package:mangatracker/core/storage/services/storage.service.dart';
import 'package:mangatracker/features/stats/dto/user_stats.dto.dart';

/// Service consommant `/user/stats` (Phase 2).
///
/// Cache local 1h via `StorageService` (clé `cached_user_stats`). En cas
/// d'erreur réseau, fallback sur le cache même expiré pour éviter un
/// écran vide. Le cache est invalidé manuellement après une action qui
/// affecte les stats (add/remove biblio, update chapter, change status).
class StatsService {
  static const String _cacheKey = 'cached_user_stats';
  static const String _cacheTimestampKey = 'cached_user_stats_at';
  static const Duration _cacheTtl = Duration(hours: 1);

  final HttpService _httpService = getIt<HttpService>();
  final StorageService _storage = getIt<StorageService>();

  Future<StatsService> init() async => this;

  /// Récupère les statistiques de l'utilisateur courant.
  ///
  /// Flow :
  /// 1. Si `forceRefresh: false` et cache < 1h → retourne le cache (fast path).
  /// 2. Sinon, fetch réseau ; en cas de succès, met à jour le cache.
  /// 3. En cas d'échec réseau, fallback sur le cache (même expiré) pour
  ///    éviter un écran vide. Si pas de cache → on remonte l'exception.
  Future<UserStatsDto> getUserStats({bool forceRefresh = false}) async {
    if (!forceRefresh) {
      final cached = await _readFreshCache();
      if (cached != null) return cached;
    }

    try {
      final Response response =
          await _httpService.getWithAuthTokens(buildApiUri('/user/stats'));
      if (response.statusCode != HttpStatus.ok) {
        throw Exception('Stats request failed: ${response.statusCode}');
      }
      final data = jsonDecode(response.body) as Map<String, dynamic>;
      final stats = UserStatsDto.fromJson(data);
      await _writeCache(stats);
      return stats;
    } catch (e) {
      // Fallback sur le cache même expiré pour éviter un écran vide.
      final stale = await _readCacheIgnoringTtl();
      if (stale != null) {
        debugPrint('StatsService: réseau KO, fallback cache stale ($e)');
        return stale;
      }
      rethrow;
    }
  }

  /// Invalide manuellement le cache (à appeler après add/remove/update biblio
  /// pour que la prochaine ouverture de la page stats refasse un fetch).
  Future<void> invalidateCache() async {
    await _storage.deleteSecureData(_cacheKey);
    await _storage.deleteSecureData(_cacheTimestampKey);
  }

  Future<UserStatsDto?> _readFreshCache() async {
    final tsRaw = await _storage.readSecureData(_cacheTimestampKey);
    if (tsRaw == null) return null;
    final ts = DateTime.tryParse(tsRaw);
    if (ts == null) return null;
    if (DateTime.now().difference(ts) > _cacheTtl) return null;
    return _readCacheIgnoringTtl();
  }

  Future<UserStatsDto?> _readCacheIgnoringTtl() async {
    try {
      final raw = await _storage.readSecureData(_cacheKey);
      if (raw == null) return null;
      return UserStatsDto.fromJson(jsonDecode(raw) as Map<String, dynamic>);
    } catch (e) {
      debugPrint('StatsService: lecture cache KO: $e');
      return null;
    }
  }

  Future<void> _writeCache(UserStatsDto stats) async {
    try {
      await _storage.writeSecureData(_cacheKey, jsonEncode(stats.toJson()));
      await _storage.writeSecureData(
        _cacheTimestampKey,
        DateTime.now().toIso8601String(),
      );
    } catch (e) {
      debugPrint('StatsService: écriture cache KO: $e');
    }
  }
}
