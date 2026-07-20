import 'dart:async';
import 'dart:math';
import 'package:bloc/bloc.dart';
import 'package:flutter/foundation.dart';
import 'package:mangatracker/core/service_locator/service_locator.dart';
import 'package:mangatracker/core/services/cache_helper_service.dart';
import 'package:mangatracker/core/services/connectivity_service.dart';
import 'package:mangatracker/features/library/services/chapter_report.service.dart';
import 'package:mangatracker/features/library/services/library.service.dart';
import 'package:mangatracker/features/manga/services/manga.service.dart';
import 'package:mangatracker/features/manga/dto/manga_detail.dto.dart';
import 'package:mangatracker/features/manga/dto/reading_status.enum.dart';
import 'package:mangatracker/features/manga/services/chapter_check_service.dart';
import 'package:mangatracker/features/manga/services/new_chapter_service.dart';
import 'package:mangatracker/features/manga/services/notification_service.dart';
import 'package:mangatracker/features/manga/services/notification_preferences_service.dart';
import 'detail_event.dart';
import 'detail_state.dart';

/// BLoC pour la gestion des détails de manga
class DetailBloc extends Bloc<DetailEvent, DetailState> {
  final MangaService _mangaService = getIt<MangaService>();
  final LibraryService _libraryService = getIt<LibraryService>();
  final ChapterReportService _chapterReportService =
      getIt<ChapterReportService>();
  final CacheHelperService _cacheHelper = getIt<CacheHelperService>();
  final ConnectivityService _connectivityService = getIt<ConnectivityService>();
  final ChapterCheckService _chapterCheckService = ChapterCheckService();
  final NewChapterService _newChapterService = NewChapterService();
  final NotificationService _notificationService = NotificationService();
  final NotificationPreferencesService _notificationPreferences = NotificationPreferencesService();
  
  StreamSubscription<bool>? _connectivitySubscription;
  int? _currentMuId;
  Timer? _chapterCheckTimer; // Timer pour la vérification différée des chapitres

  DetailBloc() : super(const DetailInitial()) {
    on<LoadMangaDetail>(_onLoadMangaDetail);
    on<RefreshMangaDetail>(_onRefreshMangaDetail);
    on<AddToLibrary>(_onAddToLibrary);
    on<RemoveFromLibrary>(_onRemoveFromLibrary);
    on<UpdateReadingStatus>(_onUpdateReadingStatus);
    on<SaveChapterProgress>(_onSaveChapterProgress);
    on<UpdateCustomLink>(_onUpdateCustomLink);
    on<DeleteCustomLink>(_onDeleteCustomLink);
    on<UpdateUserRating>(_onUpdateUserRating);
    on<ReportMoreChapters>(_onReportMoreChapters);

    _initializeConnectivityListener();
  }

