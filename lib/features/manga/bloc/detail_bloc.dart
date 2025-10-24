import 'dart:async';
import 'package:bloc/bloc.dart';
import 'package:mangatracker/core/service_locator/service_locator.dart';
import 'package:mangatracker/core/services/cache_helper_service.dart';
import 'package:mangatracker/core/services/connectivity_service.dart';
import 'package:mangatracker/features/library/services/library.service.dart';
import 'package:mangatracker/features/manga/services/manga.service.dart';
import 'package:mangatracker/features/manga/dto/manga_detail.dto.dart';
import 'package:mangatracker/features/manga/dto/reading_status.enum.dart';
import 'detail_event.dart';
import 'detail_state.dart';

/// BLoC pour la gestion des détails de manga
class DetailBloc extends Bloc<DetailEvent, DetailState> {
  final MangaService _mangaService = getIt<MangaService>();
  final LibraryService _libraryService = getIt<LibraryService>();
  final CacheHelperService _cacheHelper = getIt<CacheHelperService>();
  final ConnectivityService _connectivityService = getIt<ConnectivityService>();
  
  StreamSubscription<bool>? _connectivitySubscription;
  int? _currentMuId;

  DetailBloc() : super(const DetailInitial()) {
    on<LoadMangaDetail>(_onLoadMangaDetail);
    on<RefreshMangaDetail>(_onRefreshMangaDetail);
    on<AddToLibrary>(_onAddToLibrary);
    on<RemoveFromLibrary>(_onRemoveFromLibrary);
    on<UpdateReadingStatus>(_onUpdateReadingStatus);
    on<SaveChapterProgress>(_onSaveChapterProgress);
    on<UpdateCustomLink>(_onUpdateCustomLink);
    on<DeleteCustomLink>(_onDeleteCustomLink);
    
    _initializeConnectivityListener();
  }

  @override
  Future<void> close() {
    _connectivitySubscription?.cancel();
    return super.close();
  }

  /// Initialise l'écoute de la connectivité
  void _initializeConnectivityListener() {
    _connectivitySubscription = _connectivityService.connectivityStream.listen(
      (isConnected) {
        // Mettre à jour l'état de connectivité dans tous les cas
        if (state is DetailLoaded) {
          final currentState = state as DetailLoaded;
          emit(currentState.copyWith(isOffline: !isConnected));
        } else if (state is DetailError) {
          final currentState = state as DetailError;
          emit(DetailError(
            message: currentState.message,
            isOffline: !isConnected,
            cachedMangaDetail: currentState.cachedMangaDetail,
          ));
        }
      },
    );
  }

