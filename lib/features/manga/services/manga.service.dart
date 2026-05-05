import 'dart:async';
import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:http/http.dart';
import 'package:mangatracker/core/network/network_compat.dart';
import 'package:mangatracker/core/network/uri_builder.dart';
import 'package:mangatracker/core/service_locator/service_locator.dart';
import 'package:mangatracker/features/auth/exceptions/invalid_credentials.exception.dart';
import 'package:mangatracker/features/manga/dto/manga_detail.dto.dart';
import 'package:mangatracker/core/network/http_service.dart';

import '../../library/services/library.service.dart';
import '../dto/manga_quick_view.dto.dart';
import '../dto/manga_recommendation_view.dto.dart';

class MangaService {
  HttpService httpService = getIt<HttpService>();
  LibraryService get libraryService => getIt<LibraryService>();

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
    var url = buildApiUri('/mangas/trending', queryParameters);
    return getMangas(url);
  }

  Future<List<MangaQuickViewDto>> getPopularMangas() async {
    var queryParameters = {
      'offset': offsetTop.toString(),
      'limit': 25.toString(),
    };
    var url = buildApiUri('/mangas/popular', queryParameters);
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
    Uri url = buildApiUri('/mangas/new', queryParameters);
    return getMangas(url);
  }

  Future<List<MangaQuickViewDto>> getNextLatestManga() async {
    offsetLatest++;
    return getNewMangas();
  }

  Future<List<MangaQuickViewDto>> searchForMangas(String searchPattern) async {
    Uri url = buildApiUri('/mangas/search');
    Map<String, String> body = {'search_pattern': searchPattern};

    return getMangas(url, post: true, body: body);
  }

  Future<MangaDetailDto> getMangaDetail(String muId) async {
    Uri url = buildApiUri('/mangas/$muId');
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


  /// Récupère les recommandations détail d'un manga (proxy vers MangaUpdates).
  ///
  /// L'API externe MangaUpdates est lente — l'API interne a un timeout de 15s
  /// et batch les appels. Côté client, on applique :
  ///  - Timeout de 18s (légèrement > timeout API)
  ///  - 1 retry avec délai 500ms en cas de TimeoutException ou erreur réseau
  ///  - Liste vide si tout échoue (graceful degradation, pas de crash)
  ///
  /// L'appel API est TOUJOURS effectué (pas de cache local) — l'API externe
  /// fait foi.
  Future<List<MangaRecommendationView>> getMangaRecommendations(
    String muId,
  ) async {
    try {
      return await _fetchMangaRecommendations(muId);
    } on TimeoutException catch (e) {
      debugPrint('⚠️ MangaService.recommendations timeout, retry: $e');
      await Future.delayed(const Duration(milliseconds: 500));
      try {
        return await _fetchMangaRecommendations(muId);
      } catch (e2) {
        debugPrint('⚠️ MangaService.recommendations retry failed: $e2');
        return const [];
      }
    } on InvalidCredentialsException {
      // Auth invalide : on laisse remonter pour que le caller redirect vers login.
      rethrow;
    } catch (e) {
      // Erreur réseau (SocketException, etc.) → 1 retry puis liste vide.
      debugPrint('⚠️ MangaService.recommendations error, retry: $e');
      await Future.delayed(const Duration(milliseconds: 500));
      try {
        return await _fetchMangaRecommendations(muId);
      } catch (e2) {
        debugPrint('⚠️ MangaService.recommendations retry failed: $e2');
        return const [];
      }
    }
  }

  /// Appel HTTP brut avec timeout, sans retry (utilisé par
  /// [getMangaRecommendations] qui gère le retry).
  Future<List<MangaRecommendationView>> _fetchMangaRecommendations(
    String muId,
  ) async {
    Uri url = buildApiUri('/mangas/recommendations/$muId');

    Response response = await httpService
        .getWithAuthTokens(url)
        .timeout(const Duration(seconds: 18));

    if (response.statusCode == HttpStatus.ok) {
      dynamic data = jsonDecode(response.body);
      final List<MangaRecommendationView> mangaList = [];
      for (var i = 0; i < data.length; i++) {
        mangaList.add(MangaRecommendationView.fromJson(data[i]));
      }
      return mangaList;
    } else if (response.statusCode == HttpStatus.forbidden) {
      throw InvalidCredentialsException(
        "Not authorized to access this resource",
      );
    } else {
      throw Exception(
        'HTTP Request Failed with status: ${response.statusCode}.',
      );
    }
  }

}
