import 'package:flutter/foundation.dart';
import 'package:mangatracker/core/service_locator/service_locator.dart';
import 'package:mangatracker/core/services/cache_helper_service.dart';
import 'package:mangatracker/features/reader/services/last_site_link_policy.dart';

/// Lit la bibliothèque **en cache local** (aucun appel réseau) et applique
/// [LastSiteLinkPolicy]. `null` si aucune œuvre n'a encore de lien.
class LastSiteLinkService {
  const LastSiteLinkService();

  Future<LastSiteLink?> suggestFor(num muId) async {
    try {
      final library = await getIt<CacheHelperService>().getCachedLibrary();
      if (library == null || library.isEmpty) return null;
      return const LastSiteLinkPolicy().pick(library, excludeMuId: muId);
    } catch (e) {
      debugPrint('LastSiteLinkService: bibliothèque en cache illisible ($e)');
      return null;
    }
  }
}