  /// Charge les détails d'un manga
  Future<void> _onLoadMangaDetail(LoadMangaDetail event, Emitter<DetailState> emit) async {
    print('🔄 DetailBloc: Chargement du manga ${event.muId}...');
    try {
      emit(const DetailLoading());
      _currentMuId = event.muId;
      
      final isOffline = !_connectivityService.isConnected;
      final mangaDetail = await _cacheHelper.loadMangaDetail(
        muId: event.muId,
        networkCall: () => _mangaService.getMangaDetail(event.muId.toString()),
      );
      
      final pendingActions = await _getPendingActionsCount();
      
      // Récupérer le statut de lecture et le nombre de chapitres lus depuis la bibliothèque si le manga y est
      MangaDetailDto updatedMangaDetail = mangaDetail;
      try {
        final libraryStatus = await _libraryService.getReadingStatusByUid(event.muId);
        final readChaptersCount = await _libraryService.getReadChapterByUid(event.muId);
        
        if (libraryStatus != null) {
          // Le manga est dans la bibliothèque, mettre à jour le statut et le nombre de chapitres lus
          updatedMangaDetail = MangaDetailDto(
            muId: mangaDetail.muId,
            title: mangaDetail.title,
            description: mangaDetail.description,
            status: mangaDetail.status,
            publicationStatus: mangaDetail.publicationStatus,
            year: mangaDetail.year,
            smallCoverUrl: mangaDetail.smallCoverUrl,
            mediumCoverUrl: mangaDetail.mediumCoverUrl,
            largeCoverUrl: mangaDetail.largeCoverUrl,
            rating: mangaDetail.rating,
            totalChapters: mangaDetail.totalChapters,
            isCompleted: mangaDetail.isCompleted,
            authors: mangaDetail.authors,
            genres: mangaDetail.genres,
            customLink: mangaDetail.customLink,
            inLibrary: true,
            readChaptersCount: readChaptersCount >= 0 ? readChaptersCount.toInt() : null,
            readingStatus: libraryStatus,
            associated: mangaDetail.associated,
            recommendations: mangaDetail.recommendations,
            type: mangaDetail.type,
            seasonChapters: mangaDetail.seasonChapters,
            bonusChapters: mangaDetail.bonusChapters,
          );
          print('📚 DetailBloc: Manga trouvé dans la bibliothèque avec statut: ${libraryStatus.name} et ${readChaptersCount} chapitres lus');
        } else {
          print('📚 DetailBloc: Manga non trouvé dans la bibliothèque');
        }
      } catch (e) {
        print('⚠️ DetailBloc: Erreur lors de la récupération du statut: $e');
        // Continuer avec les détails de base si la récupération du statut échoue
      }
      
      emit(DetailLoaded(
        mangaDetail: updatedMangaDetail,
        isOffline: isOffline,
        pendingActions: pendingActions,
      ));
    } catch (e) {
      // En cas d'erreur, essayer de charger depuis le cache
      try {
        final cachedMangaDetail = await _cacheHelper.getCachedMangaDetail(event.muId);
        if (cachedMangaDetail != null) {
          emit(DetailLoaded(
            mangaDetail: cachedMangaDetail,
            isOffline: true,
            pendingActions: await _getPendingActionsCount(),
          ));
        } else {
          emit(DetailError(
            message: e.toString(),
            isOffline: !_connectivityService.isConnected,
          ));
        }
      } catch (cacheError) {
        emit(DetailError(
          message: e.toString(),
          isOffline: !_connectivityService.isConnected,
        ));
      }
    }
  }

  /// Rafraîchit les détails
  Future<void> _onRefreshMangaDetail(RefreshMangaDetail event, Emitter<DetailState> emit) async {
    if (_currentMuId != null) {
      add(LoadMangaDetail(_currentMuId!));
    }
  }

  /// Ajoute le manga à la bibliothèque
  Future<void> _onAddToLibrary(AddToLibrary event, Emitter<DetailState> emit) async {
    if (state is! DetailLoaded) return;
    
    final currentState = state as DetailLoaded;
    emit(DetailActionInProgress(
      mangaDetail: currentState.mangaDetail,
      action: 'Ajout à la bibliothèque...',
      isOffline: currentState.isOffline,
    ));
    
    try {
      print('📚 DetailBloc: Ajout du manga ${event.muId} à la bibliothèque...');
      final success = await _libraryService.addMangaToLibrary(event.muId);
      
      if (success) {
        // Mettre à jour l'état local sans recharger
        print('✅ DetailBloc: Manga ajouté, mise à jour locale de l\'état...');
        final updatedMangaDetail = MangaDetailDto(
          muId: currentState.mangaDetail.muId,
          title: currentState.mangaDetail.title,
          description: currentState.mangaDetail.description,
          status: currentState.mangaDetail.status,
          publicationStatus: currentState.mangaDetail.publicationStatus,
          year: currentState.mangaDetail.year,
          smallCoverUrl: currentState.mangaDetail.smallCoverUrl,
          mediumCoverUrl: currentState.mangaDetail.mediumCoverUrl,
          largeCoverUrl: currentState.mangaDetail.largeCoverUrl,
          rating: currentState.mangaDetail.rating,
          totalChapters: currentState.mangaDetail.totalChapters,
          isCompleted: currentState.mangaDetail.isCompleted,
          authors: currentState.mangaDetail.authors,
          genres: currentState.mangaDetail.genres,
          customLink: currentState.mangaDetail.customLink,
          inLibrary: true, // Le manga est maintenant dans la bibliothèque
          readChaptersCount: 0, // Réinitialiser le nombre de chapitres lus
          readingStatus: ReadingStatus.readLater, // Statut par défaut lors de l'ajout
          associated: currentState.mangaDetail.associated,
          recommendations: currentState.mangaDetail.recommendations,
          type: currentState.mangaDetail.type,
          seasonChapters: currentState.mangaDetail.seasonChapters,
          bonusChapters: currentState.mangaDetail.bonusChapters,
        );
        
        emit(DetailLoaded(
          mangaDetail: updatedMangaDetail,
          isOffline: currentState.isOffline,
          pendingActions: currentState.pendingActions,
        ));
      } else {
        emit(DetailError(
          message: 'Erreur lors de l\'ajout à la bibliothèque',
          isOffline: currentState.isOffline,
          cachedMangaDetail: currentState.mangaDetail,
        ));
      }
    } catch (e) {
      emit(DetailError(
        message: e.toString(),
        isOffline: currentState.isOffline,
        cachedMangaDetail: currentState.mangaDetail,
      ));
    }
  }

