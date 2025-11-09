import 'dart:async';
import 'package:bloc/bloc.dart';
import 'package:flutter/foundation.dart';
import 'package:mangatracker/core/service_locator/service_locator.dart';
import 'package:mangatracker/core/services/cache_helper_service.dart';
import 'package:mangatracker/core/services/connectivity_service.dart';
import 'package:mangatracker/features/library/services/library.service.dart';
import 'package:mangatracker/features/manga/dto/manga_quick_view.dto.dart';
import 'library_event.dart';
import 'library_state.dart';

/// BLoC pour la gestion de la bibliothèque
class LibraryBloc extends Bloc<LibraryEvent, LibraryState> {
  final LibraryService _libraryService = getIt<LibraryService>();
  final CacheHelperService _cacheHelper = getIt<CacheHelperService>();
  final ConnectivityService _connectivityService = getIt<ConnectivityService>();
  
  StreamSubscription<bool>? _connectivitySubscription;
  StreamSubscription<List<MangaQuickViewDto>>? _librarySubscription;

  LibraryBloc() : super(const LibraryInitial()) {
    on<LoadLibrary>(_onLoadLibrary);
    on<AddMangaToLibrary>(_onAddMangaToLibrary);
    on<RemoveMangaFromLibrary>(_onRemoveMangaFromLibrary);
    on<UpdateMangaStatus>(_onUpdateMangaStatus);
    on<SaveChapterProgress>(_onSaveChapterProgress);
    on<UpdateCustomLink>(_onUpdateCustomLink);
    on<DeleteCustomLink>(_onDeleteCustomLink);
    on<RefreshLibrary>(_onRefreshLibrary);
    
    _initializeConnectivityListener();
    _checkInitialConnectivity();
  }

  @override
  Future<void> close() {
    _connectivitySubscription?.cancel();
    _librarySubscription?.cancel();
    return super.close();
  }

  /// Initialise l'écoute de la connectivité
  void _initializeConnectivityListener() {
    // L'état offline est maintenant détecté directement via les erreurs réseau
    // Plus besoin de mettre à jour l'état via le listener
    _connectivitySubscription = _connectivityService.connectivityStream.listen(
      (isConnected) {
        // L'état sera mis à jour automatiquement lors des prochains chargements
      },
    );
  }

  /// Charge la bibliothèque
  Future<void> _onLoadLibrary(LoadLibrary event, Emitter<LibraryState> emit) async {
    debugPrint('🔄 LibraryBloc: Début du chargement de la bibliothèque...');

    final cachedMangas = await _cacheHelper.getCachedLibrary();
    final hasCachedData = cachedMangas != null && cachedMangas.isNotEmpty;

    if (hasCachedData) {
      final pendingCached = await _getPendingActionsCount();
      final List<MangaQuickViewDto> cachedList = cachedMangas;
      emit(LibraryLoaded(
        mangas: cachedList,
        isOffline: false,
        pendingActions: pendingCached,
        stale: true,
      ));
    } else {
      emit(const LibraryLoading());
    }
    
    try {
      debugPrint('🔄 LibraryBloc: Tentative de chargement depuis le réseau...');
      final mangas = await _cacheHelper.loadLibraryData(
        networkCall: () => _libraryService.getUserSavedMangas(),
      );
      
      final pendingActions = await _getPendingActionsCount();
      
      // Si aucune erreur, on est online
      debugPrint('✅ LibraryBloc: Données chargées depuis le réseau - ${mangas.length} mangas, $pendingActions actions en attente');
      emit(LibraryLoaded(
        mangas: mangas,
        isOffline: false,
        pendingActions: pendingActions,
        stale: false,
      ));
    } catch (e) {
      // Ne pas traiter InvalidCredentialsException comme une erreur réseau
      if (e.toString().contains('InvalidCredentialsException')) {
        debugPrint('⚠️ LibraryBloc: Erreur d\'authentification, redirection vers login');
        emit(LibraryError(
          message: 'Authentification requise',
          isOffline: false,
        ));
        return;
      }
      
      // Erreur réseau détectée : on est offline
      debugPrint('⚠️ LibraryBloc: Erreur de chargement de la bibliothèque: $e');
      debugPrint('⚠️ LibraryBloc: Tentative de récupération depuis le cache...');
      
      try {
        final fallbackMangas = cachedMangas ?? await _cacheHelper.getCachedLibrary();
        if (fallbackMangas != null && fallbackMangas.isNotEmpty) {
          final pendingActions = await _getPendingActionsCount();
          debugPrint('✅ LibraryBloc: Données de la bibliothèque chargées depuis le cache (mode offline) - ${fallbackMangas.length} mangas, $pendingActions actions en attente');
          emit(LibraryLoaded(
            mangas: fallbackMangas,
            isOffline: true,
            pendingActions: pendingActions,
            stale: true,
          ));
        } else {
          debugPrint('❌ LibraryBloc: Aucune donnée en cache disponible');
          emit(LibraryError(
            message: e.toString(),
            isOffline: true,
          ));
        }
      } catch (cacheError) {
        debugPrint('❌ LibraryBloc: Erreur lors de la récupération du cache: $cacheError');
        emit(LibraryError(
          message: e.toString(),
          isOffline: true,
        ));
      }
    }
  }

