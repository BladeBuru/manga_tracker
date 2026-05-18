import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:http/http.dart';
import 'package:mangatracker/core/network/http_service.dart';
import 'package:mangatracker/core/network/network_compat.dart';
import 'package:mangatracker/core/network/uri_builder.dart';
import 'package:mangatracker/core/service_locator/service_locator.dart';
import 'package:mangatracker/core/services/connectivity_service.dart';
import 'package:mangatracker/core/services/offline_cache_service.dart';
import 'package:mangatracker/features/manga/dto/manga_quick_view.dto.dart';
import 'package:mangatracker/features/manga/services/manga.service.dart';
import 'package:mangatracker/features/library/dto/chapter_log.dto.dart';

import '../../manga/dto/reading_status.enum.dart';

class LibraryService {
  final HttpService _http = getIt<HttpService>();
  MangaService get _mangaService => getIt<MangaService>();
  late final ConnectivityService _connectivityService;
  late final OfflineCacheService _cacheService;
  
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
        );
        // Cache en mémoire désactivé - plus besoin de le vider
        return success;
      } catch (e) {
        // En cas d'erreur réseau, ajouter à la queue
        await _cacheService.queueOfflineAction(OfflineAction.addManga(muId));
        return false;
      }
    } else {
      // Mode hors ligne : ajouter à la queue
      await _cacheService.queueOfflineAction(OfflineAction.addManga(muId));
      return true; // Retourner true car l'action est en queue
    }
  }


  // ─────────── PUT /library/chapter ───────────
  Future<bool> saveChapterProgress(int muId, int readChapters) async {
    final isOnline = _connectivityService.isConnected;
    
    if (isOnline) {
      try {
        final url = buildApiUri('/library/chapter');
        final res = await _http.putWithAuthTokens(
          url,
          headers: {HttpHeaders.contentTypeHeader: 'application/json'},
          body: jsonEncode({'muId': muId, 'readChapters': readChapters}),
        );
        final success = res.statusCode == HttpStatus.ok;
        // Cache en mémoire désactivé - plus besoin de le vider
        return success;
      } catch (e) {
        // En cas d'erreur réseau, ajouter à la queue
        await _cacheService.queueOfflineAction(OfflineAction.saveChapterProgress(muId, readChapters));
        return false;
      }
    } else {
      // Mode hors ligne : ajouter à la queue
      await _cacheService.queueOfflineAction(OfflineAction.saveChapterProgress(muId, readChapters));
      return true; // Retourner true car l'action est en queue
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
        // Cache en mémoire désactivé - plus besoin de le vider
        return success;
      } catch (e) {
        // En cas d'erreur réseau, ajouter à la queue
        await _cacheService.queueOfflineAction(OfflineAction.removeManga(muId));
        return false;
      }
    } else {
      // Mode hors ligne : ajouter à la queue
      await _cacheService.queueOfflineAction(OfflineAction.removeManga(muId));
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
        // Cache en mémoire désactivé - plus besoin de le vider
        return success;
      } catch (e) {
        // En cas d'erreur réseau, ajouter à la queue
        await _cacheService.queueOfflineAction(OfflineAction.updateMangaStatus(muId, status));
        return false;
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
        // En cas d'erreur réseau, ajouter à la queue
        await _cacheService.queueOfflineAction(OfflineAction.updateCustomLink(muId, customLink));
        return false;
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
        return res.statusCode == HttpStatus.ok;
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
        // En cas d'erreur réseau, ajouter à la queue
        await _cacheService.queueOfflineAction(OfflineAction.deleteCustomLink(muId));
        return false;
      }
    } else {
      // Mode hors ligne : ajouter à la queue
      await _cacheService.queueOfflineAction(OfflineAction.deleteCustomLink(muId));
      return true; // Retourner true car l'action est en queue
    }
  }

  // ─────────── UTILS & HELPERS ───────────


  Future<MangaQuickViewDto?> getLibraryEntry(int muId) async {
    final library = await getUserSavedMangas();
    try {
      return library.firstWhere((manga) => manga.muId == muId);
    } catch (e) {
      return null;
    }
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

  /// Récupère le customLink d'un manga, ou null si absent
  Future<String?> getCustomLink(int muId) async {
    final isOnline = _connectivityService.isConnected;
    
    if (isOnline) {
      try {
        // Récupérer les détails du manga depuis MangaService
        final mangaDetail = await _mangaService.getMangaDetail(muId.toString());
        return mangaDetail.customLink;
      } catch (e) {
        debugPrint('⚠️ LibraryService: Erreur lors de la récupération du customLink: $e');
        return null;
      }
    } else {
      // En mode offline, on ne peut pas récupérer le customLink
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
      throw Exception('Non autorisé à accéder à la ressource');
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
  }) async {
    final res = await method(
      url,
      headers: {HttpHeaders.contentTypeHeader: 'application/json'},
      body: jsonEncode({bodyKey: muId}),
    );

    if (res.statusCode == expectStatus) return true;
    if (res.statusCode == HttpStatus.forbidden) {
      throw Exception('Non autorisé à modifier la bibliothèque');
    }
    return false;
  }

  // ─────────── Phase 5 : log additif des chapitres ───────────

  /// Enregistre une session de lecture (insertion additive — replays OK).
  /// Le pointeur global `userReadChapters` reste géré par `updateChapter`.
  ///
  /// Pas de queue offline pour MVP : le log enrichit les stats, pas la
  /// progression — si la requête échoue, l'user perd juste une entrée
  /// historique, pas son avancement.
  Future<ChapterLogDto> recordChapterLog(
    int muId, {
    required num chapterNumber,
    bool isBonus = false,
    int? scrollPosition,
  }) async {
    final body = <String, dynamic>{
      'chapterNumber': chapterNumber,
      'isBonus': isBonus,
      if (scrollPosition != null) 'scrollPosition': scrollPosition,
    };
    final res = await _http.postWithAuthTokens(
      buildApiUri('/library/$muId/chapter-log'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode(body),
    );
    if (res.statusCode == HttpStatus.ok ||
        res.statusCode == HttpStatus.created) {
      return ChapterLogDto.fromJson(
        jsonDecode(res.body) as Map<String, dynamic>,
      );
    }
    throw Exception('recordChapterLog failed: ${res.statusCode}');
  }

  /// Toggle skip pour un chapitre (hors-série filler, etc.).
  Future<ChapterLogDto> toggleChapterSkip(
    int muId,
    num chapterNumber, {
    required bool skipped,
  }) async {
    final res = await _http.putWithAuthTokens(
      buildApiUri('/library/$muId/chapter/$chapterNumber/skip'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({'skipped': skipped}),
    );
    if (res.statusCode == HttpStatus.ok) {
      return ChapterLogDto.fromJson(
        jsonDecode(res.body) as Map<String, dynamic>,
      );
    }
    throw Exception('toggleChapterSkip failed: ${res.statusCode}');
  }

  /// Historique des sessions de lecture (replays, skips, bonus) pour un
  /// manga. Trié date décroissante côté serveur, max 500 entrées.
  Future<List<ChapterLogDto>> getChapterLog(int muId) async {
    final res = await _http.getWithAuthTokens(
      buildApiUri('/library/$muId/chapter-log'),
    );
    if (res.statusCode != HttpStatus.ok) {
      throw Exception('getChapterLog failed: ${res.statusCode}');
    }
    final list = jsonDecode(res.body) as List<dynamic>;
    return list
        .map((e) => ChapterLogDto.fromJson(e as Map<String, dynamic>))
        .toList();
  }
}