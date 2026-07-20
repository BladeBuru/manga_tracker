import 'dart:async';
import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:http/http.dart' as http;
import 'package:mangatracker/core/network/network_compat.dart';
import 'package:mangatracker/core/network/uri_builder.dart';
import 'package:mangatracker/features/auth/views/google_auth_js_helper_stub.dart'
    if (dart.library.html) 'package:mangatracker/features/auth/views/google_auth_js_helper_web.dart';
import 'package:mangatracker/features/auth/views/google_auth_webview.dart';
import 'package:mangatracker/core/service_locator/service_locator.dart';
import 'package:mangatracker/features/auth/exceptions/auth_server.exception.dart';
import 'package:mangatracker/features/auth/exceptions/email_already_used.exception.dart';
import 'package:mangatracker/features/auth/exceptions/invalid_credentials.exception.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../../core/storage/services/storage.service.dart';
import '../../../core/services/connectivity_service.dart';
import 'biometric.service.dart';

/// Résultat d'un appel à `refreshAccessToken()`.
///
/// On distingue trois cas pour permettre au caller (`startup_page`,
/// `http_service`) d'agir différemment :
///
/// - [success] : nouveau token reçu, l'user est authentifié.
/// - [networkError] : on n'a pas pu joindre le serveur (timeout, hors ligne,
///   SocketException). L'authentification est probablement encore valide,
///   l'user peut continuer en mode hors ligne (cache).
/// - [rejected] : le serveur a explicitement répondu 401/403/4xx — la
///   session est morte (purgée, JWT_REFRESH_SECRET changé, etc.). L'user
///   DOIT être renvoyé vers login, sinon il va naviguer dans le cache
///   avec l'illusion d'être connecté.
enum RefreshResult { success, networkError, rejected }

/// Résultat d'une tentative de connexion Google.
///
/// - [success] : tokens reçus et persistés, l'utilisateur est connecté.
/// - [cancelled] : l'utilisateur a fermé le sélecteur de compte — ce n'est
///   PAS une erreur, ne rien afficher.
/// - [configError] : le SDK Google refuse la configuration de l'app
///   (typiquement : OAuth client **Android** absent de la console GCP ou
///   SHA-1 de signature non déclaré). L'utilisateur ne peut rien y faire —
///   message dédié pour que les rapports de bug soient exploitables.
/// - [popupBlocked] : web uniquement — le navigateur a bloqué la popup
///   OAuth (window.open → null). Message dédié : autoriser les pop-ups.
/// - [failed] : toute autre erreur (réseau, backend, token invalide).
enum GoogleLoginResult { success, cancelled, configError, popupBlocked, failed }

class AuthService {
  StorageService storageService = getIt<StorageService>();
  BiometricService biometricService = getIt<BiometricService>();

  // Verrou pour éviter les race conditions lors du refresh
  bool _isRefreshing = false;
  Completer<RefreshResult>? _refreshCompleter;

  Future<AuthService> init() async {
    return this;
  }

