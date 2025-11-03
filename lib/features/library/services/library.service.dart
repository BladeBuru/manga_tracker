import 'dart:convert';
import 'dart:io';

import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:http/http.dart';
import 'package:mangatracker/core/network/http_service.dart';
import 'package:mangatracker/core/service_locator/service_locator.dart';
import 'package:mangatracker/core/services/connectivity_service.dart';
import 'package:mangatracker/core/services/offline_cache_service.dart';
import 'package:mangatracker/features/manga/dto/manga_quick_view.dto.dart';

import '../../manga/dto/reading_status.enum.dart';

class LibraryService {
  final HttpService _http = getIt<HttpService>();
  late final ConnectivityService _connectivityService;
  late final OfflineCacheService _cacheService;
  List<MangaQuickViewDto>? _userLibraryCache;
  
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
    final url = Uri.https(dotenv.env['MT_API_URL']!, '/library/all');
    final library = await _fetchMangaList(url);
    // _userLibraryCache = library; // Désactivé pour permettre la détection offline
    return library;
  }

  // ─────────── POST /library/save ───────────

  Future<bool> addMangaToLibrary(int muId) async {
    final isOnline = _connectivityService.isConnected;
    
    if (isOnline) {
      try {
        final url = Uri.https(dotenv.env['MT_API_URL']!, '/library/save');
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
        final url = Uri.https(dotenv.env['MT_API_URL']!, '/library/chapter');
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
        final url = Uri.https(dotenv.env['MT_API_URL']!, '/library/delete');
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
        final url = Uri.https(dotenv.env['MT_API_URL']!, '/library/status');
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
        final url = Uri.https(dotenv.env['MT_API_URL']!, '/library/custom-link');
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

// ─────────── DELETE /library/custom-link ───────────
  Future<bool> deleteCustomLink(int muId) async {
    final isOnline = _connectivityService.isConnected;
    
    if (isOnline) {
      try {
        final url = Uri.https(dotenv.env['MT_API_URL']!, '/library/custom-link');
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
}