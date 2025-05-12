// features/library/services/library.service.dart
import 'dart:convert';
import 'dart:io';

import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:http/http.dart';
import 'package:mangatracker/core/network/http_service.dart';
import 'package:mangatracker/core/service_locator/service_locator.dart';
import 'package:mangatracker/features/auth/exceptions/invalid_credentials.exception.dart';
import 'package:mangatracker/features/manga/dto/manga_quick_view.dto.dart';

class LibraryService {
  final HttpService _httpService = getIt<HttpService>();

  Future<LibraryService> init() async => this;

  // ─────────── Lecture ───────────
  Future<List<MangaQuickViewDto>> getUserSavedMangas() async {
    final url = Uri.https(dotenv.env['MT_API_URL']!, '/library/all');
    return _fetchMangaList(url);
  }

  Future<bool> isInLibrary(int muId) async {
    final list = await getUserSavedMangas();
    return list.any((m) => m.muId == muId);
  }

  // ─────────── Ajout / Suppression ───────────
  Future<void> saveManga(int muId) async {
    final url = Uri.https(dotenv.env['MT_API_URL']!, '/library/save');
    await _postOrDelete(
      method: _httpService.postWithAuthTokens,
      url: url,
      muId: muId,
      successCode: HttpStatus.ok,
    );
  }

  Future<void> deleteManga(int muId) async {
    final url = Uri.https(dotenv.env['MT_API_URL']!, '/library/delete');
    await _postOrDelete(
      method: _httpService.deleteWithAuthTokens,
      url: url,
      muId: muId,
      successCode: HttpStatus.ok,
    );
  }

  // ─────────── Helpers ───────────
  Future<List<MangaQuickViewDto>> _fetchMangaList(Uri url) async {
    final Response res = await _httpService.getWithAuthTokens(url);

    if (res.statusCode == HttpStatus.ok ||
        res.statusCode == HttpStatus.created) {
      final data = jsonDecode(res.body) as List<dynamic>;
      return data.map((e) => MangaQuickViewDto.fromJson(e)).toList();
    } else if (res.statusCode == HttpStatus.forbidden) {
      throw InvalidCredentialsException(
          'Not authorized to access this resource');
    } else {
      throw Exception(
          'HTTP Request failed with status: ${res.statusCode}.');
    }
  }

  Future<void> _postOrDelete({
    required Future<Response> Function(Uri,
        {Map<String, String>? headers, Object? body})
    method,
    required Uri url,
    required int muId,
    required int successCode,
  }) async {
    final res = await method(
      url,
      headers: {HttpHeaders.contentTypeHeader: 'application/json'},
      body: jsonEncode({'muId': muId}),
    );

    if (res.statusCode == successCode) return;

    if (res.statusCode == HttpStatus.forbidden) {
      throw InvalidCredentialsException(
          'Not authorized to access this resource');
    } else {
      throw Exception(
          'HTTP Request failed with status: ${res.statusCode}.');
    }
  }
}
