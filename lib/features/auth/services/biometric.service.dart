import 'package:flutter/cupertino.dart';
import 'package:flutter/services.dart';
import 'package:local_auth/local_auth.dart';

import '../../../core/notifier/notifier.dart';

class BiometricService {
  final _auth = LocalAuthentication();

  Future<bool> hasBiometricSupport() async {
    return await _auth.canCheckBiometrics;
  }

  Future<List<BiometricType>> getAvailableBiometrics() async {
    return await _auth.getAvailableBiometrics();
  }

  Future<bool> authenticateWithBiometrics(BuildContext context) async {
    try {
      bool isAuthenticated = await _auth.authenticate(
        localizedReason: 'Veuillez vous authentifier pour accéder à MangaTracker',
        options: const AuthenticationOptions(
          biometricOnly: true,
          stickyAuth: true,
        ),
      );
      return isAuthenticated;
    } on PlatformException catch (e) {
      // Gestion spécifique des blocages biométriques
      if (e.code == 'PermanentlyLockedOut' || e.message?.contains('ERROR_LOCKOUT') == true) {
        Notifier().error(
          context,
          'Trop de tentatives : veuillez déverrouiller votre téléphone avec votre code avant de réessayer.',
        );
      } else if (e.code == 'NotAvailable') {
        Notifier().info(
          context,
          'La biométrie n\'est pas disponible sur cet appareil.',
        );
      } else {
        Notifier().error(
          context,
          'Erreur biométrique : ${e.message ?? 'inconnue'}',
        );
      }
      return false;
    } catch (e) {
      Notifier().error(context, 'Erreur inattendue : $e');
      return false;
    }
  }
}


