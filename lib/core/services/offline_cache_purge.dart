import 'package:flutter/foundation.dart';
import 'package:mangatracker/core/services/offline_cache_service.dart';

/// Purge du cache local — **contrepartie indispensable** de l'assouplissement
/// de lecture décidé le 2026-08-31 (cf. `failure_classifier.dart`).
///
/// Depuis que le cache est servi même quand le serveur rejette la session, la
/// seule chose qui empêche l'utilisateur suivant d'un appareil partagé de lire
/// les données du précédent, c'est cette purge. Sans elle, l'assouplissement
/// serait une vraie fuite de données.
///
/// Deux déclencheurs, et deux seulement :
///  1. **déconnexion explicite** (`AuthService.logout()`) ;
///  2. **changement de compte** — connexion d'un autre utilisateur sans
///     déconnexion préalable, détectée via [OfflineCacheService.ownerIdKey].
///
/// ⚠️ L'invalidation **automatique** de session (401 intercepté par
/// `HttpService`, refresh rejeté au démarrage) ne doit surtout PAS purger :
/// c'est précisément le cas où l'on veut continuer à servir le cache. Elle
/// passe par `AuthService.clearSessionTokens()`.
extension OfflineCachePurge on OfflineCacheService {
  /// Efface **toutes** les clés de cache liées à l'utilisateur.
  ///
  /// Couvre les clés exactes ([OfflineCacheService.userScopedExactKeys]) et
  /// les familles à cardinalité variable
  /// ([OfflineCacheService.userScopedKeyPrefixes]) : un détail par manga
  /// consulté, une entrée par recherche, plus les caches tenus par d'autres
  /// services sous le préfixe `cached_` (stats, amis).
  ///
  /// Ne touche ni aux tokens (`accessToken` / `refreshToken`, effacés par
  /// `AuthService`), ni à `secure_credentials` : les identifiants biométriques
  /// survivent volontairement à une déconnexion, pour permettre de se
  /// reconnecter sans retaper son mot de passe.
  Future<void> purgeUserScopedCache() async {
    try {
      // 1. Clés exactes — énumérées, donc vérifiables une par une en test.
      for (final key in OfflineCacheService.userScopedExactKeys) {
        await storage.deleteSecureData(key);
      }

      // 2. Familles préfixées : on balaie le trousseau, car on ne sait pas
      //    quels muId ni quelles requêtes ont été mis en cache.
      final keys = await storage.secureKeys();
      for (final key in keys) {
        final scoped = OfflineCacheService.userScopedKeyPrefixes
            .any((prefix) => key.startsWith(prefix));
        if (scoped) await storage.deleteSecureData(key);
      }

      debugPrint('🧹 OfflineCache: cache utilisateur purgé');
    } catch (e) {
      // Une purge qui échoue ne doit pas bloquer la déconnexion : l'user doit
      // toujours pouvoir sortir. On trace, sans relancer.
      debugPrint('❌ OfflineCache: échec de la purge: $e');
    }
  }

  /// Déclare [userId] propriétaire du cache, en purgeant si le compte change.
  ///
  /// Appelée après chaque connexion réussie. Trois cas :
  ///  - **même utilisateur** (biométrie, reconnexion) → cache conservé, rien
  ///    à refetch inutilement ;
  ///  - **utilisateur différent** → purge, puis adoption ;
  ///  - **propriétaire inconnu** (cache d'avant cette version, ou identité
  ///    illisible) → purge par défaut. Sur un appareil partagé, le doute doit
  ///    profiter à la confidentialité, pas au confort.
  Future<void> adoptCacheOwner(String? userId) async {
    try {
      final previous = await storage.readSecureData(
        OfflineCacheService.ownerIdKey,
      );

      if (userId == null || userId.isEmpty) {
        // Identité illisible : on ne peut pas garantir que c'est le même
        // utilisateur, donc on purge.
        debugPrint('🧹 OfflineCache: propriétaire inconnu → purge préventive');
        await purgeUserScopedCache();
        return;
      }

      if (previous == userId) return; // même compte, on garde le cache

      if (previous != null) {
        debugPrint('🧹 OfflineCache: changement de compte détecté → purge');
      }
      // `previous == null` : cache antérieur à ce marqueur, propriétaire
      // indéterminé → purge aussi, par prudence.
      await purgeUserScopedCache();
      await storage.writeSecureData(OfflineCacheService.ownerIdKey, userId);
    } catch (e) {
      debugPrint('❌ OfflineCache: échec adoptCacheOwner: $e');
    }
  }
}