  Future attemptLogIn(String emailAddress, String password) async {
    var url = buildApiUri('/auth/login');
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
    final url = buildApiUri('/auth/register');

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

  /// Rafraîchit le token d'accès en utilisant le refresh token.
  ///
  /// Retourne un [RefreshResult] qui permet au caller de distinguer :
  ///  - `success` : nouveau token reçu → user authentifié.
  ///  - `networkError` : pas pu joindre le serveur → mode hors ligne OK.
  ///  - `rejected` : le serveur a refusé (401/403) → session morte, login
  ///    obligatoire (sinon l'user navigue dans le cache en croyant être
  ///    connecté — c'est exactement le bug "j'ai relancé l'app, je suis
  ///    pas connecté mais je vois mes données").
  ///
  /// Compat : si tu as juste besoin d'un bool, utilise [refreshOk].
  Future<RefreshResult> refreshAccessToken({String? token}) async {
    // Si un refresh est déjà en cours, attendre son résultat
    if (_isRefreshing && _refreshCompleter != null) {
      debugPrint('🔄 AuthService: Refresh déjà en cours, attente du résultat...');
      return await _refreshCompleter!.future;
    }

    final refreshToken = token ?? await storageService.readSecureData('refreshToken');
    if (refreshToken == null || isTokenExpired(refreshToken)) {
      debugPrint('⚠️ AuthService: Refresh token est null ou expiré localement');
      // Le token est cassé côté client (pas reçu, ou expiré localement) → c'est
      // un "rejet" effectif : impossible de retenter, il faut se reconnecter.
      return RefreshResult.rejected;
    }

    // Vérifier la connectivité avant de tenter le refresh
    try {
      final connectivityService = getIt<ConnectivityService>();
      if (!connectivityService.isConnected) {
        debugPrint('⚠️ AuthService: Pas de connexion réseau, refresh impossible');
        return RefreshResult.networkError; // ≠ rejet : l'auth reste plausible
      }
    } catch (e) {
      debugPrint('⚠️ AuthService: Erreur lors de la vérification de connectivité: $e');
      // Continuer même si on ne peut pas vérifier la connectivité
    }

    // Créer un completer pour partager le résultat avec les autres appels simultanés
    _isRefreshing = true;
    _refreshCompleter = Completer<RefreshResult>();

    try {
      final url = buildApiUri('/auth/refresh');
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
        _refreshCompleter!.complete(RefreshResult.success);
        return RefreshResult.success;
      } else if (res.statusCode == HttpStatus.unauthorized ||
          res.statusCode == HttpStatus.forbidden) {
        // 401/403 = le serveur a explicitement rejeté le refresh token.
        // Causes typiques : session purgée (DB reset en dev), JWT_REFRESH_SECRET
        // changé côté serveur, ou refresh token signé par une autre instance API.
        // → il FAUT renvoyer l'user vers login, pas le laisser dans le cache.
        debugPrint('❌ AuthService: Refresh rejeté par le serveur (${res.statusCode}): ${res.body}');
        _refreshCompleter!.complete(RefreshResult.rejected);
        return RefreshResult.rejected;
      } else {
        // 5xx ou autre : on traite ça comme une erreur réseau temporaire,
        // l'user pourra retenter au prochain boot ou à la reconnexion.
        debugPrint('⚠️ AuthService: Échec du refresh (transitoire) - Status: ${res.statusCode}, Body: ${res.body}');
        _refreshCompleter!.complete(RefreshResult.networkError);
        return RefreshResult.networkError;
      }
    } on SocketException catch (e) {
      debugPrint('⚠️ AuthService: Erreur réseau lors du refresh: $e');
      _refreshCompleter!.complete(RefreshResult.networkError);
      return RefreshResult.networkError;
    } on TimeoutException catch (e) {
      debugPrint('⚠️ AuthService: Timeout lors du refresh: $e');
      _refreshCompleter!.complete(RefreshResult.networkError);
      return RefreshResult.networkError;
    } catch (e) {
      debugPrint('❌ AuthService: Erreur inattendue lors du refresh: $e');
      // Erreur inattendue : on prend l'option safe = rejet (force login).
      _refreshCompleter!.complete(RefreshResult.rejected);
      return RefreshResult.rejected;
    } finally {
      _isRefreshing = false;
      _refreshCompleter = null;
    }
  }

