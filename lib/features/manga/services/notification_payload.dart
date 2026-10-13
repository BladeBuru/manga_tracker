/// Contenu (« payload ») des notifications locales et écran ouvert quand on
/// les touche. Pur : ni Flutter, ni GetIt — testé seul.
///
/// | Notification          | Payload           | Écran ouvert              |
/// |-----------------------|-------------------|---------------------------|
/// | Demande d'ami         | `friend_request`  | Mes amis, onglet Demandes |
/// | Demande acceptée      | `friend:<userId>` | Profil de l'ami           |
/// | Recommandation reçue  | `share:<muId>`    | Recommandations reçues    |
/// | Lecture partagée      | `group:<groupId>` | Le groupe de lecture      |
/// | Nouveaux chapitres    | `<muId>`          | Fiche du titre            |
/// | Autre (centre)        | `notifications`   | Centre de notifications   |
///
/// Les anciennes notifications de partage portaient le seul `<muId>` : elles
/// ouvrent la fiche du titre, ce qui reste juste.
class NotificationPayload {
  static const String friendRequest = 'friend_request';
  static const String centre = 'notifications';
  static const String _sharePrefix = 'share:';
  static const String _friendPrefix = 'friend:';
  static const String _groupPrefix = 'group:';

  static String share(String muId) => '$_sharePrefix$muId';

  static String chapter(String muId) => muId;

  static String friend(String userId) => '$_friendPrefix$userId';

  static String readingGroup(String groupId) => '$_groupPrefix$groupId';

  /// Emplacement à ouvrir, ou `null` si le contenu n'est pas reconnu.
  static String? routeFor(String? payload) {
    final value = payload?.trim() ?? '';
    if (value.isEmpty) return null;
    if (value == friendRequest) return '/friends?tab=pending';
    if (value == centre) return '/notifications';
    if (value.startsWith(_sharePrefix)) return '/inbox';
    if (value.startsWith(_friendPrefix)) {
      final id = _positiveId(value.substring(_friendPrefix.length));
      return id == null ? '/friends' : '/friends/$id';
    }
    if (value.startsWith(_groupPrefix)) {
      final id = _positiveId(value.substring(_groupPrefix.length));
      return id == null ? '/reading-groups' : '/reading-groups/$id';
    }
    final muId = _positiveId(value);
    if (muId == null) return null;
    return '/manga/$muId';
  }

  static int? _positiveId(String raw) {
    final id = int.tryParse(raw.trim());
    return (id == null || id <= 0) ? null : id;
  }
}