  /// Ajoute un manga à la bibliothèque
  Future<void> _onAddMangaToLibrary(AddMangaToLibrary event, Emitter<LibraryState> emit) async {
    if (state is! LibraryLoaded) return;
    
    final currentState = state as LibraryLoaded;
    emit(LibraryActionInProgress(
      mangas: currentState.mangas,
      action: 'Ajout en cours...',
      isOffline: currentState.isOffline,
    ));
    
    try {
      final success = await _libraryService.addMangaToLibrary(event.muId);
      
      if (success) {
        // Recharger la bibliothèque
        add(const LoadLibrary());
      } else {
        emit(LibraryError(
          message: 'Erreur lors de l\'ajout du manga',
          isOffline: currentState.isOffline,
          cachedMangas: currentState.mangas,
        ));
      }
    } catch (e) {
      emit(LibraryError(
        message: e.toString(),
        isOffline: currentState.isOffline,
        cachedMangas: currentState.mangas,
      ));
    }
  }

  /// Supprime un manga de la bibliothèque
  Future<void> _onRemoveMangaFromLibrary(RemoveMangaFromLibrary event, Emitter<LibraryState> emit) async {
    if (state is! LibraryLoaded) return;
    
    final currentState = state as LibraryLoaded;
    emit(LibraryActionInProgress(
      mangas: currentState.mangas,
      action: 'Suppression en cours...',
      isOffline: currentState.isOffline,
    ));
    
    try {
      final success = await _libraryService.removeMangaFromLibrary(event.muId);
      
      if (success) {
        // Recharger la bibliothèque
        add(const LoadLibrary());
      } else {
        emit(LibraryError(
          message: 'Erreur lors de la suppression du manga',
          isOffline: currentState.isOffline,
          cachedMangas: currentState.mangas,
        ));
      }
    } catch (e) {
      emit(LibraryError(
        message: e.toString(),
        isOffline: currentState.isOffline,
        cachedMangas: currentState.mangas,
      ));
    }
  }

  /// Met à jour le statut de lecture d'un manga
  Future<void> _onUpdateMangaStatus(UpdateMangaStatus event, Emitter<LibraryState> emit) async {
    if (state is! LibraryLoaded) return;
    
    final currentState = state as LibraryLoaded;
    emit(LibraryActionInProgress(
      mangas: currentState.mangas,
      action: 'Mise à jour du statut...',
      isOffline: currentState.isOffline,
    ));
    
    try {
      final success = await _libraryService.updateMangaStatus(event.muId, event.status);
      
      if (success) {
        // Recharger la bibliothèque
        add(const LoadLibrary());
      } else {
        emit(LibraryError(
          message: 'Erreur lors de la mise à jour du statut',
          isOffline: currentState.isOffline,
          cachedMangas: currentState.mangas,
        ));
      }
    } catch (e) {
      emit(LibraryError(
        message: e.toString(),
        isOffline: currentState.isOffline,
        cachedMangas: currentState.mangas,
      ));
    }
  }

