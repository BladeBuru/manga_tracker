/// Verdict **explicite** du serveur : la session est morte (401/403 sur
/// `/auth/refresh`, 403 sur une ressource) ou les identifiants de login sont
/// faux.
///
/// L'appareil est joignable, donc l'utilisateur peut se reconnecter : le cache
/// n'est **pas** servi sur cette erreur. Pour le cas « tokens expirés mais
/// serveur injoignable », voir `SessionExpiredException`.
class InvalidCredentialsException implements Exception {
  String cause;
  InvalidCredentialsException(this.cause);

  // `toString()` explicite : le défaut (`Instance of '...'`) est minifié par
  // dart2js en release web, ce qui cassait la détection par chaîne.
  @override
  String toString() => 'InvalidCredentialsException: $cause';
}
