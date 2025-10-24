import 'dart:async';
import 'package:bloc/bloc.dart';
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
    _connectivitySubscription = _connectivityService.connectivityStream.listen(
      (isConnected) {
        // Mettre à jour l'état de connectivité dans tous les cas
        if (state is LibraryLoaded) {
          final currentState = state as LibraryLoaded;
          emit(currentState.copyWith(isOffline: !isConnected));
        } else if (state is LibraryError) {
          final currentState = state as LibraryError;
          emit(LibraryError(
            message: currentState.message,
            isOffline: !isConnected,
            cachedMangas: currentState.cachedMangas,
          ));
        }
      },
    );
  }

  /// Charge la bibliothèque
  Future<void> _onLoadLibrary(LoadLibrary event, Emitter<LibraryState> emit) async {
    try {
      emit(const LibraryLoading());
      
      final isOffline = !_connectivityService.isConnected;
      final mangas = await _cacheHelper.loadLibraryData(
        networkCall: () => _libraryService.getUserSavedMangas(),
      );
      
      final pendingActions = await _getPendingActionsCount();
      
      emit(LibraryLoaded(
        mangas: mangas,
        isOffline: isOffline,
        pendingActions: pendingActions,
      ));
    } catch (e) {
      // En cas d'erreur, essayer de charger depuis le cache
      try {
        final cachedMangas = await _cacheHelper.getCachedLibrary();
        if (cachedMangas != null && cachedMangas.isNotEmpty) {
          emit(LibraryLoaded(
            mangas: cachedMangas,
            isOffline: true,
            pendingActions: await _getPendingActionsCount(),
          ));
        } else {
          emit(LibraryError(
            message: e.toString(),
            isOffline: !_connectivityService.isConnected,
          ));
        }
      } catch (cacheError) {
        emit(LibraryError(
          message: e.toString(),
          isOffline: !_connectivityService.isConnected,
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
      print('🔍 État initial de connectivité: ${isConnected ? "Connecté" : "Hors ligne"}');
    } catch (e) {
      print('⚠️ Erreur lors de la vérification de connectivité: $e');
    }
  }
}
