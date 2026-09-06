import 'package:flutter/foundation.dart';
import 'package:mangatracker/core/service_locator/service_locator.dart';
import 'package:mangatracker/features/reader/dto/reading_position.dto.dart';
import 'package:mangatracker/features/reader/services/reading_position.service.dart';
import 'package:mangatracker/features/reader/services/reading_resume_policy.dart';
import 'package:mangatracker/features/reader/services/scroll_position_service.dart';

/// Rassemble les deux sources de position — l'appareil et le serveur — puis
/// laisse [ReadingResumePolicy] trancher.
///
/// Un service volontairement mince : il ne décide de rien, il **collecte**.
/// Toute la règle (« quel chapitre ouvrir, à quelle position, faut-il
/// demander ? ») vit dans la politique pure, testable sans réseau ni
/// `SharedPreferences`.
///
/// Ne lève jamais : si le serveur est injoignable, la reprise se fait sur la
/// seule mémoire locale ; si celle-ci est vide aussi, on retombe très
/// exactement sur le comportement d'avant — ouvrir `dernier lu + 1`.
class ReadingResumeService {
  ReadingResumeService({
    ScrollPositionService? scrollPositionService,
    ReadingPositionService? readingPositionService,
    ReadingResumePolicy policy = const ReadingResumePolicy(),
  })  : _scrollOverride = scrollPositionService,
        _remoteOverride = readingPositionService,
        _policy = policy;

  final ScrollPositionService? _scrollOverride;
  final ReadingPositionService? _remoteOverride;
  final ReadingResumePolicy _policy;

  ScrollPositionService get _scroll =>
      _scrollOverride ?? getIt<ScrollPositionService>();

  ReadingPositionService get _remote =>
      _remoteOverride ?? getIt<ReadingPositionService>();

  /// Décide ce que doit ouvrir le bouton « Lire en ligne » pour [muId].
  ///
  /// [lastReadChapter] : dernier chapitre TERMINÉ (au sens de
  /// `ChapterCommitPolicy`).
  Future<ReadingResumeDecision> resolve({
    required int muId,
    required int lastReadChapter,
  }) async {
    final local = await _readLocal(muId);
    final remote = await _readRemote(muId);
    return _policy.decide(
      lastReadChapter: lastReadChapter,
      local: local,
      remote: remote,
    );
  }

  /// Mémoire locale, complétée par une mesure encore en attente d'envoi :
  /// l'utilisateur qui ferme le lecteur hors ligne puis rouvre aussitôt ne
  /// doit pas dépendre de la réussite d'un aller-retour réseau.
  Future<ReadingPositionDto?> _readLocal(int muId) async {
    try {
      final stored = await _scroll.readLocalPosition(muId);
      final pending = _remote.pendingFor(muId);
      if (stored == null) return pending;
      if (pending == null) return stored;
      final storedAt = stored.updatedAt;
      return storedAt == null ? pending : stored;
    } catch (e) {
      debugPrint('ReadingResumeService: mémoire locale illisible ($e)');
      return null;
    }
  }

  Future<ReadingPositionDto?> _readRemote(int muId) async {
    try {
      return await _remote.fetchPosition(muId);
    } catch (e) {
      // `fetchPosition` avale déjà ses erreurs ; cette garde couvre le cas où
      // GetIt n'aurait pas encore le service (démarrage, tests de widget).
      debugPrint('ReadingResumeService: position distante indisponible ($e)');
      return null;
    }
  }
}
