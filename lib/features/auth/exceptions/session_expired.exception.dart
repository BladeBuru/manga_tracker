/// Levée quand l'app n'a plus de credentials utilisables **mais que le serveur
/// n'a rendu aucun verdict** : les deux tokens sont expirés localement, ou le
/// refresh n'a pas pu partir faute de réseau.
///
/// ## Frontière de sécurité
///
/// Cette exception autorise la **lecture du cache local** (consultation hors
/// ligne de ce que l'utilisateur a déjà vu) et **rien d'autre** :
///
/// - lecture depuis le cache : **autorisée** (`isOffline: true` à l'écran) ;
/// - écriture / mutation serveur : **refusée** (mise en file d'attente hors
///   ligne, jamais appliquée en aveugle) ;
/// - un refresh est retenté dès que le réseau revient (`SyncService`).
///
/// À ne pas confondre avec `InvalidCredentialsException`, qui traduit un
/// verdict **explicite** du serveur (401/403 sur `/auth/refresh`, 403 sur une
/// ressource) : dans ce cas l'appareil est joignable — donc l'utilisateur peut
/// se reconnecter — la session est morte et le cache ne doit **pas** être
/// servi.
class SessionExpiredException implements Exception {
  final String cause;

  SessionExpiredException(this.cause);

  @override
  String toString() => 'SessionExpiredException: $cause';
}
