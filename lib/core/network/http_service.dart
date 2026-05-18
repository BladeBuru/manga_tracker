import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:http/http.dart';
import 'package:mangatracker/core/network/network_compat.dart';
import 'package:mangatracker/features/auth/exceptions/invalid_credentials.exception.dart';
import 'package:mangatracker/features/auth/services/auth.service.dart';

import '../service_locator/service_locator.dart';
import '../storage/services/storage.service.dart';
import '../services/connectivity_service.dart';

class HttpService {
  final StorageService _storage = getIt<StorageService>();
  final AuthService _auth = getIt<AuthService>();

  Future<Response> _performRequest(
      String method,
      Uri url, {
        required Map<String, String> headers,
        Object? body,
      }) {
    switch (method) {
      case 'GET':
        return http.get(url, headers: headers);
      case 'POST':
        return http.post(url, headers: headers, body: body);
      case 'PUT':
        return http.put(url, headers: headers, body: body);
      case 'DELETE':
        return http.delete(url, headers: headers, body: body);
      case 'PATCH':
        return http.patch(url, headers: headers, body: body);
      default:
        throw UnsupportedError('Method $method is not supported');
    }
  }

  Future<Response> _requestWithAuthTokens(
      String method,
      Uri url, {
        Map<String, String>? headers,
        Object? body,
      }) async {
    headers = await _addAuthHeaders(headers);


    Response res = await _performRequest(
      method,
      url,
      headers: headers,
      body: body,
    );


    if (res.statusCode == HttpStatus.unauthorized) {
      debugPrint('⚠️ HttpService: Réponse 401, tentative de refresh...');

      final refreshToken = await _storage.readSecureData('refreshToken');
      if (refreshToken == null || _auth.isTokenExpired(refreshToken)) {
        debugPrint('❌ HttpService: Les deux tokens sont expirés');
        await _auth.logout(); // purge pour éviter de retenter au prochain boot
        throw InvalidCredentialsException('Both tokens expired');
      }

      final result = await _auth.refreshAccessToken();
      switch (result) {
        case RefreshResult.success:
          debugPrint('🔄 HttpService: Réessai de la requête avec le nouveau token...');
          headers = await _addAuthHeaders(null);
          res = await _performRequest(method, url, headers: headers, body: body);
          if (res.statusCode == HttpStatus.unauthorized) {
            debugPrint('❌ HttpService: Toujours 401 après refresh - credentials invalides');
            await _auth.logout();
            throw InvalidCredentialsException('Invalid credentials');
          }
          debugPrint('✅ HttpService: Requête réussie après refresh');
        case RefreshResult.networkError:
          // Pas une erreur d'auth — laisser le caller (BLoC) basculer en cache.
          debugPrint('⚠️ HttpService: Refresh impossible (réseau), propage SocketException');
          throw const SocketException('Refresh impossible (réseau)');
        case RefreshResult.rejected:
          // Le serveur a dit non : tokens morts, on purge et on force login.
          debugPrint('❌ HttpService: Refresh rejeté par le serveur, logout forcé');
          await _auth.logout();
          throw InvalidCredentialsException('Refresh rejected by server');
      }
    }

    return res;
  }

  Future<Map<String, String>> _addAuthHeaders(Map<String, String>? h) async {
    final headers = h == null ? <String, String>{} : Map.of(h);

    String? accessToken = await _storage.readSecureData('accessToken');
    String? refreshToken = await _storage.readSecureData('refreshToken');

    // Cas 1 : l'access token est encore valide → on l'utilise directement
    if (accessToken != null && !_auth.isTokenExpired(accessToken)) {
      headers[HttpHeaders.authorizationHeader] = 'Bearer $accessToken';
      return headers;
    }

    // Cas 2 : l'access token est expiré/absent → on tente un refresh
    debugPrint('🔄 HttpService: Access token expiré, tentative de refresh...');

    if (refreshToken == null || _auth.isTokenExpired(refreshToken)) {
      // Refresh token aussi expiré : vérifier si on est hors ligne avant de déconnecter
      try {
        final connectivityService = getIt<ConnectivityService>();
        if (!connectivityService.isConnected && accessToken != null) {
          // Hors ligne avec un ancien access token : on tente quand même (le serveur gérera le 401)
          debugPrint('📱 HttpService: Hors ligne, utilisation de l\'ancien accessToken');
          headers[HttpHeaders.authorizationHeader] = 'Bearer $accessToken';
          return headers;
        }
      } catch (_) {}
      debugPrint('❌ HttpService: Les deux tokens sont expirés');
      throw InvalidCredentialsException('Both tokens expired');
    }

    // Refresh token valide : vérifier la connectivité
    try {
      final connectivityService = getIt<ConnectivityService>();
      if (!connectivityService.isConnected) {
        if (accessToken != null) {
          debugPrint('📱 HttpService: Hors ligne, utilisation de l\'ancien accessToken');
          headers[HttpHeaders.authorizationHeader] = 'Bearer $accessToken';
          return headers;
        }
        throw InvalidCredentialsException('No connection and no access token');
      }
    } catch (e) {
      if (e is InvalidCredentialsException) rethrow;
      // ConnectivityService non disponible → on continue
    }

    final result = await _auth.refreshAccessToken();
    switch (result) {
      case RefreshResult.success:
        break; // continue ci-dessous pour relire le nouveau token
      case RefreshResult.networkError:
        // Le caller (BLoC) traitera ça comme un fallback cache.
        debugPrint('⚠️ HttpService: Refresh impossible (réseau)');
        throw const SocketException('Refresh impossible (réseau)');
      case RefreshResult.rejected:
        // Tokens morts côté serveur → purge locale et force login.
        debugPrint('❌ HttpService: Refresh rejeté par le serveur, logout forcé');
        await _auth.logout();
        throw InvalidCredentialsException('Refresh rejected by server');
    }

    accessToken = await _storage.readSecureData('accessToken');
    if (accessToken == null) {
      throw InvalidCredentialsException('Access token not available after refresh');
    }
    debugPrint('✅ HttpService: Access token rafraîchi avec succès');

    headers[HttpHeaders.authorizationHeader] = 'Bearer $accessToken';
    return headers;
  }

  // Méthodes publiques
  Future<Response> getWithAuthTokens(Uri url,
      {Map<String, String>? headers}) =>
      _requestWithAuthTokens('GET', url, headers: headers);

  Future<Response> postWithAuthTokens(Uri url,
      {Map<String, String>? headers, Object? body}) =>
      _requestWithAuthTokens('POST', url, headers: headers, body: body);

  Future<Response> putWithAuthTokens(Uri url,
      {Map<String, String>? headers, Object? body}) =>
      _requestWithAuthTokens('PUT', url, headers: headers, body: body);

  Future<Response> deleteWithAuthTokens(Uri url,
      {Map<String, String>? headers, Object? body}) =>
      _requestWithAuthTokens('DELETE', url, headers: headers, body: body);

  Future<Response> patchWithAuthTokens(Uri url,
      {Map<String, String>? headers, Object? body}) =>
      _requestWithAuthTokens('PATCH', url, headers: headers, body: body);
}
