import 'package:flutter/cupertino.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:local_auth/local_auth.dart';

import 'package:mangatracker/l10n/app_localizations.dart';
import '../../../core/notifier/notifier.dart';

class BiometricService {
  final _auth = LocalAuthentication();

  /// Déverrouillage possible sur cet appareil : biométrie **ou** code /
  /// schéma de l'appareil (secours proposé par la fenêtre système).
  ///
  /// Couvre les appareils sans services Google et les Huawei dont la
  /// reconnaissance faciale n'est pas exposée à Android : tant qu'un
  /// verrouillage d'écran existe, le déverrouillage fonctionne.
  Future<bool> hasBiometricSupport() async {
    try {
      if (await _auth.canCheckBiometrics) return true;
      return await _auth.isDeviceSupported();
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
      
      final l10n = AppLocalizations.of(context);
      // `biometricOnly: false` : si la biométrie n'est pas utilisable
      // (reconnaissance faciale Huawei non exposée à Android, capteur
      // absent, appareil sans services Google…), la fenêtre système propose
      // le code / schéma de l'appareil. Avant, `biometricOnly: true` laissait
      // ces appareils sans aucun moyen de déverrouiller.
      bool isAuthenticated = await _auth.authenticate(
        localizedReason:
            l10n?.biometricUnlockReason ?? 'Déverrouillez Manga Tracker',
        options: const AuthenticationOptions(
          biometricOnly: false,
          stickyAuth: true,
        ),
      );

      debugPrint('🔐 Biométrie Debug - Résultat authentification: $isAuthenticated');
      return isAuthenticated;
    } on PlatformException catch (e) {
      debugPrint('🔐 Biométrie Debug - PlatformException: code=${e.code}');
      final l10n = context.mounted ? AppLocalizations.of(context) : null;
      if (e.code == 'PermanentlyLockedOut' || e.code == 'LockedOut') {
        Notifier().error(l10n?.biometricLockedOut ??
            'Trop de tentatives : déverrouillez d\'abord votre appareil.');
      } else if (e.code == 'NotEnrolled' || e.code == 'PasscodeNotSet') {
        Notifier().info(l10n?.biometricNotEnrolled ??
            'Aucun verrouillage n\'est configuré sur cet appareil.');
      } else if (e.code == 'NotAvailable') {
        Notifier().info(l10n?.biometricAuthNotAvailable ??
            'L\'authentification biométrique n\'est pas disponible sur cet appareil');
      } else {
        Notifier().error(l10n?.biometricUnlockError ??
            'Déverrouillage impossible.');
      }
      return false;
    } catch (e, stackTrace) {
      debugPrint('🔐 Biométrie Debug - Erreur inattendue: $e');
      debugPrint('🔐 Biométrie Debug - Stack trace: $stackTrace');
      final l10n = context.mounted ? AppLocalizations.of(context) : null;
      Notifier().error(l10n?.biometricUnlockError ?? 'Déverrouillage impossible.');
      return false;
    }
  }
}


