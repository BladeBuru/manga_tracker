import 'dart:convert';

import 'package:mangatracker/core/network/http_service.dart';
import 'package:mangatracker/core/network/network_compat.dart';
import 'package:mangatracker/core/network/uri_builder.dart';
import 'package:mangatracker/core/service_locator/service_locator.dart';
import 'package:mangatracker/features/manga/dto/community_recommendation.dto.dart';
import 'package:mangatracker/features/manga/dto/rating_summary.dto.dart';

/// Échec d'un vote de recommandation, pour choisir le message affiché.
enum CommunityFailure { throttled, invalid, unknown }

class CommunityException implements Exception {
  final CommunityFailure failure;
  final int statusCode;

  const CommunityException(this.failure, this.statusCode);

  @override
  String toString() => 'CommunityException($failure, HTTP $statusCode)';
}

/// Contributions de la communauté sur une œuvre : note globale et
/// recommandations « si vous avez aimé ce titre, lisez… ».
///
/// Pas d'enregistrement obligatoire dans GetIt : `HttpService` est résolu
/// au moment de l'appel (même doctrine que `RecommendationDismissalService`
/// — l'ordre du service locator n'est pas touché).
class CommunityService {
  final HttpService? _httpOverride;

  const CommunityService({HttpService? httpService})
    : _httpOverride = httpService;

  HttpService get _http => _httpOverride ?? getIt<HttpService>();

  /// Note globale et total des votes, lus en base par l'API (aucun appel
  /// MangaUpdates) — redemandés juste après un vote de l'utilisateur.
  Future<RatingSummaryDto?> getRatingSummary(num muId) async {
    final response = await _http.getWithAuthTokens(
      buildApiUri('/mangas/$muId/ratings'),
    );
    if (response.statusCode != HttpStatus.ok) return null;
    return RatingSummaryDto.fromJson(
      jsonDecode(response.body) as Map<String, dynamic>,
    );
  }

  /// Recommandations d'une fiche, votes MangaUpdates + Manga Tracker.
  Future<List<CommunityRecommendationDto>> getRecommendations(num muId) async {
    final response = await _http.getWithAuthTokens(
      buildApiUri('/mangas/$muId/community-recommendations'),
    );
    _throwIfNotSuccess(response.statusCode);
    final body = jsonDecode(response.body) as Map<String, dynamic>;
    return (body['items'] as List? ?? const [])
        .whereType<Map>()
        .map(
          (e) => CommunityRecommendationDto.fromJson(e.cast<String, dynamic>()),
        )
        .toList();
  }

  /// « Qui a aimé [muId] aimera [targetMuId] ». Idempotent côté serveur.
  /// [title] sert si l'œuvre recommandée n'est pas encore connue de l'API.
  Future<CommunityRecommendationDto> recommend(
    num muId,
    num targetMuId, {
    String? title,
  }) async {
    final response = await _http.putWithAuthTokens(
      buildApiUri('/mangas/$muId/community-recommendations/$targetMuId'),
      headers: {HttpHeaders.contentTypeHeader: 'application/json'},
      body: jsonEncode({if (title != null && title.isNotEmpty) 'title': title}),
    );
    _throwIfNotSuccess(response.statusCode);
    return CommunityRecommendationDto.fromJson(
      jsonDecode(response.body) as Map<String, dynamic>,
    );
  }

  /// Retire la recommandation de l'utilisateur.
  Future<CommunityRecommendationDto> unrecommend(
    num muId,
    num targetMuId,
  ) async {
    final response = await _http.deleteWithAuthTokens(
      buildApiUri('/mangas/$muId/community-recommendations/$targetMuId'),
    );
    _throwIfNotSuccess(response.statusCode);
    return CommunityRecommendationDto.fromJson(
      jsonDecode(response.body) as Map<String, dynamic>,
    );
  }

  void _throwIfNotSuccess(int statusCode) {
    if (statusCode == HttpStatus.ok || statusCode == HttpStatus.created) {
      return;
    }
    switch (statusCode) {
      case HttpStatus.tooManyRequests:
        throw CommunityException(CommunityFailure.throttled, statusCode);
      case HttpStatus.badRequest:
      case HttpStatus.notFound:
        throw CommunityException(CommunityFailure.invalid, statusCode);
      default:
        throw CommunityException(CommunityFailure.unknown, statusCode);
    }
  }
}
