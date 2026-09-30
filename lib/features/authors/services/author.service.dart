import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:mangatracker/core/network/http_service.dart';
import 'package:mangatracker/core/network/network_compat.dart';
import 'package:mangatracker/core/network/uri_builder.dart';
import 'package:mangatracker/core/service_locator/service_locator.dart';
import 'package:mangatracker/features/authors/dto/author_details.dto.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Échec de chargement d'une fiche auteur.
enum AuthorFailure { notFound, unavailable }

class AuthorException implements Exception {
  final AuthorFailure failure;
  const AuthorException(this.failure);

  @override
  String toString() => 'AuthorException($failure)';
}

/// Fiches auteur. Données publiques (MangaUpdates) : la dernière réponse
/// est gardée sur l'appareil pour un affichage hors ligne — aucune donnée
/// personnelle, donc hors de la purge du cache utilisateur.
class AuthorService {
  static const _cachePrefix = 'cached_author_';

  final HttpService? _httpOverride;

  const AuthorService({HttpService? httpService}) : _httpOverride = httpService;

  HttpService get _http => _httpOverride ?? getIt<HttpService>();

  /// Fiche depuis l'API. Lève [AuthorException] sur 404 / 5xx ; une panne
  /// réseau remonte telle quelle (l'appelant bascule sur [cached]).
  Future<AuthorDetailsDto> fetch(int authorId) async {
    final response = await _http.getWithAuthTokens(
      buildApiUri('/authors/$authorId'),
    );
    if (response.statusCode == HttpStatus.notFound) {
      throw const AuthorException(AuthorFailure.notFound);
    }
    if (response.statusCode != HttpStatus.ok) {
      throw const AuthorException(AuthorFailure.unavailable);
    }
    final json = jsonDecode(response.body) as Map<String, dynamic>;
    _store(authorId, response.body);
    return AuthorDetailsDto.fromJson(json);
  }

  /// Dernière fiche connue sur l'appareil, `null` si jamais consultée.
  Future<AuthorDetailsDto?> cached(int authorId) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final raw = prefs.getString('$_cachePrefix$authorId');
      if (raw == null) return null;
      return AuthorDetailsDto.fromJson(jsonDecode(raw) as Map<String, dynamic>);
    } catch (e) {
      debugPrint('AuthorService: cache illisible pour $authorId ($e)');
      return null;
    }
  }

  Future<void> _store(int authorId, String body) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('$_cachePrefix$authorId', body);
    } catch (_) {
      // Cache d'agrément : un échec d'écriture ne gêne pas l'affichage.
    }
  }
}
