import 'package:flutter/foundation.dart';
import 'package:mangatracker/core/service_locator/service_locator.dart';
import 'package:mangatracker/core/services/offline_cache_service.dart';
import 'package:mangatracker/features/manga/dto/manga_quick_view.dto.dart';

/// Index en memoire des `muId` deja presents dans la bibliotheque de
/// l'utilisateur, pour repondre « je l'ai deja » **sans aucun appel reseau**.
///
/// Source unique : le cache local `cached_library`, qui fait foi y compris
/// hors ligne. L'index n'interroge jamais l'API et ne connait rien du reseau.
///
/// Trois facons de le tenir a jour, dans l'ordre de fiabilite :
/// 1. [setFromLibrary] — le cache bibliotheque vient d'etre (re)ecrit, on
///    reprend la liste telle quelle (branche via
///    `OfflineCacheService.libraryCacheObserver`, cf. `setupServiceLocator`) ;
/// 2. [setOwned] — mise a jour optimiste au moment d'un ajout / retrait,
///    car le cache n'est pas encore reecrit a cet instant :
///    c'est ce qui fait que l'indicateur est juste des le retour sur
///    l'accueil apres un ajout depuis la fiche ;
/// 3. [ensureLoaded] / [refresh] — lecture du cache, au premier affichage.
///
/// [listenable] notifie les vues (cf. `LibraryOwnedIdsBuilder`) : aucun BLoC,
/// aucun etat duplique.
class LibraryIndexService {
  final OfflineCacheService? _cacheOverride;

  final ValueNotifier<Set<int>> _ownedMuIds =
      ValueNotifier<Set<int>>(const <int>{});

  bool _loaded = false;
  Future<void>? _inFlight;

  LibraryIndexService({OfflineCacheService? cache}) : _cacheOverride = cache;

  /// Resolu **a l'appel** : l'index est enregistre en fin de service locator
  /// et ne doit rien exiger de l'ordre d'enregistrement.
  OfflineCacheService get _cache =>
      _cacheOverride ?? getIt<OfflineCacheService>();

  /// Ensemble courant, toujours non modifiable.
  Set<int> get ownedMuIds => _ownedMuIds.value;

  /// A ecouter pour se reconstruire quand la bibliotheque change.
  ValueListenable<Set<int>> get listenable => _ownedMuIds;

  /// `true` si le titre est deja en bibliotheque d'apres l'index.
  bool contains(num muId) => _ownedMuIds.value.contains(muId.toInt());

  /// Charge l'index depuis le cache **une seule fois**. Les appels
  /// concurrents partagent la meme lecture.
  Future<void> ensureLoaded() {
    if (_loaded) return Future<void>.value();
    return _inFlight ??= _read().whenComplete(() => _inFlight = null);
  }

  /// Relit le cache maintenant, meme si l'index est deja charge.
  Future<void> refresh() {
    _loaded = false;
    return ensureLoaded();
  }

  Future<void> _read() async {
    try {
      final library = await _cache.getCachedLibrary();
      _emit(_idsOf(library ?? const <MangaQuickViewDto>[]));
    } catch (e) {
      // Un index indisponible ne doit jamais casser l'accueil : au pire,
      // aucun indicateur ne s'affiche.
      debugPrint('LibraryIndexService: cache bibliotheque illisible ($e)');
      _emit(const <int>{});
    }
    _loaded = true;
  }

  /// Le cache bibliotheque vient d'etre ecrit (`null` = invalide / purge).
  void setFromLibrary(List<MangaQuickViewDto>? library) {
    if (library == null) {
      clear();
      return;
    }
    _loaded = true;
    _emit(_idsOf(library));
  }

  /// Ajout ou retrait confirme : l'indicateur suit sans attendre la
  /// reecriture du cache bibliotheque.
  void setOwned(num muId, {required bool owned}) {
    final id = muId.toInt();
    if (_ownedMuIds.value.contains(id) == owned) return;
    final next = {..._ownedMuIds.value};
    if (owned) {
      next.add(id);
    } else {
      next.remove(id);
    }
    _emit(next);
  }

  /// Deconnexion / changement de compte : plus rien n'est connu, et la
  /// prochaine lecture repartira du cache du nouvel utilisateur.
  void clear() {
    _loaded = false;
    _emit(const <int>{});
  }

  void _emit(Set<int> ids) {
    if (setEquals(ids, _ownedMuIds.value)) return;
    _ownedMuIds.value = Set<int>.unmodifiable(ids);
  }

  static Set<int> _idsOf(List<MangaQuickViewDto> library) =>
      library.map((m) => m.muId.toInt()).toSet();
}
