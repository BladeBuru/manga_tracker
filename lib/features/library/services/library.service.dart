import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:http/http.dart';
import 'package:mangatracker/features/auth/exceptions/invalid_credentials.exception.dart';
import 'package:mangatracker/core/network/http_service.dart';
import 'package:mangatracker/core/network/network_compat.dart';
import 'package:mangatracker/core/network/uri_builder.dart';
import 'package:mangatracker/core/service_locator/service_locator.dart';
import 'package:mangatracker/core/services/connectivity_service.dart';
import 'package:mangatracker/core/services/library_index_service.dart';
import 'package:mangatracker/core/services/offline_cache_service.dart';
import 'package:mangatracker/features/manga/dto/manga_quick_view.dto.dart';
import 'package:mangatracker/features/library/services/chapter_report.service.dart';
import 'package:mangatracker/features/library/services/offline_write_queue.dart';

import '../../manga/dto/reading_status.enum.dart';

class LibraryService {
  final HttpService _http = getIt<HttpService>();

  /// File d'attente hors ligne partagée avec `ChapterProgressService`.
  final OfflineWriteQueue _writeQueue = OfflineWriteQueue();

  /// Résolu **paresseusement** : `ChapterReportService` est enregistré APRÈS
  /// `LibraryService` dans `setupServiceLocator`. Le résoudre dans le
  /// constructeur ou dans `init()` planterait le démarrage (écran blanc).
  ChapterReportService get _chapterReportService => getIt<ChapterReportService>();
  late final ConnectivityService _connectivityService;
  late final OfflineCacheService _cacheService;
  
  /// Met à jour l'index « déjà dans ma bibliothèque » sans attendre la
  /// réécriture de `cached_library` (au prochain `/library/all` seulement).
  /// Résolu **à l'appel**, et silencieux s'il est absent : une mutation ne
  /// doit jamais échouer à cause de l'index.
  void _markInIndex(int muId, {required bool owned}) {
    try {
      getIt<LibraryIndexService>().setOwned(muId, owned: owned);
    } catch (e) {
      debugPrint('LibraryService: index appartenance indisponible ($e)');
    }
  }

  Future<LibraryService> init() async {
    _connectivityService = getIt<ConnectivityService>();
    _cacheService = getIt<OfflineCacheService>();
    return this;
  }


  // ─────────── GET /library/all ───────────
  Future<List<MangaQuickViewDto>> getUserSavedMangas() async {
    // Ne plus utiliser le cache en mémoire pour permettre la détection offline
    // Le CacheHelperService gère maintenant le cache offline
    // if (_userLibraryCache != null) {
    //   return _userLibraryCache!;
    // }
    final url = buildApiUri('/library/all');
    final library = await _fetchMangaList(url);
    // _userLibraryCache = library; // Désactivé pour permettre la détection offline
    return library;
  }

  // ─────────── POST /library/save ───────────

  Future<bool> addMangaToLibrary(int muId) async {
    final isOnline = _connectivityService.isConnected;
    
    if (isOnline) {
      try {
        final url = buildApiUri('/library/save');
        final success = await _postOrDelete(
          method: _http.postWithAuthTokens,
          url: url,
          muId: muId,
          expectStatus: HttpStatus.created,
          // Déjà dans la bibliothèque (autre appareil, double appui) : c'est
          // l'état voulu. Avant, ce refus faisait échouer l'action.
          alsoSuccess: (res) =>
              isAlreadyInLibraryResponse(res.statusCode, res.body),
        );
        // La biblio a changé → les recos doivent refléter le changement
        // (le back invalide son cache, le front doit faire pareil).
        if (success) await _cacheService.invalidateRecommendationsCache();
        if (success) _markInIndex(muId, owned: true);
        return success;
      } catch (e) {
        // Rejet de session => refus, pas de mise en file.
        return await _queueUnlessRejected(OfflineAction.addManga(muId), e);
      }
    } else {
      // Mode hors ligne : ajouter à la queue
      await _cacheService.queueOfflineAction(OfflineAction.addManga(muId));
      _markInIndex(muId, owned: true);
      return true; // Retourner true car l'action est en queue
    }
  }


  // ─────────── PUT /library/chapter ───────────

