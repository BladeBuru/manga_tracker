import 'package:local_auth/local_auth.dart';

class BiometricService {
  final _auth = LocalAuthentication();

  Future<bool> hasBiometricSupport() async {
    return await _auth.canCheckBiometrics;
  }

  Future<List<BiometricType>> getAvailableBiometrics() async {
    return await _auth.getAvailableBiometrics();
  }

  Future<bool> authenticateWithBiometrics() async {
    try {
      bool isAuthenticated = await _auth.authenticate(
        localizedReason: 'Veuillez vous authentifier pour accéder à MangaTracker',
        options: const AuthenticationOptions(
          biometricOnly: true,
          stickyAuth: true,
        ),
      );
      return isAuthenticated;
    } catch (e) {
      print('Erreur biométrique : $e');
      return false;
    }
  }

}