  /// Supprime le manga de la bibliothèque
  Future<void> _onRemoveFromLibrary(RemoveFromLibrary event, Emitter<DetailState> emit) async {
    if (state is! DetailLoaded) return;
    
    final currentState = state as DetailLoaded;
    emit(DetailActionInProgress(
      mangaDetail: currentState.mangaDetail,
      action: 'Suppression de la bibliothèque...',
      isOffline: currentState.isOffline,
    ));
    
    try {
      print('🗑️ DetailBloc: Retrait du manga ${event.muId} de la bibliothèque...');
      final success = await _libraryService.removeMangaFromLibrary(event.muId);
      
      if (success) {
        // Mettre à jour l'état local sans recharger
        print('✅ DetailBloc: Manga retiré, mise à jour locale de l\'état...');
        final updatedMangaDetail = MangaDetailDto(
          muId: currentState.mangaDetail.muId,
          title: currentState.mangaDetail.title,
          description: currentState.mangaDetail.description,
          status: currentState.mangaDetail.status,
          publicationStatus: currentState.mangaDetail.publicationStatus,
          year: currentState.mangaDetail.year,
          smallCoverUrl: currentState.mangaDetail.smallCoverUrl,
          mediumCoverUrl: currentState.mangaDetail.mediumCoverUrl,
          largeCoverUrl: currentState.mangaDetail.largeCoverUrl,
          rating: currentState.mangaDetail.rating,
          totalChapters: currentState.mangaDetail.totalChapters,
          isCompleted: currentState.mangaDetail.isCompleted,
          authors: currentState.mangaDetail.authors,
          genres: currentState.mangaDetail.genres,
          customLink: currentState.mangaDetail.customLink,
          inLibrary: false, // Le manga n'est plus dans la bibliothèque
          readChaptersCount: null, // Réinitialiser le nombre de chapitres lus
          readingStatus: null, // Réinitialiser le statut
          associated: currentState.mangaDetail.associated,
          recommendations: currentState.mangaDetail.recommendations,
          type: currentState.mangaDetail.type,
          seasonChapters: currentState.mangaDetail.seasonChapters,
          bonusChapters: currentState.mangaDetail.bonusChapters,
        );
        
        emit(DetailLoaded(
          mangaDetail: updatedMangaDetail,
          isOffline: currentState.isOffline,
          pendingActions: currentState.pendingActions,
        ));
      } else {
        emit(DetailError(
          message: 'Erreur lors de la suppression de la bibliothèque',
          isOffline: currentState.isOffline,
          cachedMangaDetail: currentState.mangaDetail,
        ));
      }
    } catch (e) {
      emit(DetailError(
        message: e.toString(),
        isOffline: currentState.isOffline,
        cachedMangaDetail: currentState.mangaDetail,
      ));
    }
  }