  /// Met à jour le pointeur de progression `userReadChapters`.
  ///
  /// L'API répond **406** quand `readChapters` dépasse le total effectif
  /// connu du manga (cap serveur dans `updateChapter`). Sans traitement,
  /// la progression pourtant confirmée par l'utilisateur est perdue en
  /// silence — c'est le scénario « la source dit 79, j'ai lu 90 ».
  ///
  /// [autoReportIfAboveTotal] active le rattrapage : le 406 déclenche un
  /// signalement communautaire (`report-chapters`) puis **un seul** rejeu
  /// du PUT. À n'activer QUE sur les chemins où l'utilisateur a
  /// explicitement affirmé sa lecture (dialogue de confirmation, tap sur
  /// un chapitre) — jamais sur une détection automatique d'URL, qui
  /// polluerait la base communautaire sur un simple faux positif.
  Future<bool> saveChapterProgress(
    int muId,
    int readChapters, {
    bool autoReportIfAboveTotal = false,
  }) async {
    final isOnline = _connectivityService.isConnected;

    if (isOnline) {
      try {
        final res = await _putChapterProgress(muId, readChapters);
        if (res.statusCode == HttpStatus.ok) {
          await _cacheService.invalidateRecommendationsCache();
          return true;
        }
        if (res.statusCode == HttpStatus.notAcceptable &&
            autoReportIfAboveTotal) {
          return await _reportThenRetryProgress(muId, readChapters);
        }
        return false;
      } catch (e) {
        // Rejet de session => refus, pas de mise en file.
        return await _queueUnlessRejected(
            OfflineAction.saveChapterProgress(muId, readChapters,
                confirmedByUser: autoReportIfAboveTotal),
            e);
      }
    } else {
      // Mode hors ligne : ajouter à la queue. La confirmation suit l'action :
      // au rejeu, un 406 sera rattrapé comme en ligne.
      await _cacheService.queueOfflineAction(OfflineAction.saveChapterProgress(
          muId, readChapters,
          confirmedByUser: autoReportIfAboveTotal));
      return true; // Retourner true car l'action est en queue
    }
  }

  Future<Response> _putChapterProgress(int muId, int readChapters) {
    return _http.putWithAuthTokens(
      buildApiUri('/library/chapter'),
      headers: {HttpHeaders.contentTypeHeader: 'application/json'},
      body: jsonEncode({'muId': muId, 'readChapters': readChapters}),
    );
  }

  /// Signale le nouveau total puis rejoue le PUT **une seule fois**.
  ///
  /// Échoue silencieusement (retour `false`, comme avant) si le
  /// signalement est refusé — bornes (400), throttle (429), manga hors
  /// bibliothèque (404) ou réseau. Le flux de lecture n'est jamais bloqué
  /// et aucune boucle de retry n'est possible : le rejeu n'active pas
  /// [autoReportIfAboveTotal].
  Future<bool> _reportThenRetryProgress(int muId, int readChapters) async {
    try {
      await _chapterReportService.reportMoreChapters(muId, readChapters);
    } on ChapterReportException catch (e) {
      debugPrint('⚠️ auto-report chapitres refusé : ${e.failure}');
      return false;
    } catch (e) {
      debugPrint('⚠️ auto-report chapitres indisponible : $e');
      return false;
    }

    try {
      final res = await _putChapterProgress(muId, readChapters);
      final success = res.statusCode == HttpStatus.ok;
      if (success) await _cacheService.invalidateRecommendationsCache();
      return success;
    } catch (e) {
      // Réseau tombé entre le signalement et le rejeu : on ne perd pas la
      // progression, elle repart par la queue offline comme d'habitude.
      // Un rejet de session, lui, remonte au lieu d'être mis en file.
      return await _queueUnlessRejected(
          OfflineAction.saveChapterProgress(muId, readChapters,
              confirmedByUser: true),
          e);
    }
  }


  // ─────────── DELETE /library/delete ───────────
  Future<bool> removeMangaFromLibrary(int muId) async {
    final isOnline = _connectivityService.isConnected;
    
    if (isOnline) {
      try {
        final url = buildApiUri('/library/delete');
        final success = await _postOrDelete(
          method: _http.deleteWithAuthTokens,
          url: url,
          muId: muId,
        );
        if (success) await _cacheService.invalidateRecommendationsCache();
        if (success) _markInIndex(muId, owned: false);
        return success;
      } catch (e) {
        // Rejet de session => refus, pas de mise en file.
        return await _queueUnlessRejected(OfflineAction.removeManga(muId), e);
      }
    } else {
      // Mode hors ligne : ajouter à la queue
      await _cacheService.queueOfflineAction(OfflineAction.removeManga(muId));
      _markInIndex(muId, owned: false);
      return true; // Retourner true car l'action est en queue
    }
  }

