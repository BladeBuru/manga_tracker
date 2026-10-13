import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:mangatracker/core/network/api_exception.dart';
import 'package:mangatracker/core/network/http_service.dart';
import 'package:mangatracker/core/network/uri_builder.dart';
import 'package:mangatracker/core/service_locator/service_locator.dart';
import 'package:mangatracker/core/storage/services/storage.service.dart';
import 'package:mangatracker/features/friends/dto/friend.dto.dart';
import 'package:mangatracker/features/manga/dto/manga_quick_view.dto.dart';

/// Service côté Flutter pour le système d'amis (Phase 6).
///
/// Cache de la liste d'amis acceptés (clé `cached_friends`) pour l'affichage
/// hors ligne. **5 minutes** seulement (24 h avant) : les sélecteurs
/// « Recommander à un ami » / « Lire à deux » proposaient des amitiés
/// supprimées depuis, d'où des 403 bruts à la création d'un groupe. Les
/// sélecteurs et la page Amis forcent d'ailleurs le rafraîchissement ; le
/// cache ne sert plus que de repli hors ligne.
///
/// Les demandes (reçues, envoyées) ne sont PAS cachées : l'interface doit
/// refléter l'état serveur. Toute réponse non 2xx lève [ApiException], dont
/// le message (409 « déjà demandé », 403…) s'affiche via
/// `userFacingErrorMessage`.
class FriendsService {
  static const String _friendsCacheKey = 'cached_friends';
  static const String _friendsCacheAtKey = 'cached_friends_at';
  static const Duration _friendsCacheTtl = Duration(minutes: 5);

  final HttpService? _httpOverride;
  final StorageService? _storageOverride;

  FriendsService({HttpService? http, StorageService? storage})
      : _httpOverride = http,
        _storageOverride = storage;

  HttpService get _http => _httpOverride ?? getIt<HttpService>();
  StorageService get _storage => _storageOverride ?? getIt<StorageService>();

  Future<FriendsService> init() async => this;

  /// Liste des amis acceptés. Sans [forceRefresh] et cache < 5 min : cache.
  /// Sinon réseau ; sur échec (réseau coupé compris), dernier cache connu,
  /// à défaut l'erreur remonte.
  Future<List<FriendshipDto>> getAcceptedFriends({
    bool forceRefresh = false,
  }) async {
    if (!forceRefresh) {
      final cached = await _readCacheIfFresh();
      if (cached != null) return cached;
    }
    try {
      final list = await _getFriendships('/friends');
      await _writeCache(list);
      return list;
    } catch (e) {
      final stale = await _readCacheIgnoringTtl();
      if (stale != null) return stale;
      rethrow;
    }
  }

  /// Amitié acceptée avec [friendUserId], ou `null` (inconnue, hors ligne
  /// sans cache). Sert au profil d'un ami ouvert par lien direct, qui n'a
  /// pas reçu le nom à afficher.
  Future<FriendshipDto?> findAcceptedFriend(int friendUserId) async {
    try {
      final friends = await getAcceptedFriends();
      for (final friend in friends) {
        if (friend.otherUserId == friendUserId) return friend;
      }
    } catch (_) {
      // Le nom manquera simplement : la bibliothèque reste affichée.
    }
    return null;
  }

  /// Bibliothèque d'un ami accepté (`GET /friends/:id/library`).
  ///
  /// 403 si l'amitié n'est pas acceptée — propagé en exception. Pas de
  /// cache : consultation ponctuelle, données de l'ami toujours fraîches.
  Future<List<MangaQuickViewDto>> getFriendLibrary(int friendUserId) async {
    final res = await _http.getWithAuthTokens(
      buildApiUri('/friends/$friendUserId/library'),
    );
    if (!isHttpSuccess(res.statusCode)) throw ApiException.fromResponse(res);
    return (jsonDecode(res.body) as List<dynamic>)
        .map((e) => MangaQuickViewDto.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  /// Demandes reçues en attente. Pas de cache — toujours fresh pour le badge.
  Future<List<FriendshipDto>> getPendingRequests() =>
      _getFriendships('/friends/pending');

  /// Demandes que J'AI envoyées, encore en attente (`GET /friends/sent`).
  /// Ancien serveur sans la route (404) → liste vide, pas une erreur.
  Future<List<FriendshipDto>> getSentRequests() async {
    try {
      return await _getFriendships('/friends/sent');
    } on ApiException catch (e) {
      if (e.statusCode == 404) return const [];
      rethrow;
    }
  }

  /// Envoie une demande d'amitié par username OU userId. 409 si une demande
  /// existe déjà (message du serveur).
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
    if (!isHttpSuccess(res.statusCode)) throw ApiException.fromResponse(res);
    // Invalide le cache amis : une demande acceptée auto (sens inverse)
    // peut avoir fait basculer la relation en `accepted`.
    await invalidateCache();
    return FriendshipDto.fromJson(jsonDecode(res.body));
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
    if (!isHttpSuccess(res.statusCode)) throw ApiException.fromResponse(res);
    await invalidateCache();
    return FriendshipDto.fromJson(jsonDecode(res.body));
  }

  /// Supprime une amitié, refuse une demande reçue ou **annule** une demande
  /// envoyée (même route `DELETE /friends/:id`).
  Future<void> deleteFriendship(int friendshipId) async {
    final res = await _http.deleteWithAuthTokens(
      buildApiUri('/friends/$friendshipId'),
    );
    if (!isHttpSuccess(res.statusCode)) throw ApiException.fromResponse(res);
    await invalidateCache();
  }

  /// Recherche d'utilisateurs (pseudo OU nom affiché, min 2 caractères).
  /// Les personnes déjà liées sont renvoyées avec leur `relation`.
  Future<List<UserSearchResultDto>> searchUsers(String query) async {
    if (query.trim().length < 2) return [];
    final res = await _http.getWithAuthTokens(
      buildApiUri('/friends/search', {'q': query.trim()}),
    );
    if (!isHttpSuccess(res.statusCode)) throw ApiException.fromResponse(res);
    return (jsonDecode(res.body) as List<dynamic>)
        .map((e) => UserSearchResultDto.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  /// Invalide le cache (à appeler après toute mutation côté serveur).
  Future<void> invalidateCache() async {
    await _storage.deleteSecureData(_friendsCacheKey);
    await _storage.deleteSecureData(_friendsCacheAtKey);
  }

  Future<List<FriendshipDto>> _getFriendships(String path) async {
    final res = await _http.getWithAuthTokens(buildApiUri(path));
    if (!isHttpSuccess(res.statusCode)) throw ApiException.fromResponse(res);
    return (jsonDecode(res.body) as List<dynamic>)
        .map((e) => FriendshipDto.fromJson(e as Map<String, dynamic>))
        .toList();
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