  /// Met à jour le statut de lecture
  Future<void> _onUpdateReadingStatus(UpdateReadingStatus event, Emitter<DetailState> emit) async {
    if (state is! DetailLoaded || _currentMuId == null) return;
    
    final currentState = state as DetailLoaded;
    emit(DetailActionInProgress(
      mangaDetail: currentState.mangaDetail,
      action: 'Mise à jour du statut...',
      isOffline: currentState.isOffline,
    ));
    
    try {
      print('🔄 DetailBloc: Mise à jour du statut du manga $_currentMuId vers ${event.status.name}...');
      final success = await _libraryService.updateMangaStatus(_currentMuId!, event.status);
      
      if (success) {
        // Mettre à jour l'état local sans recharger
        print('✅ DetailBloc: Statut mis à jour, mise à jour locale de l\'état...');
        final updatedMangaDetail = MangaDetailDto(
          muId: currentState.mangaDetail.muId,
          title: currentState.mangaDetail.title,
          description: currentState.mangaDetail.description,
          status: currentState.mangaDetail.status,
          publicationStatus: currentState.mangaDetail.publicationStatus,
          year: currentState.mangaDetail.year,
          smallCoverUrl: currentState.mangaDetail.smallCoverUrl,
          mediumCoverUrl: currentState.mangaDetail.mediumCoverUrl,
          largeCoverUrl: currentState.mangaDetail.largeCoverUrl,
          rating: currentState.mangaDetail.rating,
          totalChapters: currentState.mangaDetail.totalChapters,
          isCompleted: currentState.mangaDetail.isCompleted,
          authors: currentState.mangaDetail.authors,
          genres: currentState.mangaDetail.genres,
          customLink: currentState.mangaDetail.customLink,
          inLibrary: true, // Le manga est maintenant dans la bibliothèque
          readChaptersCount: currentState.mangaDetail.readChaptersCount,
          readingStatus: event.status, // Mise à jour du statut de lecture
          associated: currentState.mangaDetail.associated,
          recommendations: currentState.mangaDetail.recommendations,
          type: currentState.mangaDetail.type,
          seasonChapters: currentState.mangaDetail.seasonChapters,
          bonusChapters: currentState.mangaDetail.bonusChapters,
        );
        
        emit(DetailLoaded(
          mangaDetail: updatedMangaDetail,
          isOffline: currentState.isOffline,
          pendingActions: currentState.pendingActions,
        ));
      } else {
        emit(DetailError(
          message: 'Erreur lors de la mise à jour du statut',
          isOffline: currentState.isOffline,
          cachedMangaDetail: currentState.mangaDetail,
        ));
      }
    } catch (e) {
      emit(DetailError(
        message: e.toString(),
        isOffline: currentState.isOffline,
        cachedMangaDetail: currentState.mangaDetail,
      ));
    }
  }

