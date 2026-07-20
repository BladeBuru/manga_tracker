import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:mangatracker/core/network/http_service.dart';
import 'package:mangatracker/core/network/uri_builder.dart';
import 'package:mangatracker/core/service_locator/service_locator.dart';
import 'package:mangatracker/core/services/offline_cache_service.dart';
import 'package:mangatracker/features/manga/dto/manga_quick_view.dto.dart';

/// Service pour récupérer les recommandations personnalisées de l'utilisateur.
///
/// - Aucun `import 'dart:io'` (compatibilité Web).
/// - Cache offline via [OfflineCacheService] : si un fetch réseau échoue,
///   on retombe sur la dernière liste sauvegardée.
class RecommendationService {
  // Codes HTTP réutilisés (évite l'import dart:io).
  static const _httpOk = 200;
  static const _httpCreated = 201;
  static const _httpUnauthorized = 401;
  static const _httpForbidden = 403;

  HttpService get _httpService => getIt<HttpService>();
  OfflineCacheService get _cacheService => getIt<OfflineCacheService>();

  Future<RecommendationService> init() async => this;

  /// Retourne les recommandations regroupées par genre.
  /// Appelle `GET /recommendations/by-genre?topGenres=...&perGenre=...`.
  ///
  /// Renvoie une map `{ "Action": [...], "Romance": [...] }`. Vide si la
  /// bibliothèque est vide ou si erreur réseau (silencieux pour l'UX).
  Future<Map<String, List<MangaQuickViewDto>>> getRecommendationsByGenre({
    int topGenres = 5,
    int perGenre = 10,
  }) async {
    final url = buildApiUri('/recommendations/by-genre', {
      'topGenres': topGenres.toString(),
      'perGenre': perGenre.toString(),
    });

    try {
      final response = await _httpService.getWithAuthTokens(url);
      if (response.statusCode != _httpOk &&
          response.statusCode != _httpCreated) {
        return const {};
      }
      final raw = jsonDecode(response.body) as Map<String, dynamic>;
      return raw.map((genre, list) {
        final items = (list as List<dynamic>)
            .map((e) => MangaQuickViewDto.fromJson(e as Map<String, dynamic>))
            .toList();
        return MapEntry(genre, items);
      });
    } catch (e) {
      debugPrint(
        '⚠️ RecommendationService.byGenre: erreur ($e), section masquée',
      );
      return const {};
    }
  }

  /// Pépites cachées (`GET /recommendations/sleepers`) : sorties récentes
  /// bien notées (note Bayésienne — pas le 10/10 à un seul vote) mais peu
  /// visibles. Vide si erreur réseau (section masquée gracieusement).
  Future<List<MangaQuickViewDto>> getSleeperHits({int limit = 12}) async {
    final url = buildApiUri('/recommendations/sleepers', {
      'limit': limit.toString(),
    });
    try {
      final response = await _httpService.getWithAuthTokens(url);
      if (response.statusCode != _httpOk &&
          response.statusCode != _httpCreated) {
        return const [];
      }
      return (jsonDecode(response.body) as List<dynamic>)
          .map((e) => MangaQuickViewDto.fromJson(e as Map<String, dynamic>))
          .toList();
    } catch (e) {
      debugPrint('⚠️ RecommendationService.sleepers: erreur ($e)');
      return const [];
    }
  }

  /// Retourne la liste personnalisée de mangas recommandés pour l'utilisateur
  /// connecté.
  /// Appelle `GET /recommendations?limit=<limit>&offset=<offset>`.
  ///
  /// En cas d'échec réseau → retourne le cache offline si présent,
  /// sinon une liste vide silencieuse (UX : la section disparaît
  /// gracieusement).
  ///
  /// En cas d'auth invalide → liste vide sans toucher au cache (évite la fuite
  /// de données entre utilisateurs).
  Future<List<MangaQuickViewDto>> getPersonalizedRecommendations({
    int limit = 50,
    int offset = 0,
  }) async {
    // Cache hit TTL 2h sur la première page (hotfix-v0-10-1 US-5) : revenir
    // sur la page ne refetch plus systématiquement. 2h front vs 1h back :
    // le back garantit la fraîcheur réelle, le front peut servir un cache
    // légèrement plus vieux (stale-while-revalidate, RETRO-005).
    if (offset == 0) {
      final expired = await _cacheService.isCacheExpiredFor(
        'recommendations',
        maxHours: 2,
      );
      if (!expired) {
        final cached = await _cacheService.getCachedRecommendations();
        // Fix « page Tout plafonnée » : le fetch home (limit 10) écrit un
        // cache court — ne le servir que s'il couvre la page demandée, sinon
        // la vue paginée (pageSize 50) croit la liste terminée.
        //
        // Fix « refetch systématique » : un user qui a MOINS de `limit` recos
        // au total avait un cache toujours plus court que `limit` → refetch à
        // chaque affichage malgré le TTL. On sert donc aussi le cache quand il
        // est marqué exhaustif (le réseau a déjà renvoyé tout ce que le serveur
        // possède).
        if (cached != null && cached.isNotEmpty) {
          final exhaustive =
              await _cacheService.isRecommendationsCacheExhaustive();
          if (cached.length >= limit || exhaustive) {
            return cached;
          }
        }
      }
    }

    final url = buildApiUri('/recommendations', {
      'limit': limit.toString(),
      'offset': offset.toString(),
    });

    try {
      final response = await _httpService.getWithAuthTokens(url);

      if (response.statusCode == _httpOk ||
          response.statusCode == _httpCreated) {
        final data = jsonDecode(response.body) as List<dynamic>;
        final list = data
            .map((e) => MangaQuickViewDto.fromJson(e as Map<String, dynamic>))
            .toList();
        // Seule la première page est mise en cache — avant, chaque page de
        // pagination ÉCRASAIT le cache (retour sur la page = page N affichée
        // à la place du début de liste).
        //
        // `exhaustive` : le serveur a renvoyé moins que `limit` ⇒ il n'a plus
        // rien de plus. Mémorisé pour servir ce cache court sans refetch (cf.
        // garde-fou ci-dessus).
        if (offset == 0) {
          await _cacheService.cacheRecommendations(
            list,
            exhaustive: list.length < limit,
          );
        }
        return list;
      }

      if (response.statusCode == _httpUnauthorized ||
          response.statusCode == _httpForbidden) {
        return [];
      }

      // Autre code HTTP → fallback cache puis exception
      final cached = await _cacheService.getCachedRecommendations();
      if (cached != null) return cached;
      throw Exception('Recommendations: HTTP ${response.statusCode}');
    } catch (e) {
      debugPrint(
        '⚠️ RecommendationService: erreur réseau ($e), tentative cache offline',
      );
      final cached = await _cacheService.getCachedRecommendations();
      return cached ?? [];
    }
  }
}
