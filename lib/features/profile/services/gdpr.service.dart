import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:mangatracker/core/network/http_service.dart';
import 'package:mangatracker/core/network/uri_builder.dart';
import 'package:mangatracker/core/service_locator/service_locator.dart';

/// Service RGPD côté client.
///
/// Expose les opérations relevant du droit des données personnelles :
///  - Article 15 : droit d'accès (`getDataSummary`)
///  - Article 20 : droit à la portabilité (`exportData`)
///  - Consentement éclairé (`getConsentStatus`, `recordConsent`)
///
/// Aucune dépendance à `dart:io` (compatible Web). Utilise `HttpService`
/// pour la rotation JWT automatique.
class GdprService {
  static const _httpOk = 200;

  HttpService get _httpService => getIt<HttpService>();

  Future<GdprService> init() async => this;

  /// Article 15 — résumé des données détenues sur l'utilisateur.
  /// Retourne `null` si l'utilisateur n'est pas authentifié ou en cas d'erreur.
  Future<Map<String, dynamic>?> getDataSummary() async {
    try {
      final url = buildApiUri('/user/gdpr/summary');
      final response = await _httpService.getWithAuthTokens(url);
      if (response.statusCode != _httpOk) return null;
      return jsonDecode(response.body) as Map<String, dynamic>;
    } catch (e) {
      debugPrint('⚠️ GdprService.getDataSummary: $e');
      return null;
    }
  }

  /// Article 20 — récupère l'export complet des données utilisateur.
  ///
  /// Retourne le JSON brut. C'est au caller de le sauvegarder où il veut
  /// (téléchargement, partage, etc.). Pour Web : utiliser `Blob` + `download`.
  /// Pour mobile : `path_provider` + `share_plus` (à wirer côté UI).
  Future<String?> exportData() async {
    try {
      final url = buildApiUri('/user/gdpr/export');
      final response = await _httpService.getWithAuthTokens(url);
      if (response.statusCode != _httpOk) {
        debugPrint('⚠️ GdprService.exportData: HTTP ${response.statusCode}');
        return null;
      }
      return response.body;
    } catch (e) {
      debugPrint('⚠️ GdprService.exportData: $e');
      return null;
    }
  }

  /// Indique si l'utilisateur doit re-accepter les CGU/Privacy.
  /// Retourne null en cas d'erreur réseau (le caller doit considérer
  /// que tout est OK pour ne pas bloquer l'utilisation).
  Future<ConsentStatus?> getConsentStatus() async {
    try {
      final url = buildApiUri('/user/gdpr/consent-status');
      final response = await _httpService.getWithAuthTokens(url);
      if (response.statusCode != _httpOk) return null;
      final json = jsonDecode(response.body) as Map<String, dynamic>;
      return ConsentStatus.fromJson(json);
    } catch (e) {
      debugPrint('⚠️ GdprService.getConsentStatus: $e');
      return null;
    }
  }

  /// Enregistre l'acceptation des CGU + Politique de confidentialité.
  /// `tosVersion` et `privacyVersion` doivent provenir de
  /// `getConsentStatus()` (ne pas hardcoder côté client).
  Future<bool> recordConsent({
    required String tosVersion,
    required String privacyVersion,
  }) async {
    try {
      final url = buildApiUri('/user/gdpr/consent');
      final response = await _httpService.postWithAuthTokens(
        url,
        body: {
          'tosVersion': tosVersion,
          'privacyVersion': privacyVersion,
        },
      );
      return response.statusCode == _httpOk;
    } catch (e) {
      debugPrint('⚠️ GdprService.recordConsent: $e');
      return false;
    }
  }
}

/// Statut de consentement de l'utilisateur courant face aux versions
/// actuelles des documents légaux.
class ConsentStatus {
  final bool needsTosAcceptance;
  final bool needsPrivacyAcceptance;
  final String currentTosVersion;
  final String currentPrivacyVersion;

  const ConsentStatus({
    required this.needsTosAcceptance,
    required this.needsPrivacyAcceptance,
    required this.currentTosVersion,
    required this.currentPrivacyVersion,
  });

  bool get needsAnyAcceptance =>
      needsTosAcceptance || needsPrivacyAcceptance;

  factory ConsentStatus.fromJson(Map<String, dynamic> json) {
    return ConsentStatus(
      needsTosAcceptance: (json['needsTosAcceptance'] as bool?) ?? false,
      needsPrivacyAcceptance:
          (json['needsPrivacyAcceptance'] as bool?) ?? false,
      currentTosVersion: (json['currentTosVersion'] as String?) ?? '1.0',
      currentPrivacyVersion:
          (json['currentPrivacyVersion'] as String?) ?? '1.0',
    );
  }
}