  /// Sauvegarde la progression de lecture
  Future<void> _onSaveChapterProgress(SaveChapterProgress event, Emitter<DetailState> emit) async {
    print('🔄 DetailBloc: Sauvegarde du chapitre ${event.readChapters} pour manga ${event.muId}...');
    if (state is! DetailLoaded) return;
    
    final currentState = state as DetailLoaded;
    
    try {
      // Si on décoche tous les chapitres (0 chapitres lus), retirer de la bibliothèque
      if (event.readChapters == 0 && currentState.mangaDetail.inLibrary) {
        print('🗑️ Aucun chapitre lu, retrait automatique de la bibliothèque...');
        final removeSuccess = await _libraryService.removeMangaFromLibrary(event.muId);
        if (removeSuccess) {
          final updatedMangaDetail = MangaDetailDto(
            muId: currentState.mangaDetail.muId,
            title: currentState.mangaDetail.title,
            description: currentState.mangaDetail.description,
            status: currentState.mangaDetail.status,
            publicationStatus: currentState.mangaDetail.publicationStatus,
            year: currentState.mangaDetail.year,
            smallCoverUrl: currentState.mangaDetail.smallCoverUrl,
            mediumCoverUrl: currentState.mangaDetail.mediumCoverUrl,
            largeCoverUrl: currentState.mangaDetail.largeCoverUrl,
            rating: currentState.mangaDetail.rating,
            totalChapters: currentState.mangaDetail.totalChapters,
            isCompleted: currentState.mangaDetail.isCompleted,
            authors: currentState.mangaDetail.authors,
            genres: currentState.mangaDetail.genres,
            customLink: currentState.mangaDetail.customLink,
            inLibrary: false,
            readChaptersCount: 0,
            readingStatus: null,
            associated: currentState.mangaDetail.associated,
            recommendations: currentState.mangaDetail.recommendations,
            type: currentState.mangaDetail.type,
            seasonChapters: currentState.mangaDetail.seasonChapters,
            bonusChapters: currentState.mangaDetail.bonusChapters,
          );
          
          emit(currentState.copyWith(
            mangaDetail: updatedMangaDetail,
          ));
          print('✅ Manga retiré de la bibliothèque');
        }
        return;
      }
      
      // Si le manga n'est pas dans la bibliothèque, l'ajouter d'abord
      bool wasAddedToLibrary = false;
      if (!currentState.mangaDetail.inLibrary) {
        print('📚 Le manga n\'est pas dans la bibliothèque, ajout automatique...');
        final addSuccess = await _libraryService.addMangaToLibrary(event.muId);
        if (!addSuccess) {
          emit(DetailError(
            message: 'Erreur lors de l\'ajout à la bibliothèque',
            isOffline: currentState.isOffline,
            cachedMangaDetail: currentState.mangaDetail,
          ));
          return;
        }
        wasAddedToLibrary = true;
        print('✅ DetailBloc: Manga ajouté automatiquement à la bibliothèque');
      }
      
      print('🔍 Sauvegarde du chapitre dans le service...');
      final success = await _libraryService.saveChapterProgress(event.muId, event.readChapters);
      print('🔍 Résultat de la sauvegarde: $success');
      
      if (success) {
        print('🔍 Détermination du statut de lecture...');
        // Déterminer le statut de lecture automatiquement
        ReadingStatus newStatus = _determineReadingStatus(
          currentReadingStatus: currentState.mangaDetail.readingStatus,
          readChapters: event.readChapters,
          totalChapters: currentState.mangaDetail.totalChapters,
          isCompleted: currentState.mangaDetail.isCompleted,
        );
        print('🔍 Nouveau statut déterminé: ${newStatus.name}');
        
        // Si le statut a changé, mettre à jour également le statut (uniquement si dans la bibliothèque)
        final isNowInLibrary = currentState.mangaDetail.inLibrary || wasAddedToLibrary;
        print('🔍 isNowInLibrary: $isNowInLibrary, statut actuel: ${currentState.mangaDetail.readingStatus}, nouveau statut: ${newStatus.name}');
        if (newStatus != currentState.mangaDetail.readingStatus && isNowInLibrary) {
          print('🔄 Mise à jour automatique du statut vers: ${newStatus.name}');
          await _libraryService.updateMangaStatus(event.muId, newStatus);
        }
        
        // Mettre à jour l'état local sans recharger
        print('✅ DetailBloc: Chapitre sauvegardé, mise à jour locale...');
        final updatedMangaDetail = MangaDetailDto(
          muId: currentState.mangaDetail.muId,
          title: currentState.mangaDetail.title,
          description: currentState.mangaDetail.description,
          status: currentState.mangaDetail.status,
          publicationStatus: currentState.mangaDetail.publicationStatus,
          year: currentState.mangaDetail.year,
          smallCoverUrl: currentState.mangaDetail.smallCoverUrl,
          mediumCoverUrl: currentState.mangaDetail.mediumCoverUrl,
          largeCoverUrl: currentState.mangaDetail.largeCoverUrl,
          rating: currentState.mangaDetail.rating,
          totalChapters: currentState.mangaDetail.totalChapters,
          isCompleted: currentState.mangaDetail.isCompleted,
          authors: currentState.mangaDetail.authors,
          genres: currentState.mangaDetail.genres,
          customLink: currentState.mangaDetail.customLink,
          inLibrary: isNowInLibrary,
          readChaptersCount: event.readChapters,
          readingStatus: newStatus,
          associated: currentState.mangaDetail.associated,
          recommendations: currentState.mangaDetail.recommendations,
          type: currentState.mangaDetail.type,
          seasonChapters: currentState.mangaDetail.seasonChapters,
          bonusChapters: currentState.mangaDetail.bonusChapters,
        );
        
        emit(currentState.copyWith(
          mangaDetail: updatedMangaDetail,
        ));
      } else {
        emit(DetailError(
          message: 'Erreur lors de la sauvegarde de la progression',
          isOffline: currentState.isOffline,
          cachedMangaDetail: currentState.mangaDetail,
        ));
      }
    } catch (e) {
      emit(DetailError(
        message: e.toString(),
        isOffline: currentState.isOffline,
        cachedMangaDetail: currentState.mangaDetail,
      ));
    }
  }
  
