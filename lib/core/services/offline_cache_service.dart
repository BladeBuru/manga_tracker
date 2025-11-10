import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:mangatracker/core/service_locator/service_locator.dart';
import 'package:mangatracker/core/storage/services/storage.service.dart';
import 'package:mangatracker/features/manga/dto/manga_quick_view.dto.dart';
import 'package:mangatracker/features/manga/dto/manga_detail.dto.dart';
import 'package:mangatracker/features/manga/dto/reading_status.enum.dart';
import 'package:mangatracker/features/profile/dto/user_information.dto.dart';

/// Actions hors ligne à synchroniser
class OfflineAction {
  final String type;
  final int muId;
  final ReadingStatus? status;
  final String? customLink;
  final int? readChapters;
  final DateTime timestamp;
  
  OfflineAction({
    required this.type,
    required this.muId,
    this.status,
    this.customLink,
    this.readChapters,
    DateTime? timestamp,
  }) : timestamp = timestamp ?? DateTime.now();
  
  Map<String, dynamic> toJson() => {
    'type': type,
    'muId': muId,
    'status': status?.name,
    'customLink': customLink,
    'readChapters': readChapters,
    'timestamp': timestamp.toIso8601String(),
  };
  
  factory OfflineAction.fromJson(Map<String, dynamic> json) => OfflineAction(
    type: json['type'],
    muId: json['muId'],
    status: json['status'] != null ? ReadingStatus.values.firstWhere(
      (e) => e.name == json['status']
    ) : null,
    customLink: json['customLink'],
    readChapters: json['readChapters'],
    timestamp: DateTime.parse(json['timestamp']),
  );
  
  // Factory methods pour les différents types d'actions
  static OfflineAction addManga(int muId) => OfflineAction(
    type: 'addManga',
    muId: muId,
  );
  
  static OfflineAction removeManga(int muId) => OfflineAction(
    type: 'removeManga',
    muId: muId,
  );
  
  static OfflineAction saveChapterProgress(int muId, int readChapters) => OfflineAction(
    type: 'saveChapterProgress',
    muId: muId,
    readChapters: readChapters,
  );
  
  static OfflineAction updateMangaStatus(int muId, ReadingStatus status) => OfflineAction(
    type: 'updateMangaStatus',
    muId: muId,
    status: status,
  );
  
  static OfflineAction updateStatus(int muId, ReadingStatus status) => OfflineAction(
    type: 'updateStatus',
    muId: muId,
    status: status,
  );
  
  static OfflineAction updateCustomLink(int muId, String customLink) => OfflineAction(
    type: 'updateCustomLink',
    muId: muId,
    customLink: customLink,
  );
  
  static OfflineAction deleteCustomLink(int muId) => OfflineAction(
    type: 'deleteCustomLink',
    muId: muId,
  );
}

/// Service de gestion du cache hors ligne
/// Permet de mettre en cache les données et de gérer les actions hors ligne
class OfflineCacheService {
  late final StorageService _storage;
  
  /// Getter pour accéder au storage depuis l'extérieur
  StorageService get storage => _storage;
  
  /// Initialise le service avec les dépendances
  void initialize() {
    _storage = getIt<StorageService>();
  }
  
  // Clés de stockage
  static const String _libraryCacheKey = 'cached_library';
  static const String _mangaDetailCacheKey = 'cached_manga_detail_';
  static const String _homePageCacheKey = 'cached_homepage';
  static const String _searchCacheKey = 'cached_search_';
  static const String _userInfoCacheKey = 'cached_user_info';
  static const String _offlineQueueKey = 'offline_queue';
  static const String _lastSyncKey = 'last_sync_timestamp';
  static const String _cacheMetadataKey = 'cache_metadata';
  
  /// Cache la liste de la bibliothèque
  Future<void> cacheLibrary(List<MangaQuickViewDto> mangas) async {
    try {
      final json = mangas.map((m) => m.toJson()).toList();
      await _storage.writeSecureData(_libraryCacheKey, jsonEncode(json));
      await _updateLastSyncTimestamp();
    } catch (e) {
      debugPrint('Erreur lors du cache de la bibliothèque: $e');
    }
  }
  
  /// Récupère la bibliothèque depuis le cache
  Future<List<MangaQuickViewDto>?> getCachedLibrary() async {
    try {
      final cached = await _storage.readSecureData(_libraryCacheKey);
      if (cached != null) {
        final List<dynamic> jsonList = jsonDecode(cached);
        return jsonList.map((json) => MangaQuickViewDto.fromJson(json)).toList();
      }
    } catch (e) {
      debugPrint('Erreur lors de la récupération du cache bibliothèque: $e');
    }
    return null;
  }
  
  /// Cache les détails d'un manga
  Future<void> cacheMangaDetail(int muId, MangaDetailDto mangaDetail) async {
    try {
      final key = '$_mangaDetailCacheKey$muId';
      await _storage.writeSecureData(key, jsonEncode(mangaDetail.toJson()));
    } catch (e) {
      debugPrint('Erreur lors du cache des détails manga: $e');
    }
  }
  
  /// Récupère les détails d'un manga depuis le cache
  Future<MangaDetailDto?> getCachedMangaDetail(int muId) async {
    try {
      final key = '$_mangaDetailCacheKey$muId';
      final cached = await _storage.readSecureData(key);
      if (cached != null) {
        return MangaDetailDto.fromJson(jsonDecode(cached));
      }
    } catch (e) {
      debugPrint('Erreur lors de la récupération du cache détails manga: $e');
    }
    return null;
  }
  
  /// Cache les données de la page d'accueil
  Future<void> cacheHomePageData(List<MangaQuickViewDto> mangas) async {
    try {
      final json = mangas.map((m) => m.toJson()).toList();
      await _storage.writeSecureData(_homePageCacheKey, jsonEncode(json));
      await _updateCacheMetadata('homepage', DateTime.now());
    } catch (e) {
      debugPrint('Erreur lors du cache de la page d\'accueil: $e');
    }
  }
  
  /// Récupère les données de la page d'accueil depuis le cache
  Future<List<MangaQuickViewDto>?> getCachedHomePageData() async {
    try {
      final cached = await _storage.readSecureData(_homePageCacheKey);
      if (cached != null) {
        final List<dynamic> jsonList = jsonDecode(cached);
        return jsonList.map((json) => MangaQuickViewDto.fromJson(json)).toList();
      }
    } catch (e) {
      debugPrint('Erreur lors de la récupération du cache page d\'accueil: $e');
    }
    return null;
  }
  
  /// Cache les résultats de recherche
  Future<void> cacheSearchResults(String query, List<MangaQuickViewDto> results) async {
    try {
      final key = '$_searchCacheKey${query.toLowerCase().replaceAll(' ', '_')}';
      final json = results.map((m) => m.toJson()).toList();
      await _storage.writeSecureData(key, jsonEncode(json));
      await _updateCacheMetadata('search_$query', DateTime.now());
    } catch (e) {
      debugPrint('Erreur lors du cache des résultats de recherche: $e');
    }
  }
  
  /// Récupère les résultats de recherche depuis le cache
  Future<List<MangaQuickViewDto>?> getCachedSearchResults(String query) async {
    try {
      final key = '$_searchCacheKey${query.toLowerCase().replaceAll(' ', '_')}';
      final cached = await _storage.readSecureData(key);
      if (cached != null) {
        final List<dynamic> jsonList = jsonDecode(cached);
        return jsonList.map((json) => MangaQuickViewDto.fromJson(json)).toList();
      }
    } catch (e) {
      debugPrint('Erreur lors de la récupération du cache recherche: $e');
    }
    return null;
  }

  /// Cache les informations utilisateur
  Future<void> cacheUserInformation(UserInformationDto userInfo) async {
    try {
      await _storage.writeSecureData(_userInfoCacheKey, jsonEncode(userInfo.toJson()));
      await _updateCacheMetadata('user_info', DateTime.now());
    } catch (e) {
      debugPrint('Erreur lors du cache des informations utilisateur: $e');
    }
  }

  /// Récupère les informations utilisateur depuis le cache
  Future<UserInformationDto?> getCachedUserInformation() async {
    try {
      final cached = await _storage.readSecureData(_userInfoCacheKey);
      if (cached != null) {
        return UserInformationDto.fromJson(jsonDecode(cached));
      }
    } catch (e) {
      debugPrint('Erreur lors de la récupération du cache informations utilisateur: $e');
    }
    return null;
  }
  
  /// Ajoute une action à la queue hors ligne
  Future<void> queueOfflineAction(OfflineAction action) async {
    try {
      final existing = await getOfflineQueue();
      existing.add(action.toJson());
      await _storage.writeSecureData(_offlineQueueKey, jsonEncode(existing));
    } catch (e) {
      debugPrint('Erreur lors de l\'ajout à la queue hors ligne: $e');
    }
  }
  
  /// Récupère la queue des actions hors ligne
  Future<List<Map<String, dynamic>>> getOfflineQueue() async {
    try {
      final cached = await _storage.readSecureData(_offlineQueueKey);
      if (cached != null) {
        return List<Map<String, dynamic>>.from(jsonDecode(cached));
      }
    } catch (e) {
      debugPrint('Erreur lors de la récupération de la queue hors ligne: $e');
    }
    return [];
  }
  
  /// Vide la queue des actions hors ligne
  Future<void> clearOfflineQueue() async {
    try {
      await _storage.deleteSecureData(_offlineQueueKey);
    } catch (e) {
      debugPrint('Erreur lors du vidage de la queue hors ligne: $e');
    }
  }
  
