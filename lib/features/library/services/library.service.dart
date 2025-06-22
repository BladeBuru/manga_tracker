import 'dart:convert';
import 'dart:io';

import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:http/http.dart';
import 'package:mangatracker/core/network/http_service.dart';
import 'package:mangatracker/core/service_locator/service_locator.dart';
import 'package:mangatracker/features/manga/dto/manga_quick_view.dto.dart';

import '../../manga/dto/reading_status.enum.dart';

class LibraryService {
  final HttpService _http = getIt<HttpService>();
  Future<LibraryService> init() async => this;
  List<MangaQuickViewDto>? _userLibraryCache;


  // ─────────── GET /library/all ───────────
  Future<List<MangaQuickViewDto>> getUserSavedMangas() async {
    if (_userLibraryCache != null) {
      return _userLibraryCache!;
    }
    final url = Uri.https(dotenv.env['MT_API_URL']!, '/library/all');
    final library = await _fetchMangaList(url);
    _userLibraryCache = library;
    return library;
  }

  // ─────────── POST /library/save ───────────

  Future<bool> addMangaToLibrary(int muId) async {
    final url = Uri.https(dotenv.env['MT_API_URL']!, '/library/save');
    final success = await _postOrDelete(
      method: _http.postWithAuthTokens,
      url: url,
      muId: muId,
      expectStatus: HttpStatus.created,
    );
    if (success) _userLibraryCache = null; // On vide le cache
    return success;
  }


  // ─────────── PUT /library/chapter ───────────
  Future<bool> saveChapterProgress(int muId, int readChapters) async {
    final url = Uri.https(dotenv.env['MT_API_URL']!, '/library/chapter');
    final res = await _http.putWithAuthTokens(
      url,
      headers: {HttpHeaders.contentTypeHeader: 'application/json'},
      body: jsonEncode({'muId': muId, 'readChapters': readChapters}),
    );
    final success = res.statusCode == HttpStatus.ok;
    if (success) _userLibraryCache = null; // On vide le cache
    return success;
  }


  // ─────────── DELETE /library/delete ───────────
  Future<bool> removeMangaFromLibrary(int muId) async {
    final url = Uri.https(dotenv.env['MT_API_URL']!, '/library/delete');
    final success = await _postOrDelete(
      method: _http.deleteWithAuthTokens,
      url: url,
      muId: muId,
    );
    if (success) _userLibraryCache = null; // On vide le cache
    return success;
  }

  // ─────────── Update /library/status ───────────
  Future<bool> updateMangaStatus(int muId, ReadingStatus status) async {
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
    if (success) _userLibraryCache = null;
    return success;
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