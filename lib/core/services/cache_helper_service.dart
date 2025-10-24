import 'package:mangatracker/core/service_locator/service_locator.dart';
import 'package:mangatracker/features/manga/dto/manga_quick_view.dto.dart';
import 'package:mangatracker/features/manga/dto/manga_detail.dto.dart';
import 'connectivity_service.dart';
import 'offline_cache_service.dart';

/// Service helper pour faciliter l'utilisation du cache dans les vues
/// Fournit des méthodes simples pour charger les données avec fallback cache
class CacheHelperService {
  final ConnectivityService _connectivityService = getIt<ConnectivityService>();
  final OfflineCacheService _cacheService = getIt<OfflineCacheService>();
  
  /// Charge les données de la bibliothèque avec fallback cache
  Future<List<MangaQuickViewDto>> loadLibraryData({
    required Future<List<MangaQuickViewDto>> Function() networkCall,
  }) async {
    final isOnline = _connectivityService.isConnected;
    
    if (isOnline) {
      try {
        // Essayer de charger depuis le réseau
        final data = await networkCall();
        // Mettre en cache
        await _cacheService.cacheLibrary(data);
        return data;
      } catch (e) {
        print('Erreur réseau, fallback vers cache: $e');
        // Fallback vers le cache
        final cached = await _cacheService.getCachedLibrary();
        if (cached != null) {
          return cached;
        }
        rethrow;
      }
    } else {
      // Mode hors ligne : utiliser le cache
      final cached = await _cacheService.getCachedLibrary();
      if (cached != null) {
        return cached;
      }
      throw Exception('Aucune donnée en cache. Connexion requise.');
    }
  }
  
  /// Charge les données de la page d'accueil avec fallback cache
  Future<List<MangaQuickViewDto>> loadHomePageData({
    required Future<List<MangaQuickViewDto>> Function() networkCall,
  }) async {
    final isOnline = _connectivityService.isConnected;
    
    if (isOnline) {
      try {
        // Essayer de charger depuis le réseau
        final data = await networkCall();
        // Mettre en cache
        await _cacheService.cacheHomePageData(data);
        return data;
      } catch (e) {
        print('Erreur réseau, fallback vers cache: $e');
        // Fallback vers le cache
        final cached = await _cacheService.getCachedHomePageData();
        if (cached != null) {
          return cached;
        }
        rethrow;
      }
    } else {
      // Mode hors ligne : utiliser le cache
      final cached = await _cacheService.getCachedHomePageData();
      if (cached != null) {
        return cached;
      }
      throw Exception('Aucune donnée en cache. Connexion requise.');
    }
  }
  
  /// Charge les détails d'un manga avec fallback cache
  Future<MangaDetailDto> loadMangaDetail({
    required int muId,
    required Future<MangaDetailDto> Function() networkCall,
  }) async {
    final isOnline = _connectivityService.isConnected;
    
    // Toujours essayer le cache d'abord (plus rapide)
    final cached = await _cacheService.getCachedMangaDetail(muId);
    if (cached != null && !isOnline) {
      return cached;
    }
    
    if (isOnline) {
      try {
        // Essayer de charger depuis le réseau
        final data = await networkCall();
        // Mettre en cache
        await _cacheService.cacheMangaDetail(muId, data);
        return data;
      } catch (e) {
        print('Erreur réseau, fallback vers cache: $e');
        // Fallback vers le cache
        if (cached != null) {
          return cached;
        }
        rethrow;
      }
    } else {
      // Mode hors ligne : utiliser le cache
      if (cached != null) {
        return cached;
      }
      throw Exception('Aucune donnée en cache. Connexion requise.');
    }
  }
  
  /// Charge les résultats de recherche avec fallback cache
  Future<List<MangaQuickViewDto>> loadSearchResults({
    required String query,
    required Future<List<MangaQuickViewDto>> Function() networkCall,
  }) async {
    final isOnline = _connectivityService.isConnected;
    
    if (isOnline) {
      try {
        // Essayer de charger depuis le réseau
        final data = await networkCall();
        // Mettre en cache
        await _cacheService.cacheSearchResults(query, data);
        return data;
      } catch (e) {
        print('Erreur réseau, fallback vers cache: $e');
        // Fallback vers le cache
        final cached = await _cacheService.getCachedSearchResults(query);
        if (cached != null) {
          return cached;
        }
        rethrow;
      }
    } else {
      // Mode hors ligne : utiliser le cache
      final cached = await _cacheService.getCachedSearchResults(query);
      if (cached != null) {
        return cached;
      }
      throw Exception('Aucune donnée en cache. Connexion requise.');
    }
  }
  
  /// Vérifie si des données sont disponibles en cache
  Future<bool> hasCachedData(String dataType) async {
    switch (dataType) {
      case 'library':
        final cached = await _cacheService.getCachedLibrary();
        return cached != null && cached.isNotEmpty;
      case 'homepage':
        final cached = await _cacheService.getCachedHomePageData();
        return cached != null && cached.isNotEmpty;
      default:
        return false;
    }
  }
  
  /// Récupère les statistiques du cache
  Future<Map<String, dynamic>> getCacheStats() async {
    return await _cacheService.getCacheStats();
  }
  
  /// Nettoie les caches expirés
  Future<void> cleanExpiredCaches() async {
    await _cacheService.cleanExpiredCaches();
  }
  
  /// Récupère la bibliothèque depuis le cache
  Future<List<MangaQuickViewDto>?> getCachedLibrary() async {
    return await _cacheService.getCachedLibrary();
  }
  
  /// Récupère la queue des actions hors ligne
  Future<List<OfflineAction>> getOfflineQueue() async {
    final queue = await _cacheService.getOfflineQueue();
    return queue.map((actionData) => OfflineAction.fromJson(actionData)).toList();
  }
}