  // ─────────── Update /library/status ───────────
  Future<bool> updateMangaStatus(int muId, ReadingStatus status) async {
    final isOnline = _connectivityService.isConnected;
    
    if (isOnline) {
      try {
        final url = buildApiUri('/library/status');
        final response = await _http.putWithAuthTokens(
          url,
          headers: {HttpHeaders.contentTypeHeader: 'application/json'},
          body: jsonEncode({
            'muId': muId,
            'readingStatus': status.value,
          }),
        );
        final success = response.statusCode == HttpStatus.ok;
        if (success) await _cacheService.invalidateRecommendationsCache();
        return success;
      } catch (e) {
        // Rejet de session => refus, pas de mise en file.
        return await _queueUnlessRejected(
            OfflineAction.updateMangaStatus(muId, status), e);
      }
    } else {
      // Mode hors ligne : ajouter à la queue
      await _cacheService.queueOfflineAction(OfflineAction.updateMangaStatus(muId, status));
      return true; // Retourner true car l'action est en queue
    }
  }

// ─────────── PUT /library/custom-link ───────────
  Future<bool> updateCustomLink(int muId, String customLink) async {
    final isOnline = _connectivityService.isConnected;
    
    if (isOnline) {
      try {
        final url = buildApiUri('/library/custom-link');
        final res = await _http.putWithAuthTokens(
          url,
          headers: {HttpHeaders.contentTypeHeader: 'application/json'},
          body: jsonEncode({'muId': muId, 'customLink': customLink}),
        );
        final success = res.statusCode == HttpStatus.ok;
        // Cache en mémoire désactivé - plus besoin de le vider
        return success;
      } catch (e) {
        // Rejet de session => refus, pas de mise en file.
        return await _queueUnlessRejected(
            OfflineAction.updateCustomLink(muId, customLink), e);
      }
    } else {
      // Mode hors ligne : ajouter à la queue
      await _cacheService.queueOfflineAction(OfflineAction.updateCustomLink(muId, customLink));
      return true; // Retourner true car l'action est en queue
    }
  }

// ─────────── PUT /library/rating ───────────
  /// Met à jour la note personnelle de l'utilisateur pour un manga (0-10).
  /// `rating = 0` supprime la note. Le manga doit déjà être en bibliothèque.
  Future<bool> updateRating(int muId, int rating) async {
    if (rating < 0 || rating > 10) {
      throw ArgumentError('Rating must be between 0 and 10, got $rating');
    }

    final isOnline = _connectivityService.isConnected;

    if (isOnline) {
      try {
        final url = buildApiUri('/library/rating');
        final res = await _http.putWithAuthTokens(
          url,
          headers: {HttpHeaders.contentTypeHeader: 'application/json'},
          body: jsonEncode({'muId': muId, 'rating': rating}),
        );
        final success = res.statusCode == HttpStatus.ok;
        // La note est un multiplicateur du scoring des recos.
        if (success) await _cacheService.invalidateRecommendationsCache();
        return success;
      } catch (e) {
        debugPrint('⚠️ updateRating: erreur réseau ($e)');
        return false;
      }
    }
    // Mode hors ligne : pas de queue pour le rating (action non critique)
    debugPrint('⚠️ updateRating: hors ligne, ignoré');
    return false;
  }

// ─────────── DELETE /library/custom-link ───────────
  Future<bool> deleteCustomLink(int muId) async {
    final isOnline = _connectivityService.isConnected;
    
    if (isOnline) {
      try {
        final url = buildApiUri('/library/custom-link');
        final res = await _http.deleteWithAuthTokens(
          url,
          headers: {HttpHeaders.contentTypeHeader: 'application/json'},
          body: jsonEncode({'muId': muId}),
        );
        final success = res.statusCode == HttpStatus.ok;
        // Cache en mémoire désactivé - plus besoin de le vider
        return success;
      } catch (e) {
        // Rejet de session => refus, pas de mise en file.
        return await _queueUnlessRejected(OfflineAction.deleteCustomLink(muId), e);
      }
    } else {
      // Mode hors ligne : ajouter à la queue
      await _cacheService.queueOfflineAction(OfflineAction.deleteCustomLink(muId));
      return true; // Retourner true car l'action est en queue
    }
  }

