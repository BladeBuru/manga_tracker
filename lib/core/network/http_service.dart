import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:http/http.dart';
import 'package:mangatracker/features/auth/exceptions/invalid_credentials.exception.dart';
import 'package:mangatracker/features/auth/services/auth.service.dart';

import '../service_locator/service_locator.dart';
import '../storage/services/storage.service.dart';

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
        throw InvalidCredentialsException('Both tokens expired');
      }

      final refreshed = await _auth.refreshAccessToken();
      if (!refreshed) {
        debugPrint('❌ HttpService: Impossible de rafraîchir le access token');
        throw InvalidCredentialsException('Could not refresh access token');
      }

      debugPrint('🔄 HttpService: Réessai de la requête avec le nouveau token...');
      headers = await _addAuthHeaders(null);

      res = await _performRequest(
        method,
        url,
        headers: headers,
        body: body,
      );
      if (res.statusCode == HttpStatus.unauthorized) {
        debugPrint('❌ HttpService: Toujours 401 après refresh - credentials invalides');
        throw InvalidCredentialsException('Invalid credentials');
      }
      debugPrint('✅ HttpService: Requête réussie après refresh');
    }

    return res;
  }

  Future<Map<String, String>> _addAuthHeaders(Map<String, String>? h) async {
    final headers = h == null ? <String,String>{} : Map.of(h);


    String? accessToken = await _storage.readSecureData('accessToken');
    String? refreshToken = await _storage.readSecureData('refreshToken');

    if (refreshToken == null || _auth.isTokenExpired(refreshToken)) {
      debugPrint('⚠️ HttpService: Refresh token expiré ou absent');
      throw InvalidCredentialsException('Refresh token expired');
    }


    if (accessToken == null || _auth.isTokenExpired(accessToken)) {
      debugPrint('🔄 HttpService: Access token expiré, tentative de refresh...');
      final ok = await _auth.refreshAccessToken();
      if (!ok) {
        debugPrint('❌ HttpService: Échec du refresh du access token');
        throw InvalidCredentialsException('Could not refresh access token');
      }
      accessToken = await _storage.readSecureData('accessToken');
      if (accessToken == null) {
        debugPrint('❌ HttpService: Access token toujours null après refresh');
        throw InvalidCredentialsException('Access token not available after refresh');
      }
      debugPrint('✅ HttpService: Access token rafraîchi avec succès');
    }

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
}