  /// Détermine le statut de lecture automatiquement en fonction de la progression
  ReadingStatus _determineReadingStatus({
    ReadingStatus? currentReadingStatus,
    required int readChapters,
    required int totalChapters,
    bool? isCompleted,
  }) {
    print('🔍 _determineReadingStatus: readChapters=$readChapters, totalChapters=$totalChapters, isCompleted=$isCompleted');
    
    // Si tous les chapitres disponibles sont lus
    if (readChapters >= totalChapters && totalChapters > 0) {
      if (isCompleted == true) {
        print('✅ Tous chapitres lus + manga terminé → completed');
        return ReadingStatus.completed;
      } else {
        print('✅ Tous chapitres lus + manga en cours → caughtUp');
        return ReadingStatus.caughtUp;
      }
    }
    
    // Si on a commencé à lire (au moins 1 chapitre)
    if (readChapters > 0) {
      print('✅ Lecture en cours → reading');
      return ReadingStatus.reading;
    }
    
    // Sinon, garder le statut actuel ou mettre "À lire plus tard" par défaut
    print('✅ Aucun chapitre lu → readLater');
    return currentReadingStatus ?? ReadingStatus.readLater;
  }

  /// Met à jour le lien personnalisé
  Future<void> _onUpdateCustomLink(UpdateCustomLink event, Emitter<DetailState> emit) async {
    if (state is! DetailLoaded || _currentMuId == null) return;
    
    final currentState = state as DetailLoaded;
    emit(DetailActionInProgress(
      mangaDetail: currentState.mangaDetail,
      action: 'Mise à jour du lien...',
      isOffline: currentState.isOffline,
    ));
    
    try {
      final success = await _libraryService.updateCustomLink(_currentMuId!, event.customLink);
      
      if (success) {
        // Mettre à jour l'état local sans recharger
        final updatedMangaDetail = MangaDetailDto(
          muId: currentState.mangaDetail.muId,
          title: currentState.mangaDetail.title,
          description: currentState.mangaDetail.description,
          status: currentState.mangaDetail.status,
          publicationStatus: currentState.mangaDetail.publicationStatus,
          year: currentState.mangaDetail.year,
          smallCoverUrl: currentState.mangaDetail.smallCoverUrl,
          mediumCoverUrl: currentState.mangaDetail.mediumCoverUrl,
          largeCoverUrl: currentState.mangaDetail.largeCoverUrl,
          rating: currentState.mangaDetail.rating,
          totalChapters: currentState.mangaDetail.totalChapters,
          isCompleted: currentState.mangaDetail.isCompleted,
          authors: currentState.mangaDetail.authors,
          genres: currentState.mangaDetail.genres,
          customLink: event.customLink, // Mise à jour du lien personnalisé
          inLibrary: currentState.mangaDetail.inLibrary,
          readChaptersCount: currentState.mangaDetail.readChaptersCount,
          readingStatus: currentState.mangaDetail.readingStatus,
          associated: currentState.mangaDetail.associated,
          recommendations: currentState.mangaDetail.recommendations,
          type: currentState.mangaDetail.type,
          seasonChapters: currentState.mangaDetail.seasonChapters,
          bonusChapters: currentState.mangaDetail.bonusChapters,
        );
        
        emit(DetailLoaded(
          mangaDetail: updatedMangaDetail,
          isOffline: currentState.isOffline,
          pendingActions: currentState.pendingActions,
        ));
      } else {
        emit(DetailError(
          message: 'Erreur lors de la mise à jour du lien',
          isOffline: currentState.isOffline,
          cachedMangaDetail: currentState.mangaDetail,
        ));
      }
    } catch (e) {
      emit(DetailError(
        message: e.toString(),
        isOffline: currentState.isOffline,
        cachedMangaDetail: currentState.mangaDetail,
      ));
    }
  }