  /// Mise en file sauf session rejetée — règle partagée, cf.
  /// [OfflineWriteQueue.queueUnlessRejected].
  Future<bool> _queueUnlessRejected(OfflineAction action, Object error) =>
      _writeQueue.queueUnlessRejected(action, error);

  // ─────────── UTILS & HELPERS ───────────


  /// Entrée bibliothèque d'un manga, **avec repli sur le cache local**.
  ///
  /// C'est cette entrée qui porte « où j'en suis » : chapitres lus, statut de
  /// lecture, total effectif. Sans repli, un chargement hors ligne du détail
  /// perdait silencieusement la progression — la page s'affichait comme si le
  /// manga n'était pas dans la bibliothèque, ce qui vide de son sens la
  /// consultation hors ligne.
  Future<MangaQuickViewDto?> getLibraryEntry(int muId) async {
    List<MangaQuickViewDto>? library;
    try {
      library = await getUserSavedMangas();
      // Rafraîchit le cache au passage : la progression reste consultable
      // même si la bibliothèque n'a pas été ouverte récemment.
      await _cacheService.cacheLibrary(library);
    } catch (e) {
      // LECTURE : le cache est servi dans tous les modes d'échec, rejet
      // serveur compris. Sans ça, « où j'en suis » disparaissait de l'écran
      // détail alors que la progression était déjà en cache localement.
      debugPrint('📚 LibraryService: entrée bibliothèque servie depuis le cache');
      library = await _cacheService.getCachedLibrary();
    }

    if (library == null) return null;
    for (final manga in library) {
      if (manga.muId == muId) return manga;
    }
    return null;
  }

  /// Récupère la progression lue pour un manga, ou -1 si absent.
  Future<num> getReadChapterByUid(int muId) async {
    final manga = await getLibraryEntry(muId);
    return  manga?.readChapters ?? -1;
  }

  Future<ReadingStatus?> getReadingStatusByUid(int muId) async {
    final manga = await getLibraryEntry(muId);
    return  manga?.readingStatus;
  }

  /// Récupère le customLink d'un manga, ou null si absent.
  ///
  /// Lu dans l'entrée de bibliothèque (`/library/all`, avec repli sur le
  /// cache) : le lien appartient à l'utilisateur. Avant, chaque appel
  /// téléchargeait la fiche complète du manga (`GET /mangas/:id`) pour n'en
  /// lire que ce champ, et renvoyait toujours `null` hors ligne.
  Future<String?> getCustomLink(int muId) async {
    try {
      final link = (await getLibraryEntry(muId))?.customLink;
      return link == null || link.isEmpty ? null : link;
    } catch (e) {
      debugPrint('⚠️ LibraryService: lien de lecture indisponible ($e)');
      return null;
    }
  }

  Future<List<MangaQuickViewDto>> _fetchMangaList(Uri url) async {
    final res = await _http.getWithAuthTokens(url);
    if (res.statusCode == HttpStatus.ok ||
        res.statusCode == HttpStatus.created) {
      final data = jsonDecode(res.body) as List<dynamic>;
      return data.map((e) => MangaQuickViewDto.fromJson(e)).toList();
    }
    if (res.statusCode == HttpStatus.forbidden) {
      // Verdict explicite du serveur : doit se classer en `sessionRejected`
      // (une `Exception` nue tombait dans `FailureMode.other`).
      throw InvalidCredentialsException('403 sur ${url.path}');
    }
    throw Exception('HTTP ${res.statusCode} : ${res.body}');
  }

  Future<bool> _postOrDelete({
    required Future<Response> Function(
        Uri url, {
        Map<String, String>? headers,
        Object? body,
        })
    method,
    required Uri url,
    required int muId,
    int expectStatus = HttpStatus.ok,
    String bodyKey = 'muId',
    bool Function(Response res)? alsoSuccess,
  }) async {
    final res = await method(
      url,
      headers: {HttpHeaders.contentTypeHeader: 'application/json'},
      body: jsonEncode({bodyKey: muId}),
    );

    if (res.statusCode == expectStatus) return true;
    if (alsoSuccess?.call(res) ?? false) return true;
    if (res.statusCode == HttpStatus.forbidden) {
      throw InvalidCredentialsException('403 sur ${url.path}');
    }
    return false;
  }

}