  /// Met à jour le timestamp de la dernière synchronisation
  Future<void> _updateLastSyncTimestamp() async {
    await _storage.writeSecureData(_lastSyncKey, DateTime.now().toIso8601String());
  }
  
  /// Récupère le timestamp de la dernière synchronisation
  Future<DateTime?> getLastSyncTimestamp() async {
    try {
      final cached = await _storage.readSecureData(_lastSyncKey);
      if (cached != null) {
        return DateTime.parse(cached);
      }
    } catch (e) {
      debugPrint('Erreur lors de la récupération du timestamp de sync: $e');
    }
    return null;
  }
  
  /// Vérifie si le cache est expiré.
  /// Retourne toujours `false` pour conserver les données tant qu'un nouveau fetch n'est pas effectué.
  Future<bool> isCacheExpired() async {
    return false;
  }
  
  /// Nettoie le cache expiré
  Future<void> clearExpiredCache() async {
    try {
      if (await isCacheExpired()) {
        await _storage.deleteSecureData(_libraryCacheKey);
        // Note: On garde les détails de manga car ils changent moins souvent
      }
    } catch (e) {
      debugPrint('Erreur lors du nettoyage du cache expiré: $e');
    }
  }
  
  /// Nettoie tout le cache
  Future<void> clearAllCache() async {
    try {
      await _storage.deleteSecureData(_libraryCacheKey);
      await _storage.deleteSecureData(_homePageCacheKey);
      await _storage.deleteSecureData(_userInfoCacheKey);
      await _storage.deleteSecureData(_offlineQueueKey);
      await _storage.deleteSecureData(_lastSyncKey);
      await _storage.deleteSecureData(_cacheMetadataKey);
    } catch (e) {
      debugPrint('Erreur lors du nettoyage complet du cache: $e');
    }
  }
  
  /// Met à jour les métadonnées du cache
  Future<void> _updateCacheMetadata(String cacheType, DateTime timestamp) async {
    try {
      final existing = await getCacheMetadata();
      existing[cacheType] = timestamp.toIso8601String();
      await _storage.writeSecureData(_cacheMetadataKey, jsonEncode(existing));
    } catch (e) {
      debugPrint('Erreur lors de la mise à jour des métadonnées: $e');
    }
  }
  
  /// Récupère les métadonnées du cache
  Future<Map<String, String>> getCacheMetadata() async {
    try {
      final cached = await _storage.readSecureData(_cacheMetadataKey);
      if (cached != null) {
        return Map<String, String>.from(jsonDecode(cached));
      }
    } catch (e) {
      debugPrint('Erreur lors de la récupération des métadonnées: $e');
    }
    return {};
  }
  
  /// Vérifie si un cache spécifique est expiré.
  /// Retourne toujours `false` pour conserver les données tant qu'un nouveau fetch n'est pas effectué.
  Future<bool> isCacheExpiredFor(String cacheType, {int maxHours = 24}) async {
    return false;
  }
  
  /// Nettoie les caches expirés (sauf bibliothèque et détails de manga de la bibliothèque)
  Future<void> cleanExpiredCaches() async {
    try {
      // Nettoyer la page d'accueil si expirée
      if (await isCacheExpiredFor('homepage', maxHours: 24)) {
        await _storage.deleteSecureData(_homePageCacheKey);
        debugPrint('Cache page d\'accueil nettoyé (expiré)');
      }
      
      // Nettoyer les recherches expirées
      final metadata = await getCacheMetadata();
      for (final key in metadata.keys) {
        if (key.startsWith('search_') && await isCacheExpiredFor(key, maxHours: 72)) {
          final query = key.replaceFirst('search_', '');
          final searchKey = '$_searchCacheKey${query.toLowerCase().replaceAll(' ', '_')}';
          await _storage.deleteSecureData(searchKey);
          debugPrint('Cache recherche "$query" nettoyé (expiré)');
        }
      }
    } catch (e) {
      debugPrint('Erreur lors du nettoyage des caches expirés: $e');
    }
  }
  
  /// Récupère les statistiques du cache
  Future<Map<String, dynamic>> getCacheStats() async {
    try {
      final metadata = await getCacheMetadata();
      final library = await getCachedLibrary();
      final homepage = await getCachedHomePageData();
      final queue = await getOfflineQueue();
      
      return {
        'library_count': library?.length ?? 0,
        'homepage_count': homepage?.length ?? 0,
        'pending_actions': queue.length,
        'last_sync': await getLastSyncTimestamp(),
        'cache_entries': metadata.length,
      };
    } catch (e) {
      debugPrint('Erreur lors de la récupération des stats: $e');
      return {};
    }
  }
}
