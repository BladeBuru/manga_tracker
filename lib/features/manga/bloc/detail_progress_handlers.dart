part of 'detail_bloc.dart';

/// Écritures de la fiche qui ne remplacent JAMAIS la page : progression
/// (tap sur un chapitre) et note personnelle. Un refus garde le contenu
/// chargé et émet [DetailActionFailed] (raison typée) ; la vue affiche le
/// message, annule son affichage anticipé et propose de réessayer.
extension _DetailProgressHandlers on DetailBloc {
  /// Abonnement aux progressions enregistrées AILLEURS (fenêtre « Ma
  /// progression » d'une lecture partagée) : la fiche encore ouverte en
  /// dessous se recharge au lieu d'afficher l'ancienne valeur au retour.
  void _listenToExternalProgress() {
    _progressSubscription = _progress.changes.listen((change) {
      if (isClosed ||
          identical(change.origin, this) ||
          change.muId != _currentMuId) {
        return;
      }
      add(const RefreshMangaDetail());
    });
  }

  /// [loaded] tel quel, sauf si une écriture de progression a eu lieu depuis
  /// le début du chargement : on garde alors la progression affichée (plus
  /// récente que la réponse du chargement).
  MangaDetailDto _keepNewerProgress(MangaDetailDto loaded, int writesAtStart) {
    final latest = state;
    if (writesAtStart == _progressWrites || latest is! DetailLoaded) {
      return loaded;
    }
    final mine = latest.mangaDetail;
    return _copyMangaDetail(
      loaded,
      inLibrary: mine.inLibrary,
      readChaptersCount: mine.readChaptersCount,
      clearReadChaptersCount: mine.readChaptersCount == null,
      readingStatus: mine.readingStatus,
      clearReadingStatus: mine.readingStatus == null,
      totalChapters: max(loaded.totalChapters, mine.totalChapters),
    );
  }

  DetailLoaded _latestLoaded(DetailLoaded fallback) {
    final latest = state;
    return latest is DetailLoaded ? latest : fallback;
  }

  /// Sauvegarde la progression de lecture (tap explicite sur un chapitre).
  Future<void> _onSaveChapterProgress(
    SaveChapterProgress event,
    Emitter<DetailState> emit,
  ) async {
    final start = state;
    if (start is! DetailLoaded) return;
    _progressWrites++;
    try {
      await _saveProgress(event, start, emit);
    } catch (e) {
      // Ajout / retrait / statut levés hors réseau : session refusée surtout.
      // INVARIANT : un handler de mutation émet toujours un état.
      final mode = classifyFailure(e);
      if (showsOfflineIndicator(mode)) {
        final latest = _latestLoaded(start);
        emit(latest.copyWith(
          isOffline: true,
          pendingActions: await _getPendingActionsCount(),
        ));
      } else {
        _emitProgressFailure(
          emit,
          event,
          requiresReauthPrompt(mode)
              ? const ChapterProgressSessionRejected()
              : ChapterProgressFailure(message: e.toString()),
        );
      }
    } finally {
      _progressWrites++;
    }
  }

