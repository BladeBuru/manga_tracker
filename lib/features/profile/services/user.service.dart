import 'dart:convert';
import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:http/http.dart';
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

  Future<UserInformationDto> getUserInformation() async {
    // Essayer d'abord depuis le cache
    final cachedInfo = await _cacheService.getCachedUserInformation();
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
}
