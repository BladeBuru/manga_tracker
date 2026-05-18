import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:http/http.dart';
import 'package:mangatracker/core/network/network_compat.dart';
import 'package:mangatracker/core/network/uri_builder.dart';
import 'package:mangatracker/core/service_locator/service_locator.dart';
import 'package:mangatracker/core/services/offline_cache_service.dart';
import 'package:mangatracker/features/auth/services/auth.service.dart';

import '../../../core/network/http_service.dart';
import '../../auth/exceptions/invalid_credentials.exception.dart';
import '../dto/user_information.dto.dart';

class UserService {
  final AuthService authService = getIt<AuthService>();
  final HttpService httpService = getIt<HttpService>();
  final OfflineCacheService _cacheService = getIt<OfflineCacheService>();

  Future<UserService> init() async {
    return this;
  }

  /// Récupère les informations utilisateur.
  ///
  /// Si [forceRefresh] est `true`, ignore le cache local et force un fetch
  /// réseau (utile après vérification d'email, changement de profil, etc.
  /// sinon on continue à servir un cache potentiellement obsolète pendant
  /// 7 jours et le badge « Vérifiez votre email » reste affiché).
  Future<UserInformationDto> getUserInformation({bool forceRefresh = false}) async {
    if (forceRefresh) {
      // Invalide le cache + ses metadata avant de rappeler le réseau, sinon
      // un fetch raté retomberait sur l'ancien cache.
      await invalidateUserInfoCache();
    }

    // Essayer d'abord depuis le cache (sauf en forceRefresh)
    final cachedInfo = forceRefresh
        ? null
        : await _cacheService.getCachedUserInformation();
    if (cachedInfo != null) {
      // Vérifier si le cache est expiré (plus de 7 jours pour les infos utilisateur)
      final isExpired = await _cacheService.isCacheExpiredFor('user_info', maxHours: 7 * 24);
      if (!isExpired) {
        // Essayer de charger depuis le réseau en arrière-plan pour mettre à jour le cache
        _refreshUserInformationFromNetwork();
        return cachedInfo;
      }
    }

    // Charger depuis le réseau
    try {
      Uri url = buildApiUri('/user/information');
      Response response = await httpService.getWithAuthTokens(url);
      Map<String, dynamic> data = jsonDecode(response.body);
      final userInfo = UserInformationDto.fromJson(data);

      // Mettre en cache
      await _cacheService.cacheUserInformation(userInfo);

      return userInfo;
    } catch (e) {
      // Si erreur réseau et qu'on a un cache (même expiré), l'utiliser
      if (cachedInfo != null) {
        debugPrint('Erreur réseau, utilisation du cache utilisateur: $e');
        return cachedInfo;
      }
      rethrow;
    }
  }

  /// Met à jour les informations utilisateur depuis le réseau en arrière-plan
  Future<void> _refreshUserInformationFromNetwork() async {
    try {
      Uri url = buildApiUri('/user/information');
      Response response = await httpService.getWithAuthTokens(url);
      Map<String, dynamic> data = jsonDecode(response.body);
      final userInfo = UserInformationDto.fromJson(data);
      
      // Mettre à jour le cache
      await _cacheService.cacheUserInformation(userInfo);
    } catch (e) {
      // Erreur silencieuse en arrière-plan
      debugPrint('Erreur lors de la mise à jour en arrière-plan des infos utilisateur: $e');
    }
  }

  Future deleteAccount() async {
    final response = await httpService.deleteWithAuthTokens(
      buildApiUri('/user/delete'),
      headers: {HttpHeaders.contentTypeHeader: 'application/json'},
    );

    if (response.statusCode == HttpStatus.ok) {
      return;
    } else if (response.statusCode == HttpStatus.forbidden) {
      throw InvalidCredentialsException(
        'Not authorized to access this resource',
      );
    } else {
      throw Exception(
        'HTTP Request failed with status: ${response.statusCode}.',
      );
    }
  }

