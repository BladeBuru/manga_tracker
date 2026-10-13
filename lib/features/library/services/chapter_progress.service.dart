import 'dart:async';
import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:http/http.dart';
import 'package:mangatracker/core/network/failure_classifier.dart';
import 'package:mangatracker/core/network/http_service.dart';
import 'package:mangatracker/core/network/network_compat.dart';
import 'package:mangatracker/core/network/uri_builder.dart';
import 'package:mangatracker/core/service_locator/service_locator.dart';
import 'package:mangatracker/core/services/connectivity_service.dart';
import 'package:mangatracker/core/services/offline_cache_service.dart';
import 'package:mangatracker/features/library/services/chapter_progress_result.dart';
import 'package:mangatracker/features/library/services/chapter_report.service.dart';
import 'package:mangatracker/features/library/services/library.service.dart';
import 'package:mangatracker/features/library/services/offline_write_queue.dart';

/// Enregistrement de la progression avec une issue **typée**
/// ([ChapterProgressResult]) — pour les écrans qui doivent expliquer un refus
/// (fenêtre « Ma progression » d'une lecture partagée, fiche du manga).
///
/// Même requête et même rattrapage que `LibraryService.saveChapterProgress`
/// (PUT, puis sur 406 signalement + un seul nouvel essai), dont le booléen
/// reste inchangé pour le lecteur. Diffuse [changes] quand le serveur porte
/// une nouvelle valeur, pour que les écrans déjà ouverts se remettent à jour.
///
/// Dépendances résolues **à l'appel** (lazy singleton sans `dependsOn`) :
/// injectables en test.
class ChapterProgressService {
  final HttpService? _httpOverride;
  final ConnectivityService? _connectivityOverride;
  final OfflineCacheService? _cacheOverride;
  final ChapterReportService? _reportsOverride;
  final LibraryService? _libraryOverride;
  final OfflineWriteQueue _queue;

  final StreamController<ChapterProgressChange> _changes =
      StreamController<ChapterProgressChange>.broadcast();

  ChapterProgressService({
    HttpService? http,
    ConnectivityService? connectivity,
    OfflineCacheService? cache,
    ChapterReportService? reports,
    LibraryService? library,
    OfflineWriteQueue? queue,
  }) : _httpOverride = http,
       _connectivityOverride = connectivity,
       _cacheOverride = cache,
       _reportsOverride = reports,
       _libraryOverride = library,
       _queue = queue ?? OfflineWriteQueue(cache: cache);

  HttpService get _http => _httpOverride ?? getIt<HttpService>();
  ConnectivityService get _connectivity =>
      _connectivityOverride ?? getIt<ConnectivityService>();
  OfflineCacheService get _cache =>
      _cacheOverride ?? getIt<OfflineCacheService>();
  ChapterReportService get _reports =>
      _reportsOverride ?? getIt<ChapterReportService>();
  LibraryService get _library => _libraryOverride ?? getIt<LibraryService>();

  /// Progressions appliquées sur le serveur (jamais une mise en file).
  Stream<ChapterProgressChange> get changes => _changes.stream;

  /// Enregistre [readChapters] (« dernier chapitre TERMINÉ ») pour [muId].
  ///
  /// [autoReportIfAboveTotal] : sur un 406 (total connu dépassé), signale le
  /// nouveau total puis réessaie une fois — À n'activer que sur une
  /// affirmation explicite de l'utilisateur, jamais sur une détection
  /// automatique (cf. `LibraryService.saveChapterProgress`).
  /// [addToLibraryIfMissing] : sur un 404, ajoute le titre à la bibliothèque
  /// puis réessaie une fois. [origin] accompagne la diffusion dans [changes].
  Future<ChapterProgressResult> save(
    int muId,
    int readChapters, {
    bool autoReportIfAboveTotal = false,
    bool addToLibraryIfMissing = false,
    Object? origin,
  }) async {
    if (readChapters < 0) {
      return ChapterProgressFailure(message: 'readChapters < 0 ($readChapters)');
    }
    final action = OfflineAction.saveChapterProgress(
      muId,
      readChapters,
      confirmedByUser: autoReportIfAboveTotal,
    );
    final result = await _save(
      muId,
      readChapters,
      action: action,
      autoReport: autoReportIfAboveTotal,
      addToLibrary: addToLibraryIfMissing,
    );
    if (result.isAppliedOnServer) {
      await _invalidateRecommendations();
      if (!_changes.isClosed) {
        _changes.add(ChapterProgressChange(
          muId: muId,
          readChapters: readChapters,
          origin: origin,
        ));
      }
    }
    return result;
  }

