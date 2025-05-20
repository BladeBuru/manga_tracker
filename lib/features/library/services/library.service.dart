import 'dart:convert';

import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:http/http.dart';
import 'package:mangatracker/core/service_locator/service_locator.dart';
import 'package:mangatracker/features/manga/services/manga.service.dart';

import '../../manga/dto/manga_quick_view.dto.dart';
import '../../../core/network/http_service.dart';

class LibraryService {
  final HttpService _httpService = getIt<HttpService>();

  /// Récupère la liste des mangas sauvegardés de l'utilisateur
  Future<List<MangaQuickViewDto>> getUserSavedMangas() async {
    final mangaService = getIt<MangaService>();

    final apiUrl = dotenv.env['MT_API_URL']!;
    final url = Uri.https(apiUrl, '/library/all');
    return mangaService.getMangas(url);
  }


  /// Ajoute un manga à la bibliothèque via POST /library/save
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

  /// Sauvegarde la progression de lecture d'un chapitre via PUT /library/chapter
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
}

