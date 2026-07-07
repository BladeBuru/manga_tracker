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
import '../dto/search_results_page.dto.dart';

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

  /// Recherche paginée de mangas.
  ///
  /// L'API renvoie une enveloppe `{results, totalHits, page, perPage, hasMore}`
  /// triée par pertinence (classement MangaUpdates, identique au site).
  /// L'enveloppe n'est renvoyée que si `page` est présent dans le body —
  /// c'est ce qui distingue les nouveaux clients des anciens (tableau nu).
  Future<SearchResultsPageDto> searchForMangas(
    String searchPattern, {
    int page = 1,
    int limit = 20,
  }) async {
    Uri url = buildApiUri('/mangas/search');
    Response response = await httpService.postWithAuthTokens(
      url,
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({
        'search_pattern': searchPattern,
        'page': page,
        'limit': limit,
      }),
    );

    if (response.statusCode == HttpStatus.ok ||
        response.statusCode == HttpStatus.created) {
      final decoded = jsonDecode(response.body);
      // Défense en profondeur : une API legacy (rollback serveur) renvoie
      // un tableau nu → synthétiser une enveloppe sans pagination plutôt
      // que de casser toute la recherche sur un cast.
      if (decoded is List) {
        final results = decoded
            .map((e) => MangaQuickViewDto.fromJson(e as Map<String, dynamic>))
            .toList();
        return SearchResultsPageDto(
          results: results,
          totalHits: results.length,
          page: 1,
          perPage: results.isEmpty ? limit : results.length,
          hasMore: false,
        );
      }
      return SearchResultsPageDto.fromJson(decoded as Map<String, dynamic>);
    } else if (response.statusCode == HttpStatus.forbidden) {
      throw InvalidCredentialsException(
          "Not authorized to access this resource");
    } else {
      throw Exception(
          'HTTP Request Failed with status: ${response.statusCode}.');
    }
  }

  /// Demande à l'API de rafraîchir les URLs de cover d'un manga (utile quand
  /// l'URL externe a expiré → 404). Retourne un [MangaQuickViewDto] avec les
  /// URLs fraîches.
  ///
  /// Endpoint API : `POST /mangas/:muId/refresh-cover`.
  Future<MangaQuickViewDto> refreshCover(int muId) async {
    Uri url = buildApiUri('/mangas/$muId/refresh-cover');
    Response response =
        await httpService.postWithAuthTokens(url).timeout(
      const Duration(seconds: 10),
    );
    if (response.statusCode == HttpStatus.ok ||
        response.statusCode == HttpStatus.created) {
      return MangaQuickViewDto.fromJson(jsonDecode(response.body));
    }
    if (response.statusCode == HttpStatus.forbidden) {
      throw InvalidCredentialsException(
        "Not authorized to access this resource",
      );
    }
    throw Exception(
      'refreshCover: HTTP ${response.statusCode}',
    );
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
