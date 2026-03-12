import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:flutter/cupertino.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:http/http.dart' as http;
import 'package:mangatracker/core/service_locator/service_locator.dart';
import 'package:mangatracker/features/auth/exceptions/auth_server.exception.dart';
import 'package:mangatracker/features/auth/exceptions/email_already_used.exception.dart';
import 'package:mangatracker/features/auth/exceptions/invalid_credentials.exception.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../../core/storage/services/storage.service.dart';
import '../../../core/services/connectivity_service.dart';
import 'biometric.service.dart';

class AuthService {
  StorageService storageService = getIt<StorageService>();
  BiometricService biometricService = getIt<BiometricService>();
  
  // Verrou pour éviter les race conditions lors du refresh
  bool _isRefreshing = false;
  Completer<bool>? _refreshCompleter;

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

  Future<void> attemptSignUp(
    String username,
    String emailAddress,
    String password,
  ) async {
    final url = Uri.https(dotenv.env['MT_API_URL']!, 'auth/register');

    try {
      final res = await http
          .post(
            url,
            body: {
              'name': username,
              'email': emailAddress,
              'password': password,
            },
          )
          .timeout(const Duration(seconds: 15));

      switch (res.statusCode) {
        case HttpStatus.created:
        case HttpStatus.ok:
          return;
        case HttpStatus.conflict:
          throw EmailAlreadyUsedException();
        case HttpStatus.badRequest:
        case HttpStatus.unprocessableEntity:
          final message = _extractMessage(res.body);
          throw AuthServerException(res.statusCode, message);
        default:
          throw AuthServerException(
            res.statusCode,
            res.body.isNotEmpty ? _extractMessage(res.body) : null,
          );
      }
    } on SocketException {
      rethrow;
    } on TimeoutException {
      rethrow;
    }
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

  /// Rafraîchit le token d'accès en utilisant le refresh token
  /// Gère les race conditions et vérifie la connectivité
  Future<bool> refreshAccessToken({String? token}) async {
    // Si un refresh est déjà en cours, attendre son résultat
    if (_isRefreshing && _refreshCompleter != null) {
      debugPrint('🔄 AuthService: Refresh déjà en cours, attente du résultat...');
      return await _refreshCompleter!.future;
    }

    final refreshToken = token ?? await storageService.readSecureData('refreshToken');
    if (refreshToken == null || isTokenExpired(refreshToken)) {
      debugPrint('⚠️ AuthService: Refresh token est null ou expiré');
      return false;
    }

    // Vérifier la connectivité avant de tenter le refresh
    try {
      final connectivityService = getIt<ConnectivityService>();
      if (!connectivityService.isConnected) {
        debugPrint('⚠️ AuthService: Pas de connexion réseau, impossible de rafraîchir le token');
        return false; // Ne pas considérer comme une erreur d'authentification
      }
    } catch (e) {
      debugPrint('⚠️ AuthService: Erreur lors de la vérification de connectivité: $e');
      // Continuer même si on ne peut pas vérifier la connectivité
    }

    // Créer un completer pour partager le résultat avec les autres appels simultanés
    _isRefreshing = true;
    _refreshCompleter = Completer<bool>();

    try {
      final url = Uri.https(dotenv.env['MT_API_URL']!, '/auth/refresh');
      final res = await http.post(
        url,
        headers: {
          HttpHeaders.authorizationHeader: 'Bearer $refreshToken',
        },
      ).timeout(
        const Duration(seconds: 10),
        onTimeout: () {
          throw TimeoutException('Refresh token timeout');
        },
      );

      if (res.statusCode == HttpStatus.created) {
        final data = jsonDecode(res.body);
        await storageService.writeSecureData('accessToken', data['accessToken']);
        
        // Si le backend renvoie un nouveau refreshToken (rotation), le sauvegarder
        if (data.containsKey('refreshToken') && data['refreshToken'] != null) {
          debugPrint('✅ AuthService: Nouveau refreshToken reçu, sauvegarde...');
          await storageService.writeSecureData('refreshToken', data['refreshToken']);
        }
        
        debugPrint('✅ AuthService: Access token rafraîchi avec succès');
        _refreshCompleter!.complete(true);
        return true;
      } else {
        debugPrint('⚠️ AuthService: Échec du refresh - Status: ${res.statusCode}, Body: ${res.body}');
        _refreshCompleter!.complete(false);
        return false;
      }
    } on SocketException catch (e) {
      debugPrint('⚠️ AuthService: Erreur réseau lors du refresh: $e');
      _refreshCompleter!.complete(false);
      return false; // Erreur réseau, pas d'authentification
    } on TimeoutException catch (e) {
      debugPrint('⚠️ AuthService: Timeout lors du refresh: $e');
      _refreshCompleter!.complete(false);
      return false; // Timeout, pas d'authentification
    } catch (e) {
      debugPrint('❌ AuthService: Erreur lors du refresh: $e');
      _refreshCompleter!.complete(false);
      return false;
    } finally {
      _isRefreshing = false;
      _refreshCompleter = null;
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

  Future<void> logout() async {
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

  Future<bool> tryBiometricLogin(BuildContext context, {int maxRetries = 2}) async {
    debugPrint('🔐 AuthService Debug - Début tryBiometricLogin');
    
    // Vérifier d'abord si la biométrie est activée
    final isEnabled = await isBiometricEnabled();
    debugPrint('🔐 AuthService Debug - Biométrie activée: $isEnabled');
    if (!isEnabled) return false;

    final hasCreds = await storageService.hasBiometricCredentials();
    debugPrint('🔐 AuthService Debug - Identifiants biométriques présents: $hasCreds');
    if (!hasCreds) return false;

    final isAvailable = await biometricService.hasBiometricSupport();
    debugPrint('🔐 AuthService Debug - Support biométrique disponible: $isAvailable');
    if (!isAvailable) return false;

    final availableTypes = await biometricService.getAvailableBiometrics();
    debugPrint('🔐 AuthService Debug - Types biométriques disponibles: $availableTypes');

    final jsonCreds = await storageService.readSecureDataBiometric('secure_credentials');
    debugPrint('🔐 AuthService Debug - Identifiants récupérés: ${jsonCreds != null}');
    if (jsonCreds == null) return false;

    final decoded = jsonDecode(jsonCreds);
    final email = decoded['email'];
    final password = decoded['password'];

    for (var attempt = 0; attempt < maxRetries; attempt++) {
      debugPrint('🔐 AuthService Debug - Tentative ${attempt + 1}/$maxRetries');
      
      final authenticated = await biometricService.authenticateWithBiometrics(context);
      debugPrint('🔐 AuthService Debug - Authentification biométrique réussie: $authenticated');
      
      if (!authenticated) {
        // Si l'erreur est NotAvailable, pas besoin de réessayer
        // (cela signifie que la biométrie n'est vraiment pas disponible)
        final availableTypes = await biometricService.getAvailableBiometrics();
        if (availableTypes.isEmpty) {
          debugPrint('🔐 AuthService Debug - Aucune biométrie disponible, arrêt des tentatives');
          // Désactiver automatiquement la biométrie si elle n'est pas disponible
          await setBiometricEnabled(false);
          debugPrint('🔐 AuthService Debug - Biométrie désactivée automatiquement (non disponible)');
          return false;
        }
        
        if (attempt < maxRetries - 1) {
          debugPrint('🔐 AuthService Debug - Attente avant nouvelle tentative...');
          await Future<void>.delayed(const Duration(milliseconds: 600));
          continue;
        }
        debugPrint('🔐 AuthService Debug - Échec après $maxRetries tentatives');
        return false;
      }

      try {
        debugPrint('🔐 AuthService Debug - Tentative de connexion avec identifiants...');
        final result = await attemptLogIn(email, password);
        await storageService.writeSecureData('accessToken', result['accessToken']);
        await storageService.writeSecureData('refreshToken', result['refreshToken']);
        debugPrint('🔐 AuthService Debug - Connexion réussie !');
        return true;
      } catch (e) {
        debugPrint('🔐 AuthService Debug - Erreur lors de la connexion: $e');
        if (attempt < maxRetries - 1) {
          await Future<void>.delayed(const Duration(milliseconds: 600));
          continue;
        }
        return false;
      }
    }

    debugPrint('🔐 AuthService Debug - Échec final');
    return false;
  }


  String? _extractMessage(String body) {
    if (body.isEmpty) return null;
    try {
      final decoded = jsonDecode(body);
      if (decoded is Map<String, dynamic>) {
        if (decoded['message'] is String) {
          return decoded['message'] as String;
        }
        if (decoded['error'] is String) {
          return decoded['error'] as String;
        }
      }
    } catch (_) {
      return body;
    }
    return null;
  }
}
