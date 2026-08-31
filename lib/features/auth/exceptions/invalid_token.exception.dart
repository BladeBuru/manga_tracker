/// Token rejeté par le serveur (signature invalide, révoqué).
///
/// Même sémantique que `InvalidCredentialsException` : verdict serveur, donc
/// login obligatoire et pas de repli sur le cache.
class InvalidTokenException implements Exception {
  String cause;
  InvalidTokenException(this.cause);

  @override
  String toString() => 'InvalidTokenException: $cause';
}
