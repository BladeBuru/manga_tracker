// features/library/services/library.service.dart
import 'dart:convert';
import 'dart:io';

import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:http/http.dart';
import 'package:mangatracker/core/network/http_service.dart';
import 'package:mangatracker/core/service_locator/service_locator.dart';
import 'package:mangatracker/features/manga/dto/manga_quick_view.dto.dart';

class LibraryService {
  final HttpService _http = getIt<HttpService>();

  Future<LibraryService> init() async => this;

  // ─────────── GET /library/all ───────────
  Future<List<MangaQuickViewDto>> getUserSavedMangas() async {
    final url = Uri.https(dotenv.env['MT_API_URL']!, '/library/all');
    return _fetchMangaList(url);
  }

  // ─────────── POST /library/save ───────────

  Future<bool> addMangaToLibrary(int muId) async {
    final url = Uri.https(dotenv.env['MT_API_URL']!, '/library/save');
    return _postOrDelete(
      method: _http.postWithAuthTokens,
      url: url,
      muId: muId,
      expectStatus: HttpStatus.created,
    );
  }


  // ─────────── PUT /library/chapter ───────────
  Future<bool> saveChapterProgress(int muId, int readChapters) async {
    final url = Uri.https(dotenv.env['MT_API_URL']!, '/library/chapter');
    final res = await _http.putWithAuthTokens(
      url,
      headers: {HttpHeaders.contentTypeHeader: 'application/json'},
      body: jsonEncode({'muId': muId, 'readChapters': readChapters}),
    );
    return res.statusCode == HttpStatus.ok;
  }

  // ─────────── DELETE /library/delete ───────────
  Future<bool> removeMangaFromLibrary(int muId) async {
    final url = Uri.https(dotenv.env['MT_API_URL']!, '/library/delete');
    return _postOrDelete(
      method: _http.deleteWithAuthTokens,
      url: url,
      muId: muId,
    );
  }

  // ─────────── GET /favorites/all ───────────
  Future<List<int>> getReadLaterList() async {
    final url = Uri.https(dotenv.env['MT_API_URL']!, '/favorites/all');
    final res = await _http.getWithAuthTokens(
      url,
      headers: {HttpHeaders.contentTypeHeader: 'application/json'},
    );
    if (res.statusCode != HttpStatus.ok) {
      throw Exception('Impossible de charger la liste ReadLater');
    }
    final List<dynamic> list = jsonDecode(res.body);
    return list.map((e) => e['mangaId'] as int).toList();
  }

  // ─────────── POST /favorites/save ───────────
  Future<bool> addToReadLater(int mangaId) async {
    final url = Uri.https(dotenv.env['MT_API_URL']!, '/favorites/save');
    return _postOrDelete(
      method: _http.postWithAuthTokens,
      url: url,
      muId: mangaId,
      expectStatus: HttpStatus.created,
      bodyKey: 'mangaId',
    );
  }

  // ─────────── DELETE /favorites/delete ───────────
  Future<bool> removeFromReadLater(int mangaId) async {
    final url = Uri.https(dotenv.env['MT_API_URL']!, '/favorites/delete');
    return _postOrDelete(
      method: _http.deleteWithAuthTokens,
      url: url,
      muId: mangaId,
      bodyKey: 'mangaId',
    );
  }
  // ─────────── UTILS & HELPERS ───────────

  /// Récupère la progression lue pour un manga, ou -1 si absent.
  Future<num> getReadChapterByUid(int muId) async {
    final saved = await getUserSavedMangas();

    for (final m in saved) {
      if (m.muId == muId) {
        // Si trouvé, renvoie la progression (ou -1 si null)
        return m.readChapters ?? 0;
      }
    }
    // Si pas trouvé
    return -1;
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