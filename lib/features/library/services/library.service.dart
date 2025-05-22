import 'dart:convert';

import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:mangatracker/core/service_locator/service_locator.dart';
import 'package:mangatracker/features/manga/services/manga.service.dart';

import '../../manga/dto/manga_quick_view.dto.dart';
import '../../../core/network/http_service.dart';

class LibraryService {
  final HttpService _httpService = getIt<HttpService>();


  Future<List<MangaQuickViewDto>> getUserSavedMangas() async {
    final mangaService = getIt<MangaService>();

    final apiUrl = dotenv.env['MT_API_URL']!;
    final url = Uri.https(apiUrl, '/library/all');
    return mangaService.getMangas(url);
  }



  Future<bool> addMangaToLibrary(String mangaId) async {
    final apiUrl = dotenv.env['MT_API_URL']!;
    final url = Uri.https(apiUrl, '/library/save');
    final body = jsonEncode({
      'muId': num.tryParse(mangaId) ?? 0,
    });

    final response = await _httpService.postWithAuthTokens (
      url,
      headers: {'Content-Type': 'application/json'},
      body: body,
    );

    return response.statusCode == 201;
  }

  Future<bool> saveChapterProgress(String mangaId, num chapterNumber) async {
    final apiUrl = dotenv.env['MT_API_URL']!;
    final url = Uri.https(apiUrl, '/library/chapter');
    final body = jsonEncode({
      'muId': num.tryParse(mangaId) ?? 0,
      'readChapters': chapterNumber,
    });

    final response = await _httpService.putWithAuthTokens(
      url,
      headers: {'Content-Type': 'application/json'},
      body: body,
    );

    return response.statusCode == 200;
  }


  Future<bool> removeMangaFromLibrary(String mangaId) async {
    final apiUrl = dotenv.env['MT_API_URL']!;
    final url = Uri.https(apiUrl, '/library/delete');
    final body = jsonEncode({'muId': num.tryParse(mangaId) ?? 0});

    final response = await _httpService.deleteWithAuthTokens(
      url,
      headers: {'Content-Type': 'application/json'},
      body: body,
    );
    return response.statusCode == 200;
  }


  Future<List<num>> getReadLaterList() async {
    final apiUrl = dotenv.env['MT_API_URL']!;
    final url    = Uri.https(apiUrl, '/favorites/all');
    final res    = await _httpService.getWithAuthTokens(url, headers: {
      'Content-Type': 'application/json',
    });

    if (res.statusCode != 200) {
      throw Exception('Impossible de charger la liste « À lire plus tard »');
    }

    final List<dynamic> jsonList = jsonDecode(res.body);
    return jsonList
        .map((item) => (item['mangaId'] as num))
        .toList();
  }
  Future<bool> addToReadLater(String mangaId) async {
    final apiUrl = dotenv.env['MT_API_URL']!;
    final url    = Uri.https(apiUrl, '/favorites/save');
    final body   = jsonEncode({'mangaId': num.tryParse(mangaId) ?? 0});

    final res = await _httpService.postWithAuthTokens(
      url,
      headers: {'Content-Type': 'application/json'},
      body: body,
    );
    return res.statusCode == 201;
  }


  Future<bool> removeFromReadLater(String mangaId) async {
    final apiUrl = dotenv.env['MT_API_URL']!;
    final url    = Uri.https(apiUrl, '/favorites/delete');
    final body   = jsonEncode({'mangaId': num.tryParse(mangaId) ?? 0});

    final res = await _httpService.deleteWithAuthTokens (
      url,
      headers: {'Content-Type': 'application/json'},
      body: body,
    );
    return res.statusCode == 200;
  }


  Future<num> getReadChapterByUid(String muId) async {
    final parsedId = num.tryParse(muId);
    if (parsedId == null) {
      return 0;
    }
    final saved = await getUserSavedMangas();
    for (final m in saved) {
      if (m.muId == parsedId) {
        return m.readChapters ?? 0;
      }
    }
    return -1;
  }

}

