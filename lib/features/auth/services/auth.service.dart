import 'dart:convert';
import 'dart:io';

import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:http/http.dart' as http;
import 'package:mangatracker/core/service_locator/service_locator.dart';
import 'package:mangatracker/features/auth/exceptions/invalid_credentials.exception.dart';

import '../../../core/storage/services/storage.service.dart';

class AuthService {
  StorageService storageService = getIt<StorageService>();

  Future<AuthService> init() async {
    return this;
  }

  Future attemptLogIn(String emailAddress, String password) async {
    var url = Uri.https(dotenv.env['MT_API_URL']!, '/auth/login');
    var res = await http.post(url,
        body: <String, String>{'email': emailAddress, 'password': password});

    switch (res.statusCode) {
      case HttpStatus.created:
        return jsonDecode(res.body);
      case HttpStatus.notFound:
        throw InvalidCredentialsException(
            'Invalid Credentials ${res.statusCode}');
      default:
        throw Exception('Unknown Error ${res.statusCode}');
    }
  }

  Future attemptSignUp(
      String username, String emailAddress, String password) async {
    var url = Uri.https(dotenv.env['MT_API_URL']!, 'auth/register');
    var res = await http.post(url,
        body: {'name': username, 'email': emailAddress, 'password': password});
    return res.statusCode;
  }

  Future<bool> isUserAuthenticated() async {
    String? refreshToken = await storageService.readSecureData('refreshToken');
    return !isTokenExpired(refreshToken);
  }

  bool isTokenExpired(String? token) {
    if (token == null) {
      return true;
    }

    Map<String, dynamic> payloadMap = parseJwt(token, 1);
    int exp = payloadMap['exp'];
    DateTime expDateTime =
        DateTime.fromMillisecondsSinceEpoch(exp * 1000, isUtc: true);
    return expDateTime.isBefore(DateTime.now().toUtc());
  }

  Map<String, dynamic> parseJwt(String token, int part) {
    String base64Url = token.split('.')[part];
    String payload = _decodeBase64(base64Url);
    Map<String, dynamic> payloadMap = json.decode(payload);
    return payloadMap;
  }

  String _decodeBase64(String str) {
    String output = str.replaceAll('-', '+').replaceAll('_', '/');

    switch (output.length % 4) {
      case 0:
        break;
      case 2:
        output += '==';
        break;
      case 3:
        output += '=';
        break;
      default:
        throw Exception('Illegal base64url string! $str');
    }

    return utf8.decode(base64Url.decode(output));
  }

  logout() {
    storageService.deleteSecureData('refreshToken');
    storageService.deleteSecureData('accessToken');
  }
}