  Future<void> _saveProgress(
    SaveChapterProgress event,
    DetailLoaded start,
    Emitter<DetailState> emit,
  ) async {
    final detail = start.mangaDetail;
    final isOffline = !_connectivityService.isConnected;

    // 0 chapitre lu : retrait de la bibliothèque (comportement existant).
    if (event.readChapters == 0 && detail.inLibrary) {
      final removed = await _libraryService.removeMangaFromLibrary(event.muId);
      if (!removed) {
        // Avant : retour silencieux, la fiche restait figée « en cours ».
        _emitProgressFailure(emit, event,
            const ChapterProgressFailure(message: 'removeManga refusé'));
        return;
      }
      final latest = _latestLoaded(start);
      emit(DetailLoaded(
        mangaDetail: _copyMangaDetail(
          latest.mangaDetail,
          inLibrary: false,
          clearReadChaptersCount: true,
          clearReadingStatus: true,
        ),
        isOffline: isOffline,
        pendingActions: await _getPendingActionsCount(),
        stale: latest.isStale,
      ));
      return;
    }

    // Titre absent de la bibliothèque : l'ajouter d'abord.
    var wasAdded = false;
    if (!detail.inLibrary) {
      final added = await _libraryService.addMangaToLibrary(event.muId);
      if (!added && !isOffline) {
        _emitProgressFailure(emit, event,
            const ChapterProgressFailure(message: 'addManga refusé'));
        return;
      }
      wasAdded = true;
    }

    // Tap explicite : il affirme l'avoir lu. Au-delà du total connu, on
    // signale au lieu de perdre la progression.
    final result = await _progress.save(
      event.muId,
      event.readChapters,
      autoReportIfAboveTotal: true,
      origin: this,
    );
    if (!result.isSuccess) {
      _emitProgressFailure(emit, event, result);
      return;
    }

    final reported = result is ChapterProgressAboveTotalReported;
    final total = reported
        ? max(detail.totalChapters, event.readChapters)
        : detail.totalChapters;
    final newStatus = await _determineReadingStatus(
      currentReadingStatus: detail.readingStatus,
      readChapters: event.readChapters,
      totalChapters: total,
      isCompleted: detail.isCompleted,
      customLink: detail.customLink,
      muId: event.muId,
    );
    final isNowInLibrary = detail.inLibrary || wasAdded;
    if (newStatus != detail.readingStatus && isNowInLibrary) {
      await _libraryService.updateMangaStatus(event.muId, newStatus);
    }

    // Relu APRÈS les attentes : un chargement concurrent a pu émettre.
    final latest = _latestLoaded(start);
    final queued = result is ChapterProgressOfflineQueued;
    emit(DetailLoaded(
      mangaDetail: _copyMangaDetail(
        latest.mangaDetail,
        inLibrary: isNowInLibrary,
        readChaptersCount: event.readChapters,
        readingStatus: newStatus,
        totalChapters: reported ? max(total, latest.mangaDetail.totalChapters) : null,
      ),
      isOffline: isOffline || queued,
      pendingActions: await _getPendingActionsCount(),
      stale: latest.isStale,
      // Enregistré par le serveur : la session est bonne.
      requiresReauth: queued && latest.requiresReauth,
    ));
  }

  /// Échec de progression : contenu conservé (valeur d'avant), raison typée.
  void _emitProgressFailure(
    Emitter<DetailState> emit,
    SaveChapterProgress event,
    ChapterProgressResult reason,
  ) {
    final latest = state;
    if (latest is! DetailLoaded) return;
    emit(DetailActionFailed(
      mangaDetail: latest.mangaDetail,
      isOffline: latest.isOffline,
      pendingActions: latest.pendingActions,
      stale: latest.isStale,
      requiresReauth:
          latest.requiresReauth || reason is ChapterProgressSessionRejected,
      notice: ProgressSaveFailed(
        readChapters: event.readChapters,
        reason: reason,
      ),
      attempt: ++_failureAttempt,
    ));
  }

  /// Met à jour la note personnelle de l'utilisateur (0-10).
  /// Mise à jour optimiste : on actualise l'état immédiatement ; si l'API
  /// échoue, retour à la note d'avant ET message (avant : retour en arrière
  /// muet, la note « sautait » sans explication).
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
      // 3. Rollback + message (0 = pas de note).
      debugPrint('⚠️ UpdateUserRating: échec API, rollback à $previousRating');
      final latest = _latestLoaded(currentState);
      emit(DetailActionFailed(
        mangaDetail: latest.mangaDetail.copyWith(userRating: previousRating),
        isOffline: latest.isOffline,
        pendingActions: latest.pendingActions,
        stale: latest.isStale,
        requiresReauth: latest.requiresReauth,
        notice: RatingSaveFailed(
          rating: event.rating,
          offline: !_connectivityService.isConnected,
        ),
        attempt: ++_failureAttempt,
      ));
      return;
    }

    // 4. Note globale et total des votes à jour : ils incluent désormais le
    // vote de l'utilisateur (lecture en base côté API, aucun appel
    // MangaUpdates). Échec silencieux : seule la note globale resterait
    // celle d'avant le vote jusqu'au prochain chargement.
    try {
      final summary = await _community.getRatingSummary(event.muId);
      final latest = state;
      if (summary == null || latest is! DetailLoaded) return;
      emit(latest.copyWith(
        mangaDetail: latest.mangaDetail.withRatingSummary(
          communityRating: summary.communityRating,
          communityRatingCount: summary.communityRatingCount,
          aggregatedRating: summary.aggregatedRating,
          muRatingVotes: summary.muRatingVotes,
          totalRatingVotes: summary.totalRatingVotes,
        ),
      ));
    } catch (e) {
      debugPrint('⚠️ UpdateUserRating: synthèse des notes indisponible ($e)');
    }
  }
}
