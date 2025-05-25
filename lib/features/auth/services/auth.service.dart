import 'dart:convert';
import 'dart:io';

import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:http/http.dart' as http;
import 'package:mangatracker/core/service_locator/service_locator.dart';
import 'package:mangatracker/features/auth/exceptions/invalid_credentials.exception.dart';

import '../../../core/storage/services/storage.service.dart';
import 'biometric.service.dart';

class AuthService {
  StorageService storageService = getIt<StorageService>();
  BiometricService biometricService = getIt<BiometricService>();

  Future<AuthService> init() async {
    return this;
  }

  Future attemptLogIn(String emailAddress, String password) async {
    var url = Uri.https(dotenv.env['MT_API_URL']!, '/auth/login');
    var res = await http.post(url,
        body: <String, String>{'email': emailAddress, 'password': password});

    switch (res.statusCode) {
      case HttpStatus.created:
        var data = jsonDecode(res.body);
        await storageService.writeSecureData('accessToken', data['accessToken']);
        await storageService.writeSecureData('refreshToken', data['refreshToken']);
        await saveCredentialsWithBiometric(emailAddress, password);
        return data;
      case HttpStatus.notFound:
        throw InvalidCredentialsException(
            'Invalid Credentials ${res.statusCode}');
      default:
        throw Exception('Unknown Error ${res.statusCode}');
    }
  }

  Future attemptSignUp(String username, String emailAddress, String password) async {
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

    try {
      Map<String, dynamic> payloadMap = parseJwt(token, 1);
      int exp = payloadMap['exp'];
      DateTime expDateTime =
      DateTime.fromMillisecondsSinceEpoch(exp * 1000, isUtc: true);
      return expDateTime.isBefore(DateTime.now().toUtc());
    } catch (e) {
      return true;
    }
  }


  Map<String, dynamic> parseJwt(String token, int part) {
    String base64Url = token.split('.')[part];
    String payload = _decodeBase64(base64Url);
    Map<String, dynamic> payloadMap = json.decode(payload);
    return payloadMap;
  }

  Future<bool> refreshAccessToken({String? token}) async {
    final refreshToken = token ?? await storageService.readSecureData('refreshToken');
    if (refreshToken == null || isTokenExpired(refreshToken)) {
      return false;
    }

    final url = Uri.https(dotenv.env['MT_API_URL']!, '/auth/refresh');
    final res = await http.post(url, headers: {
      HttpHeaders.authorizationHeader: 'Bearer $refreshToken',
    });

    if (res.statusCode == HttpStatus.created) {
      final data = jsonDecode(res.body);
      await storageService.writeSecureData('accessToken', data['accessToken']);
      return true;
    }

    return false;
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
    // storageService.deleteSecureData('secure_credentials'); //suprimer les identifiants biométriques

  }

  Future<void> saveCredentialsWithBiometric(String email, String password) async {
    final credentials = jsonEncode({'email': email, 'password': password});
    await storageService.writeSecureDataBiometric('secure_credentials', credentials);
  }


  Future<bool> tryBiometricLogin() async {
    final hasCreds = await storageService.hasBiometricCredentials();
    if (!hasCreds) return false;

    final isAvailable = await biometricService.hasBiometricSupport();
    if (!isAvailable) return false;

    final authenticated = await biometricService.authenticateWithBiometrics();
    if (!authenticated) return false;

    final jsonCreds = await storageService.readSecureDataBiometric('secure_credentials');
    if (jsonCreds == null) return false;

    final decoded = jsonDecode(jsonCreds);
    final email = decoded['email'];
    final password = decoded['password'];

    try {
      final result = await attemptLogIn(email, password);
      await storageService.writeSecureData('accessToken', result['accessToken']);
      await storageService.writeSecureData('refreshToken', result['refreshToken']);
      return true;
    } catch (e) {
      return false;
    }
  }


}
