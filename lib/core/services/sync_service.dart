import 'dart:async';
import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:mangatracker/core/service_locator/service_locator.dart';
import 'package:mangatracker/features/library/services/library.service.dart';
import 'connectivity_service.dart';
import 'offline_cache_service.dart';

/// Service de synchronisation des données hors ligne
/// Gère la synchronisation automatique des actions en attente
class SyncService {
  late final ConnectivityService _connectivityService;
  late final OfflineCacheService _cacheService;
  late final LibraryService _libraryService;
  
  StreamSubscription<bool>? _connectivitySubscription;
  bool _isSyncing = false;
  
  /// Initialise le service de synchronisation
  Future<void> initialize() async {
    // Récupérer les dépendances
    _connectivityService = getIt<ConnectivityService>();
    _cacheService = getIt<OfflineCacheService>();
    _libraryService = getIt<LibraryService>();
    
    // Écouter les changements de connectivité
    _connectivitySubscription = _connectivityService.connectivityStream.listen(
      (isConnected) {
        if (isConnected && !_isSyncing) {
          _syncOfflineData();
        }
      },
    );
  }
  
  /// Synchronise les données hors ligne
  Future<void> _syncOfflineData() async {
    if (_isSyncing) return;
    
    _isSyncing = true;
    
    try {
      final queue = await _cacheService.getOfflineQueue();
      
      if (queue.isEmpty) {
        _isSyncing = false;
        return;
      }
      
      debugPrint('🔄 Synchronisation de ${queue.length} actions hors ligne...');
      
      final List<Map<String, dynamic>> failedActions = [];
      
      for (final actionData in queue) {
        try {
          await _processOfflineAction(actionData);
          debugPrint('✅ Action synchronisée: ${actionData['type']} pour manga ${actionData['muId']}');
        } catch (e) {
          debugPrint('❌ Erreur lors de la synchronisation: $e');
          failedActions.add(actionData);
        }
      }
      
      // Mettre à jour la queue avec les actions échouées
      if (failedActions.isNotEmpty) {
        await _cacheService.storage.writeSecureData(
          'offline_queue',
          jsonEncode(failedActions),
        );
        debugPrint('⚠️ ${failedActions.length} actions échouées, seront retentées plus tard');
      } else {
        // Toutes les actions ont réussi, vider la queue
        await _cacheService.clearOfflineQueue();
        debugPrint('✅ Toutes les actions ont été synchronisées');
      }
      
    } catch (e) {
      debugPrint('❌ Erreur générale lors de la synchronisation: $e');
    } finally {
      _isSyncing = false;
    }
  }
  
  /// Traite une action hors ligne
  Future<void> _processOfflineAction(Map<String, dynamic> actionData) async {
    final action = OfflineAction.fromJson(actionData);
    
    bool success = false;
    
    switch (action.type) {
      case 'addManga':
        success = await _libraryService.addMangaToLibrary(action.muId);
        break;
        
      case 'removeManga':
        success = await _libraryService.removeMangaFromLibrary(action.muId);
        break;
        
      case 'updateStatus':
      case 'updateMangaStatus':
        if (action.status != null) {
          success = await _libraryService.updateMangaStatus(action.muId, action.status!);
        } else {
          throw Exception('Statut manquant pour l\'action ${action.type}');
        }
        break;
        
      case 'saveChapterProgress':
        if (action.readChapters != null) {
          success = await _libraryService.saveChapterProgress(action.muId, action.readChapters!);
        } else {
          throw Exception('Nombre de chapitres manquant pour l\'action ${action.type}');
        }
        break;
        
      case 'updateCustomLink':
        if (action.customLink != null) {
          success = await _libraryService.updateCustomLink(action.muId, action.customLink!);
        } else {
          throw Exception('Lien personnalisé manquant pour l\'action ${action.type}');
        }
        break;
        
      case 'deleteCustomLink':
        success = await _libraryService.deleteCustomLink(action.muId);
        break;
        
      default:
        throw Exception('Type d\'action inconnu: ${action.type}');
    }
    
    // Si l'action a échoué, lancer une exception pour qu'elle soit ajoutée à failedActions
    if (!success) {
      throw Exception('Échec de l\'action ${action.type} pour le manga ${action.muId}');
    }
  }
  
  /// Force la synchronisation manuelle
  Future<void> forceSync() async {
    if (!_connectivityService.isConnected) {
      throw Exception('Pas de connexion internet');
    }
    
    await _syncOfflineData();
  }
  
  /// Vérifie s'il y a des actions en attente
  Future<bool> hasPendingActions() async {
    final queue = await _cacheService.getOfflineQueue();
    return queue.isNotEmpty;
  }
  
  /// Récupère le nombre d'actions en attente
  Future<int> getPendingActionsCount() async {
    final queue = await _cacheService.getOfflineQueue();
    return queue.length;
  }
  
  /// Récupère les actions en attente
  Future<List<OfflineAction>> getPendingActions() async {
    final queue = await _cacheService.getOfflineQueue();
    return queue.map((actionData) => OfflineAction.fromJson(actionData)).toList();
  }
  
  /// Libère les ressources
  void dispose() {
    _connectivitySubscription?.cancel();
  }
}
