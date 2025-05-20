import 'dart:convert';
import 'dart:io';

import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:http/http.dart';
import 'package:mangatracker/core/service_locator/service_locator.dart';
import 'package:mangatracker/features/auth/exceptions/invalid_credentials.exception.dart';
import 'package:mangatracker/features/manga/dto/manga_detail.dto.dart';
import 'package:mangatracker/core/network/http_service.dart';

import '../../library/services/library.service.dart';
import '../dto/manga_quick_view.dto.dart';

class MangaService {
  HttpService httpService = getIt<HttpService>();
  LibraryService libraryService = LibraryService();

  var offsetTop = 1;
  var offsetLatest = 1;

  Future<MangaService> init() async {
    return this;
  }

  Future<List<MangaQuickViewDto>> getMangas(Uri url,
      {bool post = false, Map<String, String> body = const {}}) async {
    Response response;
    if (post) {
      response = await httpService.postWithAuthTokens(url, body: body);
    } else {
      response = await httpService.getWithAuthTokens(url);
    }

    if (response.statusCode == HttpStatus.ok ||
        response.statusCode == HttpStatus.created) {
      dynamic data = jsonDecode(response.body);
      final List<MangaQuickViewDto> mangaList = [];
      for (var i = 0; i < data.length; i++) {
        mangaList.add(MangaQuickViewDto.fromJson(data[i]));
      }
      return mangaList;
    } else if (response.statusCode == HttpStatus.forbidden) {
      throw InvalidCredentialsException(
          "Not authorized to access this resource");
    } else {
      throw Exception(
          'HTTP Request Failed with status: ${response.statusCode}.');
    }
  }

  Future<List<MangaQuickViewDto>> getTrendingMangas() async {
    var queryParameters = {
      'offset': offsetTop.toString(),
      'limit': 25.toString(),
    };
    var url = Uri.https(
        dotenv.env['MT_API_URL']!, '/mangas/trending', queryParameters);
    return getMangas(url);
  }

  Future<List<MangaQuickViewDto>> getPopularMangas() async {
    var queryParameters = {
      'offset': offsetTop.toString(),
      'limit': 25.toString(),
    };
    var url = Uri.https(
        dotenv.env['MT_API_URL']!, '/mangas/popular', queryParameters);
    return getMangas(url);
  }

  Future<List<MangaQuickViewDto>> getNextPopularMangas() async {
    offsetTop++;
    return getPopularMangas();
  }

  Future<List<MangaQuickViewDto>> getNewMangas() async {
    var queryParameters = {
      'offset': offsetTop.toString(),
      'limit': 25.toString(),
    };
    Uri url =
        Uri.https(dotenv.env['MT_API_URL']!, '/mangas/new', queryParameters);
    return getMangas(url);
  }

  Future<List<MangaQuickViewDto>> getNextLatestManga() async {
    offsetLatest++;
    return getNewMangas();
  }

  Future<List<MangaQuickViewDto>> searchForMangas(String searchPattern) async {
    Uri url = Uri.https(dotenv.env['MT_API_URL']!, '/mangas/search');
    Map<String, String> body = {'search_pattern': searchPattern};

    return getMangas(url, post: true, body: body);
  }

  Future<MangaDetailDto> getMangaDetail(String muId) async {
    Uri url = Uri.https(dotenv.env['MT_API_URL']!, '/mangas/$muId');
    Response response = await httpService.getWithAuthTokens(url);
    if (response.statusCode == HttpStatus.ok) {
      return MangaDetailDto.fromJson(jsonDecode(response.body));
    } else if (response.statusCode == HttpStatus.forbidden) {
      throw InvalidCredentialsException(
          "Not authorized to access this resource");
    } else {
      throw Exception(
          'HTTP Request Failed with status: ${response.statusCode}.');
    }
  }


  Future<num> getReadChapterByUid(String muId) async {
    final parsedId = num.tryParse(muId);
    if (parsedId == null) {
       return 0;
    }
    final saved = await libraryService.getUserSavedMangas();
    for (final m in saved) {
      if (m.muId == parsedId) {
        return m.readChapters ?? 0;
      }
    }
    return -1;
  }


}
