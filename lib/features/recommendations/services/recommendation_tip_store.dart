import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Mémoire locale des astuces d'usage des recommandations.
///
/// Une astuce ne doit apparaître **qu'une seule fois** : une aide qui revient
/// à chaque visite devient du bruit, et l'utilisateur apprend à l'ignorer —
/// exactement le sort qu'a connu le geste qu'elle est censée faire découvrir.
///
/// Volontairement **hors GetIt** : c'est une préférence d'affichage, sans
/// dépendance réseau ni ordre d'initialisation, et l'ajouter au service
/// locator pour un booléen n'apporterait qu'un risque (cf. l'écran blanc de
/// la v0.12.1, causé par un enregistrement mal ordonné). Même choix que
/// `NotificationPreferencesService`.
///
/// Le drapeau est **lié à l'appareil, pas au compte** : il n'est donc pas
/// purgé à la déconnexion, au même titre que la version de changelog déjà
/// vue. Il ne contient aucune donnée personnelle.
class RecommendationTipStore {
  /// Astuce « comment écarter un titre de mes recommandations ».
  static const String _dismissTipSeenKey = 'reco_dismiss_tip_seen';

  const RecommendationTipStore();

  /// `true` si l'astuce a déjà été montrée au moins une fois.
  ///
  /// En cas d'échec de lecture, renvoie `true` : mieux vaut ne pas montrer
  /// l'astuce que risquer de la remontrer en boucle à chaque ouverture.
  Future<bool> hasSeenDismissTip() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      return prefs.getBool(_dismissTipSeenKey) ?? false;
    } catch (e) {
      debugPrint('RecommendationTipStore: lecture impossible ($e)');
      return true;
    }
  }

  /// Range l'astuce définitivement. Idempotent, et silencieux en cas d'échec
  /// (au pire l'astuce réapparaîtra une fois de plus).
  Future<void> markDismissTipSeen() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool(_dismissTipSeenKey, true);
    } catch (e) {
      debugPrint('RecommendationTipStore: écriture impossible ($e)');
    }
  }
}