  Future changePassword(password) async {
    final response = await httpService.putWithAuthTokens(
      buildApiUri('/user/password'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({'password': password}),
    );

    if (response.statusCode == HttpStatus.ok) {
      // Le mot de passe a changé mais les infos utilisateur restent les mêmes
      // Pas besoin d'invalider le cache
      return;
    } else if (response.statusCode == HttpStatus.forbidden) {
      throw InvalidCredentialsException(
        'Not authorized to access this resource',
      );
    } else {
      throw Exception(
        'HTTP Request failed with status: ${response.statusCode}.',
      );
    }
  }

  /// Invalide le cache des informations utilisateur (appelé après changement de mot de passe, etc.)
  Future<void> invalidateUserInfoCache() async {
    try {
      await _cacheService.storage.deleteSecureData('cached_user_info');
    } catch (e) {
      debugPrint('Erreur lors de l\'invalidation du cache utilisateur: $e');
    }
  }

  /// Met à jour les champs de profil étendu (Phase 3).
  ///
  /// Envoie un PATCH `/user/profile` avec uniquement les champs non-null
  /// du paramètre. Invalide le cache local après succès pour que le
  /// prochain `getUserInformation` reflète les changements.
  Future<UserInformationDto> updateProfile({
    String? displayName,
    String? bio,
    String? avatarUrl,
    String? dateOfBirth,
    String? gender,
    bool? isProfilePublic,
  }) async {
    // L'API valide `@Length(1, N)` sur les champs string → on n'envoie PAS
    // les chaînes vides (sinon 400 Bad Request "must be longer than 1
    // character"). Pour "vider" un champ côté serveur, il faudrait un
    // endpoint dédié — pas implémenté pour MVP.
    final body = <String, dynamic>{};
    if (displayName != null && displayName.isNotEmpty) {
      body['displayName'] = displayName;
    }
    if (bio != null && bio.isNotEmpty) body['bio'] = bio;
    if (avatarUrl != null && avatarUrl.isNotEmpty) {
      // **2026-05-18** : l'API accepte désormais data URLs ET URLs http(s)
      // (regex `update-profile.dto.ts` ligne 67). La colonne est `text`
      // (cap 200 000 chars) depuis la migration ChangeAvatarUrlToText.
      // → on relaie ce que la view a déjà validé via `_validAvatarUrl`.
      if (avatarUrl.startsWith('http://') ||
          avatarUrl.startsWith('https://') ||
          avatarUrl.startsWith('data:image/')) {
        body['avatarUrl'] = avatarUrl;
      } else {
        debugPrint(
          '[updateProfile] avatarUrl format invalide (ni http(s) ni data:image/): ${avatarUrl.substring(0, avatarUrl.length.clamp(0, 60))}…',
        );
      }
    }
    if (dateOfBirth != null && dateOfBirth.isNotEmpty) {
      body['dateOfBirth'] = dateOfBirth;
    }
    if (gender != null && gender.isNotEmpty) body['gender'] = gender;
    if (isProfilePublic != null) body['isProfilePublic'] = isProfilePublic;

    // Debug : trace exacte de ce qui part vers l'API pour identifier les
    // mismatches DTO (champs inconnus, formats, casing enum…).
    debugPrint('[updateProfile] PATCH /user/profile body=${jsonEncode(body)}');

    final response = await httpService.patchWithAuthTokens(
      buildApiUri('/user/profile'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode(body),
    );

    if (response.statusCode != HttpStatus.ok) {
      // Trace le response body pour voir les violations class-validator
      // (avec enableDebugMessages côté NestJS, on récupère le détail).
      debugPrint(
        '[updateProfile] FAILED ${response.statusCode} body=${response.body}',
      );
      throw Exception(
        'Mise à jour du profil échouée : ${response.statusCode} ${response.body}',
      );
    }
    final updated = UserInformationDto.fromJson(
      jsonDecode(response.body) as Map<String, dynamic>,
    );
    await _cacheService.cacheUserInformation(updated);
    return updated;
  }
}
