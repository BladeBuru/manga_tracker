import 'dart:convert';
import 'dart:io';

import 'package:flutter/cupertino.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:http/http.dart' as http;
import 'package:mangatracker/core/service_locator/service_locator.dart';
import 'package:mangatracker/features/auth/exceptions/invalid_credentials.exception.dart';
import 'package:shared_preferences/shared_preferences.dart';

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
        // Ne plus sauvegarder automatiquement les identifiants biométriques
        // La sauvegarde se fera uniquement si l'utilisateur active la biométrie
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
      debugPrint('⚠️ AuthService: Refresh token est null ou expiré');
      return false;
    }

    try {
      final url = Uri.https(dotenv.env['MT_API_URL']!, '/auth/refresh');
      final res = await http.post(url, headers: {
        HttpHeaders.authorizationHeader: 'Bearer $refreshToken',
      });

      if (res.statusCode == HttpStatus.created) {
        final data = jsonDecode(res.body);
        await storageService.writeSecureData('accessToken', data['accessToken']);
        
        // Si le backend renvoie un nouveau refreshToken (rotation), le sauvegarder
        if (data.containsKey('refreshToken') && data['refreshToken'] != null) {
          debugPrint('✅ AuthService: Nouveau refreshToken reçu, sauvegarde...');
          await storageService.writeSecureData('refreshToken', data['refreshToken']);
        }
        
        debugPrint('✅ AuthService: Access token rafraîchi avec succès');
        return true;
      } else {
        debugPrint('⚠️ AuthService: Échec du refresh - Status: ${res.statusCode}, Body: ${res.body}');
        return false;
      }
    } catch (e) {
      debugPrint('❌ AuthService: Erreur lors du refresh: $e');
      return false;
    }
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

  /// Vérifie si la biométrie est activée
  Future<bool> isBiometricEnabled() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool('biometric_auth_enabled') ?? false;
  }

  /// Vérifie si une préférence biométrique a déjà été définie
  Future<bool> hasBiometricPreference() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.containsKey('biometric_auth_enabled');
  }

  /// Active ou désactive la biométrie
  /// Si activation et que des identifiants sont disponibles, les sauvegarde
  /// Si désactivation, conserve les identifiants mais ne les utilise plus
  Future<void> setBiometricEnabled(bool enabled, {String? email, String? password}) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('biometric_auth_enabled', enabled);
    
    if (enabled) {
      // Si on active et qu'on a des identifiants, les sauvegarder
      if (email != null && password != null) {
        await saveCredentialsWithBiometric(email, password);
      } else {
        // Vérifier si des identifiants existent déjà
        final hasCreds = await storageService.hasBiometricCredentials();
        if (!hasCreds) {
          // Pas d'identifiants disponibles, l'utilisateur devra se reconnecter
          debugPrint('⚠️ AuthService: Activation biométrique sans identifiants disponibles');
        }
      }
    }
    // Si désactivation, on ne supprime pas les identifiants (pour réactivation future)
  }

  Future<bool> tryBiometricLogin(BuildContext context) async {
    // Vérifier d'abord si la biométrie est activée
    final isEnabled = await isBiometricEnabled();
    if (!isEnabled) return false;

    final hasCreds = await storageService.hasBiometricCredentials();
    if (!hasCreds) return false;

    final isAvailable = await biometricService.hasBiometricSupport();
    if (!isAvailable) return false;

    final authenticated = await biometricService.authenticateWithBiometrics(context);
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
