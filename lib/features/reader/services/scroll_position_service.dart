import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter_inappwebview/flutter_inappwebview.dart';
import 'package:mangatracker/core/service_locator/service_locator.dart';
import 'package:mangatracker/features/reader/dto/reading_position.dto.dart';
import 'package:mangatracker/features/reader/services/reader_viewport_probe.dart';
import 'package:mangatracker/features/reader/services/reading_position.service.dart';
import 'package:mangatracker/features/reader/services/reading_position_store.dart';
import 'package:mangatracker/features/reader/utils/reading_position_calculator.dart';

/// Sauvegarde et restauration de la position de lecture dans les WebViews.
///
/// Trois écritures pour une seule mesure :
///  1. les **pixels** du chapitre courant (`scroll_position_<muId>_<ch>`),
///     seuls fidèles pour rouvrir le même chapitre sur le même appareil ;
///  2. le **marque-page local** (`reading_position_<muId>`), au format du
///     serveur, pour arbitrer avec un autre appareil ;
///  3. l'envoi au serveur via [ReadingPositionService], sous throttle.
///
/// Deux invariants, nés des défauts corrigés le 2026-09-06 (détail dans
/// `.claude/memory-bank/known-issues.md`, verrouillés par
/// `test/features/reader/scroll_position_service_test.dart`) :
///  - la position est écrite **quelle que soit la profondeur de lecture** ;
///    c'est la **suppression** de la position à la validation du chapitre —
///    pas un refus d'écriture — qui garantit qu'on ne rouvre jamais un
///    chapitre terminé en son milieu ;
///  - tout retour de WebView passe par [ReaderViewportProbe], parce qu'un
///    garde-fou qui lit une `Map` comme du texte est inerte sur Android.
class ScrollPositionService {
  ScrollPositionService({
    ReadingPositionService? positionService,
    ReaderViewportProbe probe = const ReaderViewportProbe(),
    ReadingPositionStore store = const ReadingPositionStore(),
  })  : _positionOverride = positionService,
        _probe = probe,
        _store = store;

  final ReadingPositionService? _positionOverride;
  final ReaderViewportProbe _probe;
  final ReadingPositionStore _store;

  ReadingPositionService get _remote =>
      _positionOverride ?? getIt<ReadingPositionService>();

  /// Tolérance de vérification après restauration, en pixels. En deçà, la
  /// position est considérée atteinte (arrondis de zoom, barre d'adresse
  /// escamotable).
  static const double _landingTolerancePx = 24;

  /// Au-delà, on considère que l'utilisateur a repris la main et on annule la
  /// restauration plutôt que de lui arracher la page.
  static const double _userScrollGuardPx = 100;

  Timer? _scrollSaveTimer;
  InAppWebViewController? _currentController;
  int? _currentMuId;
  int? _currentChapter;

  /// Suspend les écritures pendant une restauration : sans ce verrou, le tick
  /// périodique mesurait la page encore en haut et écrasait la position qu'on
  /// était justement en train de restaurer.
  bool _restoreInProgress = false;

  /// Mesure la position courante, l'écrit localement et la fait remonter au
  /// serveur. Rend le pourcentage mesuré, `null` si la page n'était pas
  /// mesurable (chargement en cours, document plus court que l'écran).
  ///
  /// [immediate] : force l'envoi serveur sans attendre la fenêtre de throttle
  /// — sortie du lecteur et passage en arrière-plan.
  Future<double?> saveScrollPosition(
    InAppWebViewController controller,
    int muId,
    int chapter, {
    bool immediate = false,
  }) async {
    if (_restoreInProgress) return null;
    try {
      final metrics = await _probe.measure(controller);
      if (metrics == null) return null;

      final percent = ReadingPositionCalculator.percentFromScroll(
        scrollY: metrics.scrollY,
        viewportHeight: metrics.viewportHeight,
        documentHeight: metrics.documentHeight,
      );
      if (percent == null || metrics.scrollY <= 0) return null;

      await _store.write(
        muId: muId,
        chapter: chapter,
        scrollY: metrics.scrollY,
        positionPercent: ReadingPositionCalculator.round(percent),
      );

      // Jamais bloquant : un serveur muet ne doit pas retarder une sortie.
      unawaited(_reportToServer(muId, chapter, percent, immediate: immediate));
      return percent;
    } catch (e) {
      debugPrint('ScrollPositionService: sauvegarde impossible ($e)');
      return null;
    }
  }

  Future<void> _reportToServer(int muId, int chapter, double percent,
      {required bool immediate}) async {
    try {
      await _remote.savePosition(muId, chapter, percent);
      if (immediate) await _remote.flush(muId);
    } catch (e) {
      debugPrint('ScrollPositionService: synchronisation différée ($e)');
    }
  }

  /// Mesure et remonte la position au serveur **sans rien écrire
  /// localement**.
  ///
  /// Pour le lecteur hors ligne : il mémorise déjà ses pixels dans le chapitre
  /// téléchargé et n'a besoin que de la part « inter-appareils », le
  /// pourcentage. Rend le pourcentage mesuré, `null` si la page n'est pas
  /// mesurable. Ne lève jamais.
  Future<double?> reportPositionOnly(
    InAppWebViewController controller,
    int muId,
    int chapter, {
    bool immediate = false,
  }) async {
    try {
      final metrics = await _probe.measure(controller);
      if (metrics == null || metrics.scrollY <= 0) return null;
      final percent = ReadingPositionCalculator.percentFromScroll(
        scrollY: metrics.scrollY,
        viewportHeight: metrics.viewportHeight,
        documentHeight: metrics.documentHeight,
      );
      if (percent == null) return null;
      await _reportToServer(muId, chapter, percent, immediate: immediate);
      return percent;
    } catch (e) {
      debugPrint('ScrollPositionService: mesure hors ligne impossible ($e)');
      return null;
    }
  }