  @override
  Future<void> close() {
    _connectivitySubscription?.cancel();
    _chapterCheckTimer?.cancel();
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

  /// Charge les détails d'un manga
  Future<void> _onLoadMangaDetail(LoadMangaDetail event, Emitter<DetailState> emit) async {
    debugPrint('🔄 DetailBloc: Chargement du manga ${event.muId}...');
    _currentMuId = event.muId;

    final cachedDetail = await _cacheHelper.getCachedMangaDetail(event.muId);
    MangaDetailDto? enrichedCachedDetail;

    if (cachedDetail != null) {
      enrichedCachedDetail = await _enrichWithLibraryInfo(event.muId, cachedDetail);
      final pendingCached = await _getPendingActionsCount();
      emit(DetailLoaded(
        mangaDetail: enrichedCachedDetail,
        isOffline: false,
        pendingActions: pendingCached,
        stale: true,
      ));
    } else {
      emit(const DetailLoading());
    }

    try {
      final mangaDetail = await _cacheHelper.loadMangaDetail(
        muId: event.muId,
        networkCall: () => _mangaService.getMangaDetail(event.muId.toString()),
      );
      
      final pendingActions = await _getPendingActionsCount();
      
      final updatedMangaDetail = await _enrichWithLibraryInfo(event.muId, mangaDetail);
      
      // Si aucune erreur, on est online - émettre l'état immédiatement
      emit(DetailLoaded(
        mangaDetail: updatedMangaDetail,
        isOffline: false,
        pendingActions: pendingActions,
        stale: false,
      ));
      
      // Vérifier les nouveaux chapitres en arrière-plan (non-bloquant)
      // pour éviter de ralentir le chargement de la page
      // Attendre 3 secondes pour laisser la page se charger complètement avant de vérifier
      if (updatedMangaDetail.customLink != null && updatedMangaDetail.customLink!.isNotEmpty) {
        // Annuler toute vérification précédente en cours
        _chapterCheckTimer?.cancel();
        
        // Exécuter en arrière-plan avec un délai pour ne pas bloquer le chargement initial
        _chapterCheckTimer = Timer(const Duration(seconds: 3), () {
          // Vérifier que le muId n'a pas changé (l'utilisateur n'a pas changé de manga)
          if (_currentMuId == event.muId) {
            _checkForNewChapters(event.muId, updatedMangaDetail).catchError((e) {
              debugPrint('⚠️ DetailBloc: Erreur lors de la vérification en arrière-plan: $e');
            });
          }
        });
      }
    } catch (e) {
      // Ne pas traiter InvalidCredentialsException comme une erreur réseau
      if (e.toString().contains('InvalidCredentialsException')) {
        debugPrint('⚠️ DetailBloc: Erreur d\'authentification');
        emit(DetailError(
          message: 'Authentification requise',
          isOffline: false,
        ));
        return;
      }
      
      // Erreur réseau détectée : on est offline
      debugPrint('⚠️ Erreur de chargement du manga, tentative de récupération depuis le cache...');
      
      try {
        final fallbackDetail = enrichedCachedDetail ?? await _cacheHelper.getCachedMangaDetail(event.muId);
        if (fallbackDetail != null) {
          debugPrint('✅ Données du manga chargées depuis le cache (mode offline)');
          emit(DetailLoaded(
            mangaDetail: fallbackDetail,
            isOffline: true,
            pendingActions: await _getPendingActionsCount(),
            stale: true,
          ));
        } else {
          emit(DetailError(
            message: e.toString(),
            isOffline: true,
          ));
        }
      } catch (cacheError) {
        emit(DetailError(
          message: e.toString(),
          isOffline: true,
        ));
      }
    }
  }

  Future<MangaDetailDto> _enrichWithLibraryInfo(int muId, MangaDetailDto mangaDetail) async {
    try {
      final entry = await _libraryService.getLibraryEntry(muId);

      if (entry != null && entry.readingStatus != null) {
        final readChaptersCount = entry.readChapters ?? -1;
        // Chantier A : le détail (`getMangaDetail`) renvoie le total OFFICIEL
        // MU (le cache stocke le détail brut, non enrichi → fiable), tandis que
        // /library/all renvoie le total EFFECTIF (max serveur entre le total MU
        // et le signalement user). On garde le plus grand comme total effectif
        // affiché, et on conserve le total officiel pour la validation du
        // dialog « Signaler plus de chapitres » (borne serveur = officiel+200).
        final officialTotal = mangaDetail.totalChapters;
        final effectiveTotal = max(
          officialTotal,
          entry.totalChapters?.toInt() ?? 0,
        );
        return _copyMangaDetail(
          mangaDetail,
          inLibrary: true,
          readChaptersCount:
              readChaptersCount >= 0 ? readChaptersCount.toInt() : null,
          readingStatus: entry.readingStatus,
          totalChapters: effectiveTotal,
          officialTotalChapters: officialTotal,
        );
      }
    } catch (e) {
      debugPrint('⚠️ DetailBloc: Erreur lors de la récupération du statut: $e');
    }
    return mangaDetail;
  }

  /// Signale que le manga possède plus de chapitres que le total connu
  /// (chantier A). Succès → ré-émission de l'état avec le total effectif
  /// renvoyé par l'API (PAS de reload) et `onResult(null)`. Échec → état
  /// inchangé, la cause typée est remontée au dialog via `event.onResult`
  /// (400 bornes, 404 hors biblio, 429 throttle, sinon `unknown`).
  Future<void> _onReportMoreChapters(
      ReportMoreChapters event, Emitter<DetailState> emit) async {
    if (state is! DetailLoaded) {
      event.onResult?.call(ChapterReportFailure.unknown);
      return;
    }

    try {
      final result = await _chapterReportService.reportMoreChapters(
        event.muId,
        event.reportedTotal,
      );
      // Finding 1 : relire `state` APRÈS l'await. Réutiliser le snapshot
      // capturé avant l'appel réseau écraserait une mise à jour émise
      // entre-temps par un handler concurrent (race).
      final latest = state;
      if (latest is DetailLoaded) {
        emit(latest.copyWith(
          mangaDetail: latest.mangaDetail.copyWith(
            totalChapters: result.effectiveTotalChapters,
          ),
        ));
      }
      event.onResult?.call(null);
    } on ChapterReportException catch (e) {
      // Finding 2 : propager la cause typée au dialog pour un message adapté
      // (400 permanent ≠ throttle temporaire).
      debugPrint('⚠️ DetailBloc: signalement de chapitres échoué: $e');
      event.onResult?.call(e.failure);
    } catch (e) {
      debugPrint('⚠️ DetailBloc: signalement de chapitres échoué: $e');
      event.onResult?.call(ChapterReportFailure.unknown);
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
    
    // Vérifier si on est offline
    final isOffline = !_connectivityService.isConnected;
    
    emit(DetailActionInProgress(
      mangaDetail: currentState.mangaDetail,
      action: isOffline ? 'Action mise en queue (hors ligne)...' : 'Ajout à la bibliothèque...',
      isOffline: isOffline,
    ));
    
    try {
      debugPrint('📚 DetailBloc: Ajout du manga ${event.muId} à la bibliothèque...');
      final success = await _libraryService.addMangaToLibrary(event.muId);
      
      if (success) {
        // Mettre à jour l'état local sans recharger
        debugPrint('✅ DetailBloc: Manga ajouté, mise à jour locale de l\'état...');
        final updatedMangaDetail = _copyMangaDetail(
          currentState.mangaDetail,
          inLibrary: true,
          readChaptersCount: 0,
          readingStatus: ReadingStatus.readLater,
        );
        
        final pendingActions = isOffline ? currentState.pendingActions + 1 : currentState.pendingActions;
        
        emit(DetailLoaded(
          mangaDetail: updatedMangaDetail,
          isOffline: isOffline,
          pendingActions: pendingActions,
          stale: currentState.isStale,
        ));
      } else {
        // En cas d'échec, si on est online c'est une vraie erreur, sinon c'est déjà géré
        if (!isOffline) {
          emit(DetailError(
            message: 'Erreur lors de l\'ajout à la bibliothèque',
            isOffline: false,
            cachedMangaDetail: currentState.mangaDetail,
          ));
        }
      }
    } catch (e) {
      // En cas d'exception, vérifier si c'est à cause du mode offline
      final isNowOffline = !_connectivityService.isConnected;
      if (!isNowOffline) {
        emit(DetailError(
          message: e.toString(),
          isOffline: false,
          cachedMangaDetail: currentState.mangaDetail,
        ));
      }
    }
  }

  /// Supprime le manga de la bibliothèque
  Future<void> _onRemoveFromLibrary(RemoveFromLibrary event, Emitter<DetailState> emit) async {
    if (state is! DetailLoaded) return;
    
    final currentState = state as DetailLoaded;
    
    // Vérifier si on est offline
    final isOffline = !_connectivityService.isConnected;
    
    emit(DetailActionInProgress(
      mangaDetail: currentState.mangaDetail,
      action: isOffline ? 'Action mise en queue (hors ligne)...' : 'Suppression de la bibliothèque...',
      isOffline: isOffline,
    ));
    
    try {
      debugPrint('🗑️ DetailBloc: Retrait du manga ${event.muId} de la bibliothèque...');
      final success = await _libraryService.removeMangaFromLibrary(event.muId);
      
      if (success) {
        // Mettre à jour l'état local sans recharger
        debugPrint('✅ DetailBloc: Manga retiré, mise à jour locale de l\'état...');
        final updatedMangaDetail = _copyMangaDetail(
          currentState.mangaDetail,
          inLibrary: false,
          clearReadChaptersCount: true,
          clearReadingStatus: true,
        );
        
        final pendingActions = isOffline ? currentState.pendingActions + 1 : currentState.pendingActions;
        
        emit(DetailLoaded(
          mangaDetail: updatedMangaDetail,
          isOffline: isOffline,
          pendingActions: pendingActions,
          stale: currentState.isStale,
        ));
      } else {
        // En cas d'échec, si on est online c'est une vraie erreur, sinon c'est déjà géré
        if (!isOffline) {
          emit(DetailError(
            message: 'Erreur lors de la suppression de la bibliothèque',
            isOffline: false,
            cachedMangaDetail: currentState.mangaDetail,
          ));
        }
      }
    } catch (e) {
      // En cas d'exception, vérifier si c'est à cause du mode offline
      final isNowOffline = !_connectivityService.isConnected;
      if (!isNowOffline) {
        emit(DetailError(
          message: e.toString(),
          isOffline: false,
          cachedMangaDetail: currentState.mangaDetail,
        ));
      }
    }
  }

  /// Met à jour le statut de lecture
  Future<void> _onUpdateReadingStatus(UpdateReadingStatus event, Emitter<DetailState> emit) async {
    if (state is! DetailLoaded || _currentMuId == null) return;
    
    final currentState = state as DetailLoaded;
    
    // Vérifier si on est offline
    final isOffline = !_connectivityService.isConnected;
    
    emit(DetailActionInProgress(
      mangaDetail: currentState.mangaDetail,
      action: isOffline ? 'Action mise en queue (hors ligne)...' : 'Mise à jour du statut...',
      isOffline: isOffline,
    ));
    
    try {
      debugPrint('🔄 DetailBloc: Mise à jour du statut du manga $_currentMuId vers ${event.status.name}...');
      final success = await _libraryService.updateMangaStatus(_currentMuId!, event.status);
      
      if (success) {
        // Mettre à jour l'état local sans recharger
        debugPrint('✅ DetailBloc: Statut mis à jour, mise à jour locale de l\'état...');
        final updatedMangaDetail = _copyMangaDetail(
          currentState.mangaDetail,
          inLibrary: true,
          readingStatus: event.status,
        );
        
        final pendingActions = isOffline ? currentState.pendingActions + 1 : currentState.pendingActions;
        
        emit(DetailLoaded(
          mangaDetail: updatedMangaDetail,
          isOffline: isOffline,
          pendingActions: pendingActions,
          stale: currentState.isStale,
        ));
      } else {
        // En cas d'échec, si on est online c'est une vraie erreur, sinon c'est déjà géré
        if (!isOffline) {
          emit(DetailError(
            message: 'Erreur lors de la mise à jour du statut',
            isOffline: false,
            cachedMangaDetail: currentState.mangaDetail,
          ));
        }
      }
    } catch (e) {
      // En cas d'exception, vérifier si c'est à cause du mode offline
      final isNowOffline = !_connectivityService.isConnected;
      if (!isNowOffline) {
        emit(DetailError(
          message: e.toString(),
          isOffline: false,
          cachedMangaDetail: currentState.mangaDetail,
        ));
      }
    }
  }

  /// Sauvegarde la progression de lecture
  Future<void> _onSaveChapterProgress(SaveChapterProgress event, Emitter<DetailState> emit) async {
    debugPrint('🔄 DetailBloc: Sauvegarde du chapitre ${event.readChapters} pour manga ${event.muId}...');
    if (state is! DetailLoaded) return;
    
    final currentState = state as DetailLoaded;
    
    // Vérifier le statut de connectivité
    final isOffline = !_connectivityService.isConnected;
    
    try {
      // Si on décoche tous les chapitres (0 chapitres lus), retirer de la bibliothèque
      if (event.readChapters == 0 && currentState.mangaDetail.inLibrary) {
        debugPrint('🗑️ Aucun chapitre lu, retrait automatique de la bibliothèque...');
        final removeSuccess = await _libraryService.removeMangaFromLibrary(event.muId);
        if (removeSuccess) {
          final updatedMangaDetail = _copyMangaDetail(
            currentState.mangaDetail,
            inLibrary: false,
            clearReadChaptersCount: true,
            clearReadingStatus: true,
          );
          
          final pendingActions = isOffline ? currentState.pendingActions + 1 : currentState.pendingActions;
          
          emit(DetailLoaded(
            mangaDetail: updatedMangaDetail,
            isOffline: isOffline,
            pendingActions: pendingActions,
            stale: currentState.isStale,
          ));
          debugPrint('✅ Manga retiré de la bibliothèque');
        }
        return;
      }
      
      // Si le manga n'est pas dans la bibliothèque, l'ajouter d'abord
      bool wasAddedToLibrary = false;
      if (!currentState.mangaDetail.inLibrary) {
        debugPrint('📚 Le manga n\'est pas dans la bibliothèque, ajout automatique...');
        final addSuccess = await _libraryService.addMangaToLibrary(event.muId);
        // Si offline et addSuccess, ça veut dire que c'est en queue
        if (!addSuccess && !isOffline) {
          emit(DetailError(
            message: 'Erreur lors de l\'ajout à la bibliothèque',
            isOffline: false,
            cachedMangaDetail: currentState.mangaDetail,
          ));
          return;
        }
        wasAddedToLibrary = true;
        debugPrint('✅ DetailBloc: Manga ajouté automatiquement à la bibliothèque');
      }
      
      debugPrint('🔍 Sauvegarde du chapitre dans le service...');
      final success = await _libraryService.saveChapterProgress(event.muId, event.readChapters);
      debugPrint('🔍 Résultat de la sauvegarde: $success');
      
      if (success) {
        debugPrint('🔍 Détermination du statut de lecture...');
        // Déterminer le statut de lecture automatiquement
        ReadingStatus newStatus = await _determineReadingStatus(
          currentReadingStatus: currentState.mangaDetail.readingStatus,
          readChapters: event.readChapters,
          totalChapters: currentState.mangaDetail.totalChapters,
          isCompleted: currentState.mangaDetail.isCompleted,
          customLink: currentState.mangaDetail.customLink,
          muId: event.muId,
        );
        debugPrint('🔍 Nouveau statut déterminé: ${newStatus.name}');
        
        // Si le statut a changé, mettre à jour également le statut (uniquement si dans la bibliothèque)
        final isNowInLibrary = currentState.mangaDetail.inLibrary || wasAddedToLibrary;
          debugPrint('🔍 isNowInLibrary: $isNowInLibrary, statut actuel: ${currentState.mangaDetail.readingStatus}, nouveau statut: ${newStatus.name}');
        if (newStatus != currentState.mangaDetail.readingStatus && isNowInLibrary) {
          debugPrint('🔄 Mise à jour automatique du statut vers: ${newStatus.name}');
          await _libraryService.updateMangaStatus(event.muId, newStatus);
        }
        
        // Compter le nombre d'actions offline
        int offlineActionCount = 0;
        if (isOffline) {
          if (wasAddedToLibrary) offlineActionCount++; // Ajout à la bibliothèque
          offlineActionCount++; // Sauvegarde du chapitre
          if (newStatus != currentState.mangaDetail.readingStatus && isNowInLibrary) {
            offlineActionCount++; // Mise à jour du statut
          }
        }
        
        // Mettre à jour l'état local sans recharger
        debugPrint('✅ DetailBloc: Chapitre sauvegardé, mise à jour locale...');
        final updatedMangaDetail = _copyMangaDetail(
          currentState.mangaDetail,
          inLibrary: isNowInLibrary,
          readChaptersCount: event.readChapters,
          readingStatus: newStatus,
        );
        
        emit(DetailLoaded(
          mangaDetail: updatedMangaDetail,
          isOffline: isOffline,
          pendingActions: currentState.pendingActions + offlineActionCount,
          stale: currentState.isStale,
        ));
      } else {
        // Échec uniquement si on est online
        if (!isOffline) {
          emit(DetailError(
            message: 'Erreur lors de la sauvegarde de la progression',
            isOffline: false,
            cachedMangaDetail: currentState.mangaDetail,
          ));
        }
      }
    } catch (e) {
      // Exception uniquement si on est online
      final isNowOffline = !_connectivityService.isConnected;
      if (!isNowOffline) {
        emit(DetailError(
          message: e.toString(),
          isOffline: false,
          cachedMangaDetail: currentState.mangaDetail,
        ));
      }
    }
  }
  
  /// Détermine le statut de lecture automatiquement en fonction de la progression
  /// Vérifie également s'il y a de nouveaux chapitres disponibles avant de passer à "À jour"
  Future<ReadingStatus> _determineReadingStatus({
    ReadingStatus? currentReadingStatus,
    required int readChapters,
    required int totalChapters,
    bool? isCompleted,
    String? customLink,
    int? muId,
  }) async {
    debugPrint('🔍 _determineReadingStatus: readChapters=$readChapters, totalChapters=$totalChapters, isCompleted=$isCompleted');
    
    // Si tous les chapitres disponibles sont lus
    if (readChapters >= totalChapters && totalChapters > 0) {
      // Vérifier s'il y a de nouveaux chapitres disponibles en ligne
      // avant de passer à "À jour"
      if (customLink != null && customLink.isNotEmpty && muId != null) {
        try {
          // Vérifier si le chapitre suivant existe
          final nextChapterExists = await _chapterCheckService.checkNextChapter(
            muId,
            customLink,
            readChapters,
          );
          
          if (nextChapterExists) {
            debugPrint('✅ Chapitre suivant disponible → reading (pas encore à jour)');
            // Enregistrer le nouveau chapitre
            await _newChapterService.addNewChapter(muId, readChapters + 1);
            return ReadingStatus.reading;
          } else {
            debugPrint('✅ Aucun nouveau chapitre disponible → caughtUp');
            // S'assurer qu'il n'y a pas de nouveaux chapitres enregistrés
            await _newChapterService.clearNewChapters(muId);
          }
        } catch (e) {
          debugPrint('⚠️ Erreur lors de la vérification du chapitre suivant: $e');
          // En cas d'erreur, on suppose qu'il n'y a pas de nouveau chapitre
        }
      }
      
      if (isCompleted == true) {
        debugPrint('✅ Tous chapitres lus + manga terminé → completed');
        return ReadingStatus.completed;
      } else {
        debugPrint('✅ Tous chapitres lus + manga en cours → caughtUp');
        return ReadingStatus.caughtUp;
      }
    }
    
    // Si on a commencé à lire (au moins 1 chapitre)
    if (readChapters > 0) {
      debugPrint('✅ Lecture en cours → reading');
      return ReadingStatus.reading;
    }
    
    // Sinon, garder le statut actuel ou mettre "À lire plus tard" par défaut
    debugPrint('✅ Aucun chapitre lu → readLater');
    return currentReadingStatus ?? ReadingStatus.readLater;
  }

  /// Vérifie s'il y a de nouveaux chapitres disponibles pour un manga
  Future<void> _checkForNewChapters(int muId, MangaDetailDto mangaDetail) async {
    if (mangaDetail.customLink == null || mangaDetail.customLink!.isEmpty) {
      return;
    }

    final readChapters = mangaDetail.readChaptersCount ?? 0;
    if (readChapters <= 0) {
      return; // Pas de chapitres lus, pas besoin de vérifier
    }

    try {
      debugPrint('🔍 DetailBloc: Vérification des nouveaux chapitres pour $muId (lu: $readChapters)');
      
      // Vérifier le chapitre suivant
      final nextChapterExists = await _chapterCheckService.checkNextChapter(
        muId,
        mangaDetail.customLink!,
        readChapters,
      );

      if (nextChapterExists) {
        final nextChapter = readChapters + 1;
        await _newChapterService.addNewChapter(muId, nextChapter);
        debugPrint('✅ DetailBloc: Nouveau chapitre détecté: $nextChapter');
        
        // Envoyer une notification seulement si les notifications sont activées
        final notificationsEnabled = await _notificationPreferences.areNewChapterNotificationsEnabled();
        if (notificationsEnabled) {
          await _notificationService.showNewChapterNotification(
            muId: muId,
            mangaTitle: mangaDetail.title,
            chapterNumber: nextChapter,
          );
        }
      } else {
        // Pas de nouveau chapitre, nettoyer la liste si nécessaire
        final hasNewChapters = await _newChapterService.hasNewChapters(muId);
        if (hasNewChapters) {
          // Vérifier si les chapitres enregistrés existent toujours
          final newChapters = await _newChapterService.getNewChapters(muId);
          for (final chapter in newChapters) {
            final exists = await _chapterCheckService.checkChapterExists(
              mangaDetail.customLink!,
              chapter,
            );
            if (!exists) {
              await _newChapterService.markChapterAsRead(muId, chapter);
            }
          }
        }
      }

      // Enregistrer le dernier chapitre vérifié
      await _newChapterService.setLastCheckedChapter(muId, readChapters);
      await _newChapterService.setLastCheckDate(DateTime.now());
    } catch (e) {
      debugPrint('⚠️ DetailBloc: Erreur lors de la vérification des nouveaux chapitres: $e');
    }
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
        final updatedMangaDetail = _copyMangaDetail(
          currentState.mangaDetail,
          customLink: event.customLink,
        );
        
        emit(DetailLoaded(
          mangaDetail: updatedMangaDetail,
          isOffline: currentState.isOffline,
          pendingActions: currentState.pendingActions,
          stale: currentState.isStale,
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
        final updatedMangaDetail = _copyMangaDetail(
          currentState.mangaDetail,
          clearCustomLink: true,
        );
        
        emit(DetailLoaded(
          mangaDetail: updatedMangaDetail,
          isOffline: currentState.isOffline,
          pendingActions: currentState.pendingActions,
          stale: currentState.isStale,
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

  /// Met à jour la note personnelle de l'utilisateur (0-10).
  /// Mise à jour optimiste : on actualise l'état immédiatement, on roll-back
  /// si l'API échoue.
  Future<void> _onUpdateUserRating(
    UpdateUserRating event,
    Emitter<DetailState> emit,
  ) async {
    final currentState = state;
    if (currentState is! DetailLoaded) return;

    if (event.rating < 0 || event.rating > 10) {
      debugPrint('⚠️ UpdateUserRating: rating hors plage (${event.rating})');
      return;
    }

    final previousRating = currentState.mangaDetail.userRating;
    // 1. Update optimiste UI
    emit(currentState.copyWith(
      mangaDetail: currentState.mangaDetail.copyWith(userRating: event.rating),
    ));

    // 2. Appel API
    final success = await _libraryService.updateRating(event.muId, event.rating);

    if (!success) {
      // 3. Rollback si échec
      debugPrint('⚠️ UpdateUserRating: échec API, rollback à $previousRating');
      emit(currentState.copyWith(
        mangaDetail:
            currentState.mangaDetail.copyWith(userRating: previousRating),
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

  /// Helper pour créer une copie de MangaDetailDto avec des champs modifiés
  MangaDetailDto _copyMangaDetail(
    MangaDetailDto original, {
    bool? inLibrary,
    int? readChaptersCount,
    ReadingStatus? readingStatus,
    String? customLink,
    int? totalChapters,
    int? officialTotalChapters,
    bool clearCustomLink = false,
    bool clearReadingStatus = false,
    bool clearReadChaptersCount = false,
  }) {
    return MangaDetailDto(
      muId: original.muId,
      title: original.title,
      description: original.description,
      translatedDescription: original.translatedDescription,
      status: original.status,
      publicationStatus: original.publicationStatus,
      year: original.year,
      smallCoverUrl: original.smallCoverUrl,
      mediumCoverUrl: original.mediumCoverUrl,
      largeCoverUrl: original.largeCoverUrl,
      rating: original.rating,
      totalChapters: totalChapters ?? original.totalChapters,
      officialTotalChapters:
          officialTotalChapters ?? original.officialTotalChapters,
      isCompleted: original.isCompleted,
      authors: original.authors,
      genres: original.genres,
      customLink: clearCustomLink ? null : (customLink ?? original.customLink),
      inLibrary: inLibrary ?? original.inLibrary,
      readChaptersCount: clearReadChaptersCount ? null : (readChaptersCount ?? original.readChaptersCount),
      readingStatus: clearReadingStatus ? null : (readingStatus ?? original.readingStatus),
      associated: original.associated,
      recommendations: original.recommendations,
      type: original.type,
      seasonChapters: original.seasonChapters,
      bonusChapters: original.bonusChapters,
      userRating: original.userRating,
      communityRating: original.communityRating,
      communityRatingCount: original.communityRatingCount,
      aggregatedRating: original.aggregatedRating,
    );
  }
}
