import 'package:flutter/cupertino.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:local_auth/local_auth.dart';

import '../../../core/notifier/notifier.dart';

class BiometricService {
  final _auth = LocalAuthentication();

  Future<bool> hasBiometricSupport() async {
    try {
      final canCheck = await _auth.canCheckBiometrics;
      debugPrint('🔐 Biométrie Debug - canCheckBiometrics: $canCheck');
      
      // Pour certains appareils (ex: Huawei), canCheckBiometrics peut retourner false
      // mais getAvailableBiometrics peut quand même retourner des types disponibles
      if (!canCheck) {
        final available = await _auth.getAvailableBiometrics();
        debugPrint('🔐 Biométrie Debug - canCheckBiometrics=false mais getAvailableBiometrics: $available');
        
        // Si la liste n'est pas vide, on a des biométries disponibles
        if (available.isNotEmpty) {
          return true;
        }
        
        // Pour certains appareils Huawei, même si getAvailableBiometrics retourne [],
        // authenticate() peut quand même fonctionner (API propriétaire Huawei)
        // On retourne true pour permettre la tentative, authenticate() gérera l'erreur si nécessaire
        debugPrint('🔐 Biométrie Debug - Liste vide mais retour true pour compatibilité Huawei (authenticate() gérera l\'erreur)');
        return true;
      }
      
      return canCheck;
    } catch (e) {
      debugPrint('🔐 Biométrie Debug - Erreur dans hasBiometricSupport: $e');
      return false;
    }
  }

  Future<List<BiometricType>> getAvailableBiometrics() async {
    try {
      final available = await _auth.getAvailableBiometrics();
      debugPrint('🔐 Biométrie Debug - Types biométriques disponibles: $available');
      return available;
    } catch (e) {
      debugPrint('🔐 Biométrie Debug - Erreur dans getAvailableBiometrics: $e');
      return [];
    }
  }

  Future<bool> authenticateWithBiometrics(BuildContext context) async {
    try {
      debugPrint('🔐 Biométrie Debug - Début de l\'authentification biométrique');
      
      // Vérifier d'abord si des biométries sont disponibles
      final available = await getAvailableBiometrics();
      debugPrint('🔐 Biométrie Debug - Types disponibles avant authentification: $available');
      
      // Pour certains appareils (ex: Huawei), getAvailableBiometrics peut retourner []
      // mais authenticate() peut quand même fonctionner
      // On essaie donc d'authentifier même si la liste est vide
      if (available.isEmpty) {
        debugPrint('🔐 Biométrie Debug - Liste vide mais tentative d\'authentification quand même (compatibilité Huawei)');
      }
      
      debugPrint('🔐 Biométrie Debug - Appel de authenticate()...');
      
      bool isAuthenticated = await _auth.authenticate(
        localizedReason: 'Veuillez vous authentifier pour accéder à MangaTracker',
        options: const AuthenticationOptions(
          biometricOnly: true,
          stickyAuth: true,
        ),
      );
      
      debugPrint('🔐 Biométrie Debug - Résultat authentification: $isAuthenticated');
      return isAuthenticated;
    } on PlatformException catch (e) {
      debugPrint('🔐 Biométrie Debug - PlatformException: code=${e.code}, message=${e.message}, details=${e.details}');
      
      // Gestion spécifique des blocages biométriques
      if (e.code == 'PermanentlyLockedOut' || e.message?.contains('ERROR_LOCKOUT') == true) {
        debugPrint('🔐 Biométrie Debug - Biométrie verrouillée de façon permanente');
        Notifier().error(
          'Trop de tentatives : veuillez déverrouiller votre téléphone avec votre code avant de réessayer.',
        );
      } else if (e.code == 'NotAvailable') {
        debugPrint('🔐 Biométrie Debug - Biométrie non disponible (code: NotAvailable, message: ${e.message})');
        
        // Message spécifique pour "Security credentials not available"
        // Cela arrive souvent sur les appareils Huawei avec reconnaissance faciale propriétaire
        if (e.message?.contains('Security credentials not available') == true) {
          Notifier().info(
            'La reconnaissance faciale de votre appareil n\'est pas compatible avec l\'API Android standard. Veuillez utiliser un autre moyen d\'authentification.',
          );
        } else {
          Notifier().info(
            'La biométrie n\'est pas disponible sur cet appareil.',
          );
        }
      } else if (e.code == 'NotEnrolled') {
        debugPrint('🔐 Biométrie Debug - Aucune biométrie enregistrée (code: NotEnrolled)');
        Notifier().info(
          'Aucune méthode biométrique n\'est enregistrée sur cet appareil. Veuillez enregistrer une empreinte digitale ou une reconnaissance faciale dans les paramètres.',
        );
      } else {
        debugPrint('🔐 Biométrie Debug - Autre erreur biométrique: ${e.message ?? 'inconnue'}');
        Notifier().error(
          'Erreur biométrique : ${e.message ?? 'inconnue'}',
        );
      }
      return false;
    } catch (e, stackTrace) {
      debugPrint('🔐 Biométrie Debug - Erreur inattendue: $e');
      debugPrint('🔐 Biométrie Debug - Stack trace: $stackTrace');
      Notifier().error('Erreur inattendue : $e');
      return false;
    }
  }
}