  /// Restaure la position du chapitre courant.
  ///
  /// [fallbackPercent] : position venue du serveur (ou d'un autre appareil),
  /// utilisée seulement si cet appareil n'a rien mémorisé pour ce chapitre.
  /// Rend `true` si une position a été appliquée.
  Future<bool> restoreScrollPosition(
    InAppWebViewController controller,
    int muId,
    int chapter, {
    bool hasRestoredScroll = false,
    double? fallbackPercent,
  }) async {
    if (hasRestoredScroll) return false;

    try {
      final savedPixels = await _store.readScrollY(muId, chapter);
      final hasTarget =
          (savedPixels != null && savedPixels > 0) || fallbackPercent != null;

      if (!hasTarget) {
        // Nouveau chapitre : rien à restaurer, on laisse simplement les images
        // finir de charger avant de rendre la main.
        await _probe.waitForImages(controller);
        return false;
      }

      _restoreInProgress = true;
      try {
        return await _applyRestore(
          controller,
          savedPixels: savedPixels,
          fallbackPercent: fallbackPercent,
        );
      } finally {
        _restoreInProgress = false;
      }
    } catch (e) {
      debugPrint('ScrollPositionService: restauration impossible ($e)');
      _restoreInProgress = false;
      return false;
    }
  }

  /// Applique la position, puis **vérifie et retente**.
  ///
  /// Une seule passe ne suffit pas : les images d'un scan continuent de se
  /// charger après `onLoadStop`, le document s'allonge, et le `scrollTo` initial
  /// atterrit trop haut. On revérifie donc la position atteinte et on corrige,
  /// au lieu de constater l'échec sans rien tenter.
  Future<bool> _applyRestore(
    InAppWebViewController controller, {
    required double? savedPixels,
    required double? fallbackPercent,
  }) async {
    var applied = false;

    for (var attempt = 0; attempt < 3; attempt++) {
      await Future<void>.delayed(
          Duration(milliseconds: attempt == 0 ? 500 : 400));

      final metrics = await _probe.measure(controller);
      // Document pas encore exploitable : réessayer plutôt que viser à vide.
      if (metrics == null || !metrics.ready) continue;

      // L'utilisateur a repris la main : sa position prime sur la nôtre.
      if (!applied && metrics.scrollY > _userScrollGuardPx) return false;

      final maxScroll = metrics.maxScroll;
      if (maxScroll <= 0) continue;

      var target = savedPixels ??
          ReadingPositionCalculator.scrollOffsetFromPercent(
            percent: fallbackPercent,
            viewportHeight: metrics.viewportHeight,
            documentHeight: metrics.documentHeight,
          );
      if (target == null) continue;
      if (target > maxScroll) target = maxScroll;

      if (applied && (metrics.scrollY - target).abs() <= _landingTolerancePx) {
        return true; // déjà en place, le document ne bouge plus
      }

      await _probe.scrollTo(controller, target);
      applied = true;
    }
    return applied;
  }

  /// Démarre la sauvegarde périodique. L'intervalle par défaut suit le rythme
  /// de lecture ; l'envoi serveur, lui, reste sous le throttle de
  /// [ReadingPositionService].
  void startSaveTimer(
    InAppWebViewController controller,
    int muId,
    int chapter, {
    Duration interval = const Duration(seconds: 5),
  }) {
    stopSaveTimer();
    _currentController = controller;
    _currentMuId = muId;
    _currentChapter = chapter;

    _scrollSaveTimer = Timer.periodic(interval, (timer) {
      final activeController = _currentController;
      final activeMuId = _currentMuId;
      final activeChapter = _currentChapter;
      if (activeController == null ||
          activeMuId == null ||
          activeChapter == null) {
        timer.cancel();
        return;
      }
      unawaited(
        saveScrollPosition(activeController, activeMuId, activeChapter)
            .then((_) {}, onError: (Object e) {
          debugPrint('ScrollPositionService: tick ignoré ($e)');
        }),
      );
    });
  }

  void stopSaveTimer() {
    _scrollSaveTimer?.cancel();
    _scrollSaveTimer = null;
    _currentController = null;
    _currentMuId = null;
    _currentChapter = null;
  }

  /// Marque-page local du manga, au format du serveur — `null` si aucun.
  Future<ReadingPositionDto?> readLocalPosition(int muId) =>
      _store.readBookmark(muId);

  /// Efface la position d'un chapitre — **c'est ce qui garantit** qu'un
  /// chapitre validé comme terminé ne se rouvre jamais en son milieu, et non
  /// un refus d'écriture au-delà d'un seuil de défilement.
  ///
  /// Si le marque-page du manga désignait ce chapitre, la synchronisation
  /// serveur est coupée dans la foulée : sans ça, le tick suivant réenverrait
  /// une position au milieu d'un chapitre que le serveur vient de clore.
  Future<void> deleteScrollPosition(int muId, int chapterNumber) async {
    final wasCurrent = await _store.deleteChapter(muId, chapterNumber);
    if (wasCurrent) _remote.forget(muId);
  }

  /// Ne garde que la position du chapitre en cours pour ce manga.
  Future<void> cleanOldPositions(int muId, int currentChapter) =>
      _store.cleanOtherChapters(muId, currentChapter);

  void dispose() => stopSaveTimer();
}
