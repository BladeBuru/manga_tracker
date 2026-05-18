import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:mangatracker/core/network/http_service.dart';
import 'package:mangatracker/core/network/network_compat.dart';
import 'package:mangatracker/core/network/uri_builder.dart';
import 'package:mangatracker/core/service_locator/service_locator.dart';
import 'package:mangatracker/core/storage/services/storage.service.dart';
import 'package:mangatracker/features/friends/dto/friend.dto.dart';

/// Service côté Flutter pour le système d'amis (Phase 6).
///
/// Cache 24h sur la liste d'amis acceptés (clé `cached_friends`) pour
/// affichage offline. Les demandes en attente ne sont PAS cachées
/// (UI doit refléter l'état serveur en temps quasi-réel pour le badge).
class FriendsService {
  static const String _friendsCacheKey = 'cached_friends';
  static const String _friendsCacheAtKey = 'cached_friends_at';
  static const Duration _friendsCacheTtl = Duration(hours: 24);

  final HttpService _http = getIt<HttpService>();
  final StorageService _storage = getIt<StorageService>();

  Future<FriendsService> init() async => this;

  /// Liste des amis acceptés. Si `forceRefresh = false` et cache < 24h,
  /// retourne le cache (fast path). Sinon fetch + cache.
  Future<List<FriendshipDto>> getAcceptedFriends({
    bool forceRefresh = false,
  }) async {
    if (!forceRefresh) {
      final cached = await _readCacheIfFresh();
      if (cached != null) return cached;
    }
    final res = await _http.getWithAuthTokens(buildApiUri('/friends'));
    if (res.statusCode != HttpStatus.ok) {
      // Fallback cache stale en cas d'erreur réseau.
      final stale = await _readCacheIgnoringTtl();
      if (stale != null) return stale;
      throw Exception('getAcceptedFriends failed: ${res.statusCode}');
    }
    final list = (jsonDecode(res.body) as List<dynamic>)
        .map((e) => FriendshipDto.fromJson(e as Map<String, dynamic>))
        .toList();
    await _writeCache(list);
    return list;
  }

  /// Demandes reçues en attente. Pas de cache — toujours fresh pour le badge.
  Future<List<FriendshipDto>> getPendingRequests() async {
    final res = await _http.getWithAuthTokens(buildApiUri('/friends/pending'));
    if (res.statusCode != HttpStatus.ok) {
      throw Exception('getPendingRequests failed: ${res.statusCode}');
    }
    return (jsonDecode(res.body) as List<dynamic>)
        .map((e) => FriendshipDto.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  /// Envoie une demande d'amitié par username OU userId.
  Future<FriendshipDto> sendRequest({
    int? addresseeId,
    String? addresseeUsername,
  }) async {
    final body = <String, dynamic>{
      if (addresseeId != null) 'addresseeId': addresseeId,
      if (addresseeUsername != null) 'addresseeUsername': addresseeUsername,
    };
    final res = await _http.postWithAuthTokens(
      buildApiUri('/friends/request'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode(body),
    );
    if (res.statusCode == HttpStatus.ok ||
        res.statusCode == HttpStatus.created) {
      // Invalide le cache amis : une demande acceptée auto (sens inverse)
      // peut avoir fait basculer la relation en `accepted`.
      await invalidateCache();
      return FriendshipDto.fromJson(jsonDecode(res.body));
    }
    throw Exception('sendRequest failed: ${res.statusCode} ${res.body}');
  }

  /// Accepte / rejette / bloque une demande pending.
  Future<FriendshipDto> updateStatus(
    int friendshipId,
    FriendshipStatus newStatus,
  ) async {
    final res = await _http.patchWithAuthTokens(
      buildApiUri('/friends/$friendshipId'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({'status': newStatus.value}),
    );
    if (res.statusCode != HttpStatus.ok) {
      throw Exception('updateStatus failed: ${res.statusCode}');
    }
    await invalidateCache();
    return FriendshipDto.fromJson(jsonDecode(res.body));
  }

  /// Supprime une amitié (les deux côtés peuvent supprimer).
  Future<void> deleteFriendship(int friendshipId) async {
    final res = await _http.deleteWithAuthTokens(
      buildApiUri('/friends/$friendshipId'),
    );
    if (res.statusCode != HttpStatus.ok) {
      throw Exception('deleteFriendship failed: ${res.statusCode}');
    }
    await invalidateCache();
  }

  /// Recherche d'utilisateurs pour autocomplete (min 2 chars).
  Future<List<UserSearchResultDto>> searchUsers(String query) async {
    if (query.trim().length < 2) return [];
    final res = await _http.getWithAuthTokens(
      buildApiUri('/friends/search', {'q': query.trim()}),
    );
    if (res.statusCode != HttpStatus.ok) {
      throw Exception('searchUsers failed: ${res.statusCode}');
    }
    return (jsonDecode(res.body) as List<dynamic>)
        .map((e) => UserSearchResultDto.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  /// Invalide le cache (à appeler après toute mutation côté serveur).
  Future<void> invalidateCache() async {
    await _storage.deleteSecureData(_friendsCacheKey);
    await _storage.deleteSecureData(_friendsCacheAtKey);
  }

  Future<List<FriendshipDto>?> _readCacheIfFresh() async {
    final ts = await _storage.readSecureData(_friendsCacheAtKey);
    if (ts == null) return null;
    final parsed = DateTime.tryParse(ts);
    if (parsed == null) return null;
    if (DateTime.now().difference(parsed) > _friendsCacheTtl) return null;
    return _readCacheIgnoringTtl();
  }

  Future<List<FriendshipDto>?> _readCacheIgnoringTtl() async {
    try {
      final raw = await _storage.readSecureData(_friendsCacheKey);
      if (raw == null) return null;
      final list = jsonDecode(raw) as List<dynamic>;
      return list
          .map((e) => FriendshipDto.fromJson(e as Map<String, dynamic>))
          .toList();
    } catch (e) {
      debugPrint('FriendsService: lecture cache KO: $e');
      return null;
    }
  }

  Future<void> _writeCache(List<FriendshipDto> friends) async {
    try {
      // Note : le DTO ne définit pas toJson, on stocke un format minimal
      // qui peut être re-parsé par FriendshipDto.fromJson.
      final list = friends
          .map((f) => {
                'id': f.id,
                'status': f.status.value,
                'direction': f.direction == FriendshipDirection.received
                    ? 'received'
                    : 'sent',
                'otherUserId': f.otherUserId,
                'otherUsername': f.otherUsername,
                'otherDisplayName': f.otherDisplayName,
                'otherAvatarUrl': f.otherAvatarUrl,
                'createdAt': f.createdAt.toIso8601String(),
                'acceptedAt': f.acceptedAt?.toIso8601String(),
              })
          .toList();
      await _storage.writeSecureData(_friendsCacheKey, jsonEncode(list));
      await _storage.writeSecureData(
        _friendsCacheAtKey,
        DateTime.now().toIso8601String(),
      );
    } catch (e) {
      debugPrint('FriendsService: écriture cache KO: $e');
    }
  }
}
