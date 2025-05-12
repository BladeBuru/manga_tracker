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

  Future<Response> getWithAuthTokens(Uri url,
      {Map<String, String>? headers, Object? body}) async {
    headers = await _addAuthTokensHeaders(headers);
    return http.get(url, headers: headers);
  }

  Future<Response> deleteWithAuthTokens(
      Uri url, {
        Map<String, String>? headers,
        Object? body,
      }) async {
    headers = await _addAuthTokensHeaders(headers);
    return http.delete(
      url,
      headers: {
        HttpHeaders.contentTypeHeader: 'application/json',
        ...?headers,
      },
      body: body,
    );
  }

  Future<Response> postWithAuthTokens(Uri url,
      {Map<String, String>? headers, Object? body}) async {
    headers = await _addAuthTokensHeaders(headers);
    return http.post(url, body: body, headers: headers);
  }

  Future<Map<String, String>?> _addAuthTokensHeaders(
      Map<String, String>? headers) async {
    String? accessToken = await storageService.readSecureData('accessToken');
    String? refreshToken = await storageService.readSecureData('refreshToken');

    if (authService.isTokenExpired(refreshToken)) {
      throw InvalidCredentialsException(
          'Both AccessToken and refreshToken are invalid');
    }

    if (authService.isTokenExpired(accessToken)) {
      accessToken = await renewAccessToken(refreshToken!);
    }

    headers ??= {};
    headers.putIfAbsent(HttpHeaders.authorizationHeader,
        () => "Bearer ${accessToken.toString()}");
    return headers;
  }

  Future<String> renewAccessToken(String refreshToken) async {
    var url = Uri.https(dotenv.env['MT_API_URL']!, '/auth/refresh');
    var res = await http.post(url, headers: {
      HttpHeaders.authorizationHeader: "Bearer ${refreshToken.toString()}"
    });

    switch (res.statusCode) {
      case HttpStatus.created:
        return jsonDecode(res.body)['refreshToken'];
      case HttpStatus.notFound:
        throw InvalidCredentialsException(
            'Invalid Refresh Token ${res.statusCode}');
      default:
        throw Exception('Unknown Error ${res.statusCode}');
    }
  }
}