  /// Supprime le lien personnalisé
  Future<void> _onDeleteCustomLink(DeleteCustomLink event, Emitter<DetailState> emit) async {
    if (state is! DetailLoaded || _currentMuId == null) return;
    
    final currentState = state as DetailLoaded;
    emit(DetailActionInProgress(
      mangaDetail: currentState.mangaDetail,
      action: 'Suppression du lien...',
      isOffline: currentState.isOffline,
    ));
    
    try {
      final success = await _libraryService.deleteCustomLink(_currentMuId!);
      
      if (success) {
        // Mettre à jour l'état local sans recharger
        final updatedMangaDetail = MangaDetailDto(
          muId: currentState.mangaDetail.muId,
          title: currentState.mangaDetail.title,
          description: currentState.mangaDetail.description,
          status: currentState.mangaDetail.status,
          publicationStatus: currentState.mangaDetail.publicationStatus,
          year: currentState.mangaDetail.year,
          smallCoverUrl: currentState.mangaDetail.smallCoverUrl,
          mediumCoverUrl: currentState.mangaDetail.mediumCoverUrl,
          largeCoverUrl: currentState.mangaDetail.largeCoverUrl,
          rating: currentState.mangaDetail.rating,
          totalChapters: currentState.mangaDetail.totalChapters,
          isCompleted: currentState.mangaDetail.isCompleted,
          authors: currentState.mangaDetail.authors,
          genres: currentState.mangaDetail.genres,
          customLink: null, // Supprimer le lien personnalisé
          inLibrary: currentState.mangaDetail.inLibrary,
          readChaptersCount: currentState.mangaDetail.readChaptersCount,
          readingStatus: currentState.mangaDetail.readingStatus,
          associated: currentState.mangaDetail.associated,
          recommendations: currentState.mangaDetail.recommendations,
          type: currentState.mangaDetail.type,
          seasonChapters: currentState.mangaDetail.seasonChapters,
          bonusChapters: currentState.mangaDetail.bonusChapters,
        );
        
        emit(DetailLoaded(
          mangaDetail: updatedMangaDetail,
          isOffline: currentState.isOffline,
          pendingActions: currentState.pendingActions,
        ));
      } else {
        emit(DetailError(
          message: 'Erreur lors de la suppression du lien',
          isOffline: currentState.isOffline,
          cachedMangaDetail: currentState.mangaDetail,
        ));
      }
    } catch (e) {
      emit(DetailError(
        message: e.toString(),
        isOffline: currentState.isOffline,
        cachedMangaDetail: currentState.mangaDetail,
      ));
    }
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
}
