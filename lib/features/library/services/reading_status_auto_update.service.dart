import 'package:flutter/foundation.dart';
import 'package:mangatracker/core/service_locator/service_locator.dart';
import 'package:mangatracker/core/services/offline_cache_service.dart';
import 'package:mangatracker/features/library/services/library.service.dart';
import 'package:mangatracker/features/library/services/reading_status_auto_update_rule.dart';
import 'package:mangatracker/features/manga/dto/manga_quick_view.dto.dart';
import 'package:mangatracker/features/manga/dto/reading_status.enum.dart';

/// Applique côté application la bascule « à jour » → « en cours » quand la
/// détection d'un nouveau chapitre est **locale** (site de scan atteint via
/// le lien personnalisé, vérification en arrière-plan, drapeau
/// `hasNewChapters`). Ce cas est invisible pour l'API — qui, elle, gère la
/// bascule quand le total MangaUpdates augmente, y compris app fermée.
///
/// Pas d'enregistrement GetIt (ni `dependsOn`) : les dépendances sont
/// résolues à l'appel, l'ordre du service locator n'est pas touché.
class ReadingStatusAutoUpdateService {
  LibraryService get _library => getIt<LibraryService>();
  OfflineCacheService get _cache => getIt<OfflineCacheService>();

  /// Mangas dont la bascule a déjà été demandée (appliquée ou mise en file
  /// hors ligne) et pas encore confirmée par l'API. Évite les doublons
  /// d'appels réseau : chargement depuis le cache puis depuis le réseau,
  /// rechargements successifs, repli sur le cache après une panne.
  final Set<int> _requested = {};

  /// Réconcilie une liste de bibliothèque avec les chapitres détectés
  /// localement (`muId` → chapitres). Renvoie la liste enrichie :
  /// `hasNewChapters` à jour et statut basculé « en cours » là où la règle
  /// s'applique. L'appel réseau n'est fait **que** pour les entrées qui
  /// basculent, une fois chacune ; le cache hors ligne est mis à jour pour
  /// que la bascule survive à un rechargement sans réseau.
  Future<List<MangaQuickViewDto>> reconcileLibrary(
    List<MangaQuickViewDto> mangas,
    Map<int, List<int>> localNewChapters,
  ) async {
    var anyFlip = false;
    final result = <MangaQuickViewDto>[];
    for (final manga in mangas) {
      final muId = manga.muId.toInt();
      final chapters = localNewChapters[muId] ?? const <int>[];
      // L'API a confirmé (ou l'utilisateur a changé) le statut : une future
      // bascule doit pouvoir repartir de zéro.
      if (manga.readingStatus != ReadingStatus.caughtUp) {
        _requested.remove(muId);
      }
      final flip = ReadingStatusAutoUpdateRule.shouldFlipToReading(
        status: manga.readingStatus,
        readChapters: manga.readChapters,
        newChapters: chapters,
      );
      if (flip) {
        anyFlip = true;
        await _requestFlip(muId);
      }
      result.add(manga.copyWith(
        hasNewChapters: chapters.isNotEmpty,
        readingStatus: flip ? ReadingStatus.reading : manga.readingStatus,
      ));
    }
    if (anyFlip) await _cache.cacheLibrary(result);
    return result;
  }

  /// Détection ponctuelle d'un [chapter] (vérification en arrière-plan,
  /// fiche détail). Renvoie `true` si l'entrée est passée « en cours » ; le
  /// serveur est prévenu (ou l'action mise en file) et le cache patché.
  Future<bool> onNewChapterDetected({
    required int muId,
    required ReadingStatus? status,
    required num? readChapters,
    required int chapter,
  }) async {
    final flip = ReadingStatusAutoUpdateRule.shouldFlipToReading(
      status: status,
      readChapters: readChapters,
      newChapters: [chapter],
    );
    if (!flip) return false;
    await _requestFlip(muId);
    await _patchCachedStatus(muId, ReadingStatus.reading);
    return true;
  }

  /// Un seul appel de statut par manga tant que l'API n'a pas confirmé.
  /// Un succès **ou** une mise en file hors ligne mémorise la demande ; une
  /// erreur (session rejetée, HTTP) ne la mémorise pas → nouvelle tentative
  /// au prochain chargement.
  Future<bool> _requestFlip(int muId) async {
    if (_requested.contains(muId)) return false;
    try {
      final ok = await _library.updateMangaStatus(muId, ReadingStatus.reading);
      if (ok) _requested.add(muId);
      return ok;
    } catch (e) {
      debugPrint(
          'ReadingStatusAutoUpdateService: bascule refusée pour $muId ($e)');
      return false;
    }
  }

  Future<void> _patchCachedStatus(int muId, ReadingStatus status) async {
    final cached = await _cache.getCachedLibrary();
    if (cached == null) return;
    var changed = false;
    final patched = cached.map((manga) {
      if (manga.muId.toInt() != muId || manga.readingStatus == status) {
        return manga;
      }
      changed = true;
      return manga.copyWith(readingStatus: status);
    }).toList();
    if (changed) await _cache.cacheLibrary(patched);
  }
}
