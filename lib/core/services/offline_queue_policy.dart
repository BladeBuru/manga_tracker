import 'dart:math';

/// Règles de la file des modifications faites hors ligne. **Pure** : ni
/// Flutter, ni GetIt, ni stockage — testée seule
/// (`test/core/services/offline_queue_policy_test.dart`).
///
/// Problème corrigé (file à 112 actions, jamais vidée) :
/// - chaque chapitre lu ajoutait une progression ET un lien : la file ne
///   gardait que des états intermédiaires inutiles ;
/// - une action refusée pour de bon (titre retiré, total dépassé…) restait
///   à vie et était retentée à chaque synchronisation.
///
/// Désormais :
/// - **une seule** action par titre et par nature (progression, statut,
///   lien) : la plus récente remplace la précédente et passe en fin de file
///   (l'ordre des causes est respecté) ;
/// - ajouter puis retirer un titre qui n'a jamais atteint le serveur
///   s'annule ; retirer un titre efface ses autres actions en attente ;
/// - une action refusée par le serveur, trop souvent ratée ou trop vieille
///   est abandonnée.
class OfflineQueuePolicy {
  /// Au-delà, une action qui échoue encore est abandonnée.
  static const int maxAttempts = 8;

  /// Une modification plus vieille n'a plus de sens à rejouer.
  static const Duration maxAge = Duration(days: 30);

  static const String _id = 'id';
  static const String _attempts = 'attempts';

  static final Random _random = Random();

  /// Nature d'une action : deux actions de même nature sur un même titre
  /// se remplacent.
  static String? groupOf(String? type) => switch (type) {
    'saveChapterProgress' => 'progress',
    'updateStatus' || 'updateMangaStatus' => 'status',
    'updateCustomLink' || 'deleteCustomLink' => 'link',
    'addManga' || 'removeManga' => 'membership',
    _ => null,
  };

  /// File après ajout de [action], doublons fusionnés.
  static List<Map<String, dynamic>> enqueue(
    List<Map<String, dynamic>> queue,
    Map<String, dynamic> action,
  ) {
    final entry = _withIdentity(action);
    final muId = entry['muId'];
    final type = entry['type'] as String?;
    final group = groupOf(type);
    final result = List<Map<String, dynamic>>.of(queue);

    if (type == 'removeManga') {
      // Retirer un titre rend caduques ses autres modifications en attente.
      final hadPendingAdd = result.any(
        (e) => e['muId'] == muId && e['type'] == 'addManga',
      );
      result.removeWhere((e) => e['muId'] == muId);
      // Ajout jamais parvenu au serveur, puis retrait : il n'y a rien à faire.
      if (!hadPendingAdd) result.add(entry);
      return result;
    }
    if (type == 'addManga') {
      final alreadyQueued = result.any(
        (e) => e['muId'] == muId && e['type'] == 'addManga',
      );
      if (!alreadyQueued) result.add(entry);
      return result;
    }
    if (group != null) {
      result.removeWhere((e) => e['muId'] == muId && groupOf(e['type']) == group);
    }
    result.add(entry);
    return result;
  }

  /// Remet en ordre une file existante (fusion des doublons accumulés par les
  /// versions précédentes, identifiants manquants).
  static List<Map<String, dynamic>> normalize(
    List<Map<String, dynamic>> queue,
  ) {
    var result = <Map<String, dynamic>>[];
    for (final action in queue) {
      result = enqueue(result, action);
    }
    return result;
  }

  /// Action à abandonner sans la rejouer (trop d'échecs, trop vieille,
  /// illisible).
  static bool isExpired(Map<String, dynamic> entry, DateTime now) {
    final attempts = entry[_attempts];
    if (attempts is int && attempts >= maxAttempts) return true;
    final raw = entry['timestamp'];
    final at = raw is String ? DateTime.tryParse(raw) : null;
    if (at == null) return true;
    return now.difference(at) > maxAge;
  }

  /// Même action, une tentative de plus.
  static Map<String, dynamic> withFailedAttempt(Map<String, dynamic> entry) {
    final attempts = entry[_attempts];
    return {...entry, _attempts: (attempts is int ? attempts : 0) + 1};
  }

  static String? idOf(Map<String, dynamic> entry) => entry[_id] as String?;

  /// Suite à donner à la réponse du serveur pour une action rejouée.
  static ReplayDecision decide(int statusCode) {
    if (statusCode >= 200 && statusCode < 300) return ReplayDecision.done;
    if (statusCode == 401 || statusCode == 403) {
      return ReplayDecision.stopNeedsLogin;
    }
    if (statusCode == 408 || statusCode == 429 || statusCode >= 500) {
      return ReplayDecision.retryLater;
    }
    // 400, 404, 406, 409, 410, 422… : le serveur ne l'acceptera jamais.
    return ReplayDecision.drop;
  }

  static Map<String, dynamic> _withIdentity(Map<String, dynamic> action) {
    if (action[_id] is String) return action;
    final stamp = DateTime.now().microsecondsSinceEpoch;
    return {...action, _id: '$stamp-${_random.nextInt(1 << 32)}'};
  }
}

enum ReplayDecision {
  /// Appliquée : on la retire.
  done,

  /// Refusée pour de bon : on la retire (la rejouer ne changera rien).
  drop,

  /// Serveur ou réseau indisponible : on la garde pour plus tard.
  retryLater,

  /// Session refusée : on s'arrête, la file attend la reconnexion.
  stopNeedsLogin,
}
