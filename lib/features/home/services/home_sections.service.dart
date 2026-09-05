import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:http/http.dart' show Response;
import 'package:mangatracker/core/network/http_service.dart';
import 'package:mangatracker/core/network/network_compat.dart';
import 'package:mangatracker/core/network/uri_builder.dart';
import 'package:mangatracker/core/service_locator/service_locator.dart';
import 'package:mangatracker/core/storage/services/storage.service.dart';
import 'package:mangatracker/features/auth/exceptions/invalid_credentials.exception.dart';
import 'package:mangatracker/features/home/dto/home_section.dto.dart';

/// La section demandee n'existe pas (ou plus) cote serveur (404).
class HomeSectionNotFoundException implements Exception {
  final String sectionId;

  const HomeSectionNotFoundException(this.sectionId);

  @override
  String toString() => 'HomeSectionNotFoundException: $sectionId';
}

/// Sections de l'accueil « catalogue » (`/mangas/home/sections`).
///
/// - Lecture seule, JWT via [HttpService].
/// - La reponse complete est mise en cache sous [cacheKey] pour le mode hors
///   ligne : prefixe `cached_`, donc purgee a la deconnexion par
///   `purgeUserScopedCache()` sans rien ajouter a l'inventaire.
/// - Aucun `dart:io` (compatibilite web) ; les erreurs **remontent** : c'est
///   le BLoC qui classe l'echec (`classifyFailure`) et decide du repli.
///
/// Les dependances sont resolues depuis GetIt **a l'appel**, pas a la
/// construction, pour rester insensible a l'ordre du service locator (cf.
/// `RecommendationDismissalService` et la regression d'ecran blanc v0.12.1).
class HomeSectionsService {
  /// Cle de cache de la reponse complete (`HomeSectionsDto`).
  static const String cacheKey = 'cached_home_sections';

  /// Bornes du parametre `limit` acceptees par l'API.
  static const int minLimit = 5;
  static const int maxLimit = 40;

  /// Items par section sur l'accueil.
  static const int defaultLimit = 20;

  /// Items par page sur la page « Tout voir ».
  static const int pageLimit = 40;

  final HttpService? _httpOverride;
  final StorageService? _storageOverride;

  const HomeSectionsService({HttpService? httpService, StorageService? storage})
      : _httpOverride = httpService,
        _storageOverride = storage;

  HttpService get _http => _httpOverride ?? getIt<HttpService>();
  StorageService get _storage => _storageOverride ?? getIt<StorageService>();

  /// `GET /mangas/home/sections?limit=` — toutes les sections, dans l'ordre
  /// du serveur. Met la reponse en cache avant de la renvoyer.
  Future<HomeSectionsDto> fetchSections({int limit = defaultLimit}) async {
    final url = buildApiUri('/mangas/home/sections', {
      'limit': limit.clamp(minLimit, maxLimit).toString(),
    });
    final response = await _http.getWithAuthTokens(url);
    _ensureSuccess(response);
    final dto = HomeSectionsDto.fromJson(_decodeObject(response.body));
    await _writeCache(dto);
    return dto;
  }

  /// `GET /mangas/home/sections/:id?page=&limit=` — une page d'une section.
  ///
  /// Leve [HomeSectionNotFoundException] sur 404 (identifiant inconnu).
  Future<HomeSectionsPageDto> fetchSectionPage(
    String id, {
    int page = 1,
    int limit = pageLimit,
  }) async {
    final url = buildApiUri(
      '/mangas/home/sections/${Uri.encodeComponent(id)}',
      {
        'page': (page < 1 ? 1 : page).toString(),
        'limit': limit.clamp(minLimit, maxLimit).toString(),
      },
    );
    final response = await _http.getWithAuthTokens(url);
    if (response.statusCode == HttpStatus.notFound) {
      throw HomeSectionNotFoundException(id);
    }
    _ensureSuccess(response);
    return HomeSectionsPageDto.fromJson(_decodeObject(response.body));
  }

  /// Derniere reponse mise en cache, ou `null` si absente ou illisible.
  Future<HomeSectionsDto?> getCachedSections() async {
    try {
      final raw = await _storage.readSecureData(cacheKey);
      if (raw == null || raw.isEmpty) return null;
      final envelope = _decodeObject(raw);
      final data = envelope['data'];
      if (data is! Map<String, dynamic>) return null;
      return HomeSectionsDto.fromJson(data);
    } catch (e) {
      debugPrint('HomeSectionsService: cache illisible ($e)');
      return null;
    }
  }

  /// Ecriture silencieuse : un cache qui echoue ne doit pas casser l'accueil.
  Future<void> _writeCache(HomeSectionsDto dto) async {
    try {
      final envelope = {
        'cachedAt': DateTime.now().toIso8601String(),
        'data': dto.toJson(),
      };
      await _storage.writeSecureData(cacheKey, jsonEncode(envelope));
    } catch (e) {
      debugPrint('HomeSectionsService: echec ecriture cache ($e)');
    }
  }

  Map<String, dynamic> _decodeObject(String body) {
    final decoded = jsonDecode(body);
    if (decoded is Map<String, dynamic>) return decoded;
    throw const FormatException('Reponse JSON inattendue (objet attendu)');
  }

  void _ensureSuccess(Response response) {
    final status = response.statusCode;
    if (status == HttpStatus.ok || status == HttpStatus.created) return;
    if (status == HttpStatus.forbidden || status == HttpStatus.unauthorized) {
      throw InvalidCredentialsException(
        'Not authorized to access home sections',
      );
    }
    throw Exception('HTTP Request Failed with status: $status.');
  }
}