  /// Wrapper boolean conservé pour les call sites qui se moquent du détail
  /// (success / networkError → "ok globalement, on continue"; rejected →
  /// false = "force login"). Préférer [refreshAccessToken] pour les flows
  /// auth-critiques (startup, http interceptor).
  Future<bool> refreshOk({String? token}) async {
    final result = await refreshAccessToken(token: token);
    return result == RefreshResult.success;
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
    // Race condition fix : si l'user logout puis se reconnecte immédiatement,
    // les `deleteSecureData` non-awaités pouvaient s'exécuter APRÈS le nouveau
    // `writeSecureData` du login suivant → tokens du nouveau login effacés.
    await storageService.deleteSecureData('refreshToken');
    await storageService.deleteSecureData('accessToken');
    // Note : ne supprime pas `secure_credentials` (identifiants biométriques)
    // pour permettre la réactivation biométrique sans re-saisie.
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

      // Le context peut avoir été démonté entre deux tentatives (navigation).
      if (!context.mounted) return false;
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
        // attemptLogIn() persiste déjà les tokens (lignes 42-43). Réécrire ici
        // était redondant et créait une fenêtre de race si un logout ou un
        // autre flow auth se glissait entre les deux séries de writeSecureData.
        await attemptLogIn(email, password);
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


  /// Connexion via Google.
  ///
  /// - Sur **mobile** : utilise le package `google_sign_in` (popup natif Google)
  ///   → envoie l'idToken au backend `POST /auth/google/mobile`
  /// - Sur **web** : ouvre une popup via WebView + postMessage (flux OAuth existant)
  Future<GoogleLoginResult> loginWithGoogle(BuildContext context) async {
    if (!kIsWeb) {
      return _loginWithGoogleMobile();
    }
    return _loginWithGoogleWeb(context);
  }

  // Web Client ID = le même que le backend utilise pour vérifier l'idToken
  static const _googleWebClientId =
      '43781664315-4qruuj7eek7j71meh9ccl398r9k20a6k.apps.googleusercontent.com';

  Future<GoogleLoginResult> _loginWithGoogleMobile() async {
    try {
      // Initialise le SDK (idempotent si déjà initialisé)
      await GoogleSignIn.instance.initialize(serverClientId: _googleWebClientId);

      // Force le choix de compte Google
      await GoogleSignIn.instance.signOut();

      // Lance le popup natif Google
      final account = await GoogleSignIn.instance.authenticate();

      // En v7, authentication est un getter synchrone
      final idToken = account.authentication.idToken;
      if (idToken == null) {
        debugPrint('❌ AuthService: idToken Google null (serverClientId manquant ?)');
        return GoogleLoginResult.failed;
      }

      debugPrint('🔵 AuthService: idToken reçu, envoi au backend...');
      final url = buildApiUri('/auth/google/mobile');
      final res = await http
          .post(
            url,
            headers: {'Content-Type': 'application/json'},
            body: jsonEncode({
              'idToken': idToken,
              'deviceInfo': 'Flutter Mobile',
            }),
          )
          .timeout(const Duration(seconds: 15));

      if (res.statusCode == HttpStatus.created || res.statusCode == HttpStatus.ok) {
        final data = jsonDecode(res.body);
        await storageService.writeSecureData('accessToken', data['accessToken']);
        await storageService.writeSecureData('refreshToken', data['refreshToken']);
        debugPrint('✅ AuthService: Connexion Google mobile réussie');
        return GoogleLoginResult.success;
      } else {
        debugPrint('❌ AuthService: Erreur backend Google mobile - ${res.statusCode}: ${res.body}');
        return GoogleLoginResult.failed;
      }
    } on GoogleSignInException catch (e) {
      // Le code permet de distinguer les cas (visible via `adb logcat`) :
      //  - canceled → fermeture volontaire du sélecteur, pas une erreur ;
      //  - clientConfigurationError / providerConfigurationError → OAuth
      //    client Android absent ou SHA-1 non déclaré dans la console GCP.
      debugPrint(
          '⚠️ AuthService: GoogleSignInException code=${e.code.name} — ${e.description}');
      if (e.code == GoogleSignInExceptionCode.canceled) {
        return GoogleLoginResult.cancelled;
      }
      if (e.code == GoogleSignInExceptionCode.clientConfigurationError ||
          e.code == GoogleSignInExceptionCode.providerConfigurationError) {
        return GoogleLoginResult.configError;
      }
      return GoogleLoginResult.failed;
    } on Exception catch (e) {
      debugPrint('⚠️ AuthService: Connexion Google échouée: $e');
      return GoogleLoginResult.failed;
    }
  }

  Future<GoogleLoginResult> _loginWithGoogleWeb(BuildContext context) async {
    final oauthUrl = buildApiUri('/auth/google').toString();

    // window.open DOIT être appelé dans la section SYNCHRONE du handler de
    // tap (avant tout await / Navigator.push) : hors du geste utilisateur,
    // Brave/Safari bloquent silencieusement la popup et l'écran d'attente
    // pollait un postMessage qui ne pouvait jamais arriver (bug web 2026-07).
    final popupOpened = openGoogleOAuthPopup(oauthUrl);
    if (!popupOpened) {
      debugPrint('❌ AuthService: popup Google bloquée par le navigateur');
      return GoogleLoginResult.popupBlocked;
    }

    if (!context.mounted) return GoogleLoginResult.failed;

    final result = await Navigator.of(context).push<GoogleAuthResult>(
      MaterialPageRoute(
        fullscreenDialog: true,
        builder: (_) => GoogleAuthWebView(
          oauthUrl: oauthUrl,
          popupAlreadyOpened: true,
        ),
      ),
    );

    // Fermeture de la popup sans compléter le flux = annulation volontaire.
    if (result == null) return GoogleLoginResult.cancelled;

    await storageService.writeSecureData('accessToken', result.accessToken);
    await storageService.writeSecureData('refreshToken', result.refreshToken);
    debugPrint('✅ AuthService: Connexion Google web réussie');
    return GoogleLoginResult.success;
  }

  /// Persiste un couple `{accessToken, refreshToken}` reçu d'une voie
  /// alternative à `attemptLogIn` (vérification email, reset password
  /// confirmé, refresh côté serveur, etc.).
  ///
  /// **Sécurité** : à n'appeler QUE depuis un flow qui a déjà validé
  /// l'identité de l'utilisateur (token email vérifié, etc.). Les tokens
  /// sont stockés via `flutter_secure_storage` (Keystore Android,
  /// Keychain iOS, WebCrypto Web).
  Future<void> persistTokens({
    required String accessToken,
    required String refreshToken,
  }) async {
    await storageService.writeSecureData('accessToken', accessToken);
    if (refreshToken.isNotEmpty) {
      await storageService.writeSecureData('refreshToken', refreshToken);
    }
    debugPrint('✅ AuthService: Tokens persistés via persistTokens()');
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
