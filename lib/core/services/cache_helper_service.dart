import 'package:mangatracker/core/service_locator/service_locator.dart';
import 'package:mangatracker/features/manga/dto/manga_quick_view.dto.dart';
import 'package:mangatracker/features/manga/dto/manga_detail.dto.dart';
import 'offline_cache_service.dart';

/// Service helper pour faciliter l'utilisation du cache dans les vues
/// Fournit des méthodes simples pour charger les données avec fallback cache
class CacheHelperService {
  final OfflineCacheService _cacheService = getIt<OfflineCacheService>();
  
  /// Charge les données de la bibliothèque avec fallback cache
  Future<List<MangaQuickViewDto>> loadLibraryData({
    required Future<List<MangaQuickViewDto>> Function() networkCall,
  }) async {
    // Toujours essayer le réseau d'abord
    try {
      final data = await networkCall();
      // Mettre en cache
      await _cacheService.cacheLibrary(data);
      return data;
    } catch (e) {
      print('Erreur réseau, fallback vers cache: $e');
      // Laisser l'exception remonter pour que les BLoCs puissent détecter l'erreur réseau
      rethrow;
    }
  }
  
  /// Charge les données de la page d'accueil avec fallback cache
  Future<List<MangaQuickViewDto>> loadHomePageData({
    required Future<List<MangaQuickViewDto>> Function() networkCall,
  }) async {
    // Toujours essayer le réseau d'abord
    try {
      final data = await networkCall();
      // Mettre en cache
      await _cacheService.cacheHomePageData(data);
      return data;
    } catch (e) {
      print('Erreur réseau, fallback vers cache: $e');
      // Laisser l'exception remonter pour que les BLoCs puissent détecter l'erreur réseau
      rethrow;
    }
  }
  
  /// Charge les détails d'un manga avec fallback cache
  Future<MangaDetailDto> loadMangaDetail({
    required int muId,
    required Future<MangaDetailDto> Function() networkCall,
  }) async {
    // Toujours essayer le réseau d'abord
    try {
      final data = await networkCall();
      await _cacheService.cacheMangaDetail(muId, data);
      return data;
    } catch (e) {
      print('Erreur réseau, fallback vers cache: $e');
      // Laisser l'exception remonter pour que les BLoCs puissent détecter l'erreur réseau
      rethrow;
    }
  }
  
  /// Charge les résultats de recherche avec fallback cache
  Future<List<MangaQuickViewDto>> loadSearchResults({
    required String query,
    required Future<List<MangaQuickViewDto>> Function() networkCall,
  }) async {
    // Toujours essayer le réseau d'abord
    try {
      final data = await networkCall();
      // Mettre en cache
      await _cacheService.cacheSearchResults(query, data);
      return data;
    } catch (e) {
      print('Erreur réseau, fallback vers cache: $e');
      // Laisser l'exception remonter pour que les BLoCs puissent détecter l'erreur réseau
      rethrow;
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
  
  /// Récupère les données de la page d'accueil depuis le cache
  Future<List<MangaQuickViewDto>?> getCachedHomePageData() async {
    return await _cacheService.getCachedHomePageData();
  }
  
  /// Récupère les détails d'un manga depuis le cache
  Future<MangaDetailDto?> getCachedMangaDetail(int muId) async {
    return await _cacheService.getCachedMangaDetail(muId);
  }
}