  /// Sauvegarde la progression de lecture
  Future<void> _onSaveChapterProgress(SaveChapterProgress event, Emitter<LibraryState> emit) async {
    if (state is! LibraryLoaded) return;
    
    final currentState = state as LibraryLoaded;
    emit(LibraryActionInProgress(
      mangas: currentState.mangas,
      action: 'Sauvegarde de la progression...',
      isOffline: currentState.isOffline,
    ));
    
    try {
      final success = await _libraryService.saveChapterProgress(event.muId, event.readChapters);
      
      if (success) {
        // Recharger la bibliothèque
        add(const LoadLibrary());
      } else {
        emit(LibraryError(
          message: 'Erreur lors de la sauvegarde de la progression',
          isOffline: currentState.isOffline,
          cachedMangas: currentState.mangas,
        ));
      }
    } catch (e) {
      emit(LibraryError(
        message: e.toString(),
        isOffline: currentState.isOffline,
        cachedMangas: currentState.mangas,
      ));
    }
  }

  /// Met à jour le lien personnalisé
  Future<void> _onUpdateCustomLink(UpdateCustomLink event, Emitter<LibraryState> emit) async {
    if (state is! LibraryLoaded) return;
    
    final currentState = state as LibraryLoaded;
    emit(LibraryActionInProgress(
      mangas: currentState.mangas,
      action: 'Mise à jour du lien...',
      isOffline: currentState.isOffline,
    ));
    
    try {
      final success = await _libraryService.updateCustomLink(event.muId, event.customLink);
      
      if (success) {
        // Recharger la bibliothèque
        add(const LoadLibrary());
      } else {
        emit(LibraryError(
          message: 'Erreur lors de la mise à jour du lien',
          isOffline: currentState.isOffline,
          cachedMangas: currentState.mangas,
        ));
      }
    } catch (e) {
      emit(LibraryError(
        message: e.toString(),
        isOffline: currentState.isOffline,
        cachedMangas: currentState.mangas,
      ));
    }
  }

  /// Supprime le lien personnalisé
  Future<void> _onDeleteCustomLink(DeleteCustomLink event, Emitter<LibraryState> emit) async {
    if (state is! LibraryLoaded) return;
    
    final currentState = state as LibraryLoaded;
    emit(LibraryActionInProgress(
      mangas: currentState.mangas,
      action: 'Suppression du lien...',
      isOffline: currentState.isOffline,
    ));
    
    try {
      final success = await _libraryService.deleteCustomLink(event.muId);
      
      if (success) {
        // Recharger la bibliothèque
        add(const LoadLibrary());
      } else {
        emit(LibraryError(
          message: 'Erreur lors de la suppression du lien',
          isOffline: currentState.isOffline,
          cachedMangas: currentState.mangas,
        ));
      }
    } catch (e) {
      emit(LibraryError(
        message: e.toString(),
        isOffline: currentState.isOffline,
        cachedMangas: currentState.mangas,
      ));
    }
  }

  /// Rafraîchit la bibliothèque
  Future<void> _onRefreshLibrary(RefreshLibrary event, Emitter<LibraryState> emit) async {
    add(const LoadLibrary());
  }

  /// Récupère le nombre d'actions en attente
  Future<int> _getPendingActionsCount() async {
    try {
      final queue = await _cacheHelper.getOfflineQueue();
      return queue.length;
    } catch (e) {
      return 0;
    }
  }

  /// Vérifie l'état initial de la connectivité
  Future<void> _checkInitialConnectivity() async {
    try {
      final isConnected = await _connectivityService.checkConnectivity();
      // Cette information sera utilisée lors du premier chargement
      debugPrint('🔍 État initial de connectivité: ${isConnected ? "Connecté" : "Hors ligne"}');
    } catch (e) {
      debugPrint('⚠️ Erreur lors de la vérification de connectivité: $e');
    }
  }
}
