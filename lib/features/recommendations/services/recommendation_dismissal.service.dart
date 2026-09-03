import 'dart:convert';

import 'package:mangatracker/core/network/http_service.dart';
import 'package:mangatracker/core/network/network_compat.dart';
import 'package:mangatracker/core/network/uri_builder.dart';
import 'package:mangatracker/core/service_locator/service_locator.dart';
import 'package:mangatracker/core/services/offline_cache_service.dart';
import 'package:mangatracker/features/recommendations/dto/dismissal_reason.dart';

/// Cause d'échec d'un rejet, pour choisir le message affiché.
enum DismissalFailure {
  /// Quota serveur atteint (60 rejets par heure et par utilisateur).
  throttled,

  /// Manga inconnu du catalogue, ou rejet déjà annulé côté serveur.
  notFound,

  /// Tout le reste (5xx, réponse inattendue).
  unknown,
}

class DismissalException implements Exception {
  final DismissalFailure failure;
  final int statusCode;

  const DismissalException(this.failure, this.statusCode);

  @override
  String toString() => 'DismissalException($failure, HTTP $statusCode)';
}

/// Rejets « pas intéressé / déjà vu » sur les recommandations.
///
/// Volontairement séparé de `RecommendationService` (lecture des recos) :
/// ce service ne fait que des mutations, et surtout il doit **invalider le
/// cache local des recommandations** après chaque écriture. Sans ça, le
/// cache front (TTL 2 h sur la première page) re-servirait le titre écarté
/// au prochain affichage alors que le serveur, lui, l'a déjà retiré — le
/// geste paraîtrait sans effet.
///
/// Les erreurs ne sont pas avalées, contrairement aux lectures de
/// recommandations : un rejet est une action explicite de l'utilisateur, un
/// échec silencieux lui laisserait croire que c'est fait.
class RecommendationDismissalService {
  final HttpService? _httpOverride;
  final OfflineCacheService? _cacheOverride;

  /// Les dépendances sont injectables pour les tests, sinon résolues depuis
  /// GetIt **au moment de l'appel** et non à la construction.
  ///
  /// C'est délibéré : une résolution à la construction obligerait à déclarer
  /// un `dependsOn` et donc à placer cet enregistrement après celui de
  /// `OfflineCacheService`. Le repo a déjà connu une régression d'écran blanc
  /// en production causée par un `dependsOn` sur un type pas encore
  /// enregistré — ce service est donc insensible à l'ordre du service locator.
  const RecommendationDismissalService({
    HttpService? httpService,
    OfflineCacheService? cacheService,
  }) : _httpOverride = httpService,
       _cacheOverride = cacheService;

  HttpService get _http => _httpOverride ?? getIt<HttpService>();
  OfflineCacheService get _cache => _cacheOverride ?? getIt<OfflineCacheService>();

  /// Écarte un titre : il ne remontera plus dans aucune recommandation.
  ///
  /// Rejeter deux fois le même titre est sans danger — l'API fait un upsert
  /// et met simplement à jour la raison.
  ///
  /// Lève [DismissalException] sur erreur serveur, et laisse remonter
  /// `SocketException` hors ligne (l'appelant affiche alors un message
  /// dédié plutôt que l'erreur générique).
  Future<void> dismiss(num muId, DismissalReason reason) async {
    final response = await _http.postWithAuthTokens(
      buildApiUri('/recommendations/dismissals/$muId'),
      headers: {HttpHeaders.contentTypeHeader: 'application/json'},
      body: jsonEncode({'reason': reason.wireValue}),
    );

    _throwIfNotSuccess(response.statusCode, const [
      HttpStatus.created,
      HttpStatus.ok,
    ]);
    await _cache.invalidateRecommendationsCache();
  }

  /// Annule un rejet : le titre redevient recommandable.
  ///
  /// Utilisé par l'action « Annuler » proposée juste après le rejet. Un 404
  /// (rejet déjà annulé) est remonté comme [DismissalFailure.notFound] :
  /// l'appelant peut décider de le traiter comme un succès.
  Future<void> restore(num muId) async {
    final response = await _http.deleteWithAuthTokens(
      buildApiUri('/recommendations/dismissals/$muId'),
    );

    _throwIfNotSuccess(response.statusCode, const [
      HttpStatus.noContent,
      HttpStatus.ok,
    ]);
    await _cache.invalidateRecommendationsCache();
  }

  void _throwIfNotSuccess(int statusCode, List<int> accepted) {
    if (accepted.contains(statusCode)) return;
    switch (statusCode) {
      case HttpStatus.tooManyRequests:
        throw const DismissalException(
          DismissalFailure.throttled,
          HttpStatus.tooManyRequests,
        );
      case HttpStatus.notFound:
        throw const DismissalException(
          DismissalFailure.notFound,
          HttpStatus.notFound,
        );
      default:
        throw DismissalException(DismissalFailure.unknown, statusCode);
    }
  }
}
