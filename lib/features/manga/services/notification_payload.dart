/// Contenu (« payload ») des notifications locales et écran ouvert quand on
/// les touche. Pur : ni Flutter, ni GetIt — testé seul.
///
/// | Notification          | Payload           | Écran ouvert              |
/// |-----------------------|-------------------|---------------------------|
/// | Demande d'ami         | `friend_request`  | Mes amis, onglet Demandes |
/// | Recommandation reçue  | `share:<muId>`    | Recommandations reçues    |
/// | Nouveaux chapitres    | `<muId>`          | Fiche du titre            |
///
/// Les anciennes notifications de partage portaient le seul `<muId>` : elles
/// ouvrent la fiche du titre, ce qui reste juste.
class NotificationPayload {
  static const String friendRequest = 'friend_request';
  static const String _sharePrefix = 'share:';

  static String share(String muId) => '$_sharePrefix$muId';

  static String chapter(String muId) => muId;

  /// Emplacement à ouvrir, ou `null` si le contenu n'est pas reconnu.
  static String? routeFor(String? payload) {
    final value = payload?.trim() ?? '';
    if (value.isEmpty) return null;
    if (value == friendRequest) return '/friends?tab=pending';
    if (value.startsWith(_sharePrefix)) return '/inbox';
    final muId = int.tryParse(value);
    if (muId == null || muId <= 0) return null;
    return '/manga/$muId';
  }
}