  Future<ChapterProgressResult> _save(
    int muId,
    int readChapters, {
    required OfflineAction action,
    required bool autoReport,
    required bool addToLibrary,
  }) async {
    if (!_connectivity.isConnected) return _enqueue(action);
    try {
      var res = await _put(muId, readChapters);
      if (res.statusCode == HttpStatus.notFound && addToLibrary) {
        // L'ajout traite « déjà dans la bibliothèque » comme un succès, et se
        // met lui-même en file si le réseau tombe (la progression suivra).
        if (await _library.addMangaToLibrary(muId)) {
          res = await _put(muId, readChapters);
        }
      }
      if (res.statusCode == HttpStatus.notAcceptable && autoReport) {
        return await _reportThenRetry(muId, readChapters, action);
      }
      return ChapterProgressResult.fromStatusCode(res.statusCode);
    } catch (e) {
      return _fromError(e, action);
    }
  }

  /// Signale le nouveau total puis rejoue le PUT **une seule fois** (aucune
  /// boucle possible : le rejeu ne déclenche pas d'autre signalement).
  Future<ChapterProgressResult> _reportThenRetry(
    int muId,
    int readChapters,
    OfflineAction action,
  ) async {
    try {
      await _reports.reportMoreChapters(muId, readChapters);
    } on ChapterReportException catch (e) {
      debugPrint('⚠️ ChapterProgressService: signalement refusé ($e)');
      return ChapterProgressResult.fromReportFailure(e);
    } catch (e) {
      return _fromError(e, action);
    }
    try {
      final res = await _put(muId, readChapters);
      final result = ChapterProgressResult.fromStatusCode(res.statusCode);
      return result is ChapterProgressSaved
          ? const ChapterProgressAboveTotalReported()
          : result;
    } catch (e) {
      return _fromError(e, action);
    }
  }

  /// Exception → issue : session refusée (rien en file), réseau (en file),
  /// sinon échec. Même frontière que `OfflineWriteQueue.queueUnlessRejected`.
  Future<ChapterProgressResult> _fromError(
    Object error,
    OfflineAction action,
  ) async {
    final mode = classifyFailure(error);
    if (requiresReauthPrompt(mode)) return const ChapterProgressSessionRejected();
    if (OfflineWriteQueue.isQueueable(mode)) return _enqueue(action);
    debugPrint('⚠️ ChapterProgressService: échec inattendu ($error)');
    return ChapterProgressFailure(message: error.toString());
  }

  Future<ChapterProgressResult> _enqueue(OfflineAction action) async {
    try {
      await _queue.enqueue(action);
      return const ChapterProgressOfflineQueued();
    } catch (e) {
      return ChapterProgressFailure(message: 'file hors ligne : $e');
    }
  }

  Future<Response> _put(int muId, int readChapters) {
    return _http.putWithAuthTokens(
      buildApiUri('/library/chapter'),
      headers: {HttpHeaders.contentTypeHeader: 'application/json'},
      body: jsonEncode({'muId': muId, 'readChapters': readChapters}),
    );
  }

  /// La progression pèse dans le classement des recommandations. Jamais
  /// bloquant : un cache non vidé ne doit pas faire échouer l'enregistrement.
  Future<void> _invalidateRecommendations() async {
    try {
      await _cache.invalidateRecommendationsCache();
    } catch (e) {
      debugPrint('⚠️ ChapterProgressService: cache des recos non vidé ($e)');
    }
  }

  void dispose() => _changes.close();
}
