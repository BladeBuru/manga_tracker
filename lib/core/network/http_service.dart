import 'dart:convert';
import 'dart:io';

import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:http/http.dart' as http;
import 'package:http/http.dart';
import 'package:mangatracker/features/auth/exceptions/invalid_credentials.exception.dart';
import 'package:mangatracker/features/auth/services/auth.service.dart';

import '../service_locator/service_locator.dart';
import '../storage/services/storage.service.dart';

class HttpService {
  StorageService storageService = getIt<StorageService>();
  AuthService authService = getIt<AuthService>();

  Future<Response> _requestWithAuthTokens(
    String method,
    Uri url, {
    Map<String, String>? headers,
    Object? body,
  }) async {
    headers = await _addAuthTokensHeaders(headers);

    switch (method.toUpperCase()) {
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

  Future<Response> getWithAuthTokens(Uri url, {Map<String, String>? headers}) =>
      _requestWithAuthTokens('GET', url, headers: headers);

  Future<Response> postWithAuthTokens(
    Uri url, {
    Map<String, String>? headers,
    Object? body,
  }) => _requestWithAuthTokens('POST', url, headers: headers, body: body);

  Future<Response> putWithAuthTokens(
    Uri url, {
    Map<String, String>? headers,
    Object? body,
  }) => _requestWithAuthTokens('PUT', url, headers: headers, body: body);

  Future<Response> deleteWithAuthTokens(
    Uri url, {
    Map<String, String>? headers,
    Object? body,
  }) => _requestWithAuthTokens('DELETE', url, headers: headers, body: body);


  Future<Map<String, String>?> _addAuthTokensHeaders(
    Map<String, String>? headers,
  ) async {
    String? accessToken = await storageService.readSecureData('accessToken');
    String? refreshToken = await storageService.readSecureData('refreshToken');

    if (authService.isTokenExpired(refreshToken)) {
      throw InvalidCredentialsException(
        'Both AccessToken and refreshToken are invalid',
      );
    }

    if (authService.isTokenExpired(accessToken)) {
      accessToken = await renewAccessToken(refreshToken!);
    }

    headers ??= {};
    headers.putIfAbsent(
      HttpHeaders.authorizationHeader,
      () => "Bearer ${accessToken.toString()}",
    );
    return headers;
  }

  Future<String> renewAccessToken(String refreshToken) async {
    var url = Uri.https(dotenv.env['MT_API_URL']!, '/auth/refresh');
    var res = await http.post(
      url,
      headers: {
        HttpHeaders.authorizationHeader: "Bearer ${refreshToken.toString()}",
      },
    );

    switch (res.statusCode) {
      case HttpStatus.created:
        return jsonDecode(res.body)['refreshToken'];
      case HttpStatus.notFound:
        throw InvalidCredentialsException(
          'Invalid Refresh Token ${res.statusCode}',
        );
      default:
        throw Exception('Unknown Error ${res.statusCode}');
    }
  }
}
