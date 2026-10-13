import 'dart:convert';

import 'package:http/http.dart';
import 'package:mangatracker/core/network/http_service.dart';
import 'package:mangatracker/core/network/network_compat.dart';
import 'package:mangatracker/core/network/uri_builder.dart';
import 'package:mangatracker/core/service_locator/service_locator.dart';
import 'package:mangatracker/core/services/offline_cache_service.dart';
import 'package:mangatracker/core/services/offline_queue_policy.dart';
import 'package:mangatracker/features/library/services/chapter_report.service.dart';
import 'package:mangatracker/features/library/services/offline_refusal_notice.dart';
import 'package:mangatracker/features/library/services/offline_write_queue.dart';
import 'package:mangatracker/features/manga/dto/reading_status.enum.dart';

/// Rejoue UNE modification faite hors ligne, telle quelle.
///
/// Différences voulues avec `LibraryService` : jamais de remise en file
/// (le rejeu passait par les méthodes publiques, qui ré-empilaient chaque
/// échec) et une décision par réponse serveur au lieu d'un booléen — c'est
/// ce qui permet d'abandonner ce que le serveur refusera toujours.
///
/// Une exception (réseau, session) remonte telle quelle : c'est
/// `SyncService` qui la classe.
///
/// Progression : un 406 (total connu dépassé) est rattrapé comme en ligne —
/// signalement puis un seul nouvel essai — quand l'utilisateur avait affirmé
/// sa lecture ([OfflineAction.confirmedByUser]). Une progression abandonnée
/// pour de bon est signalée à l'utilisateur ([onProgressRefused]) au lieu de
/// disparaître en silence.
class OfflineReplayService {
  final HttpService? _httpOverride;
  final ChapterReportService? _reportsOverride;
  final void Function(OfflineAction action) _onProgressRefused;

  OfflineReplayService({
    HttpService? http,
    ChapterReportService? reports,
    void Function(OfflineAction action)? onProgressRefused,
  }) : _httpOverride = http,
       _reportsOverride = reports,
       _onProgressRefused = onProgressRefused ?? notifyOfflineProgressRefused;

  HttpService get _http => _httpOverride ?? getIt<HttpService>();
  ChapterReportService get _reports =>
      _reportsOverride ?? getIt<ChapterReportService>();

  static const Map<String, String> _json = {
    HttpHeaders.contentTypeHeader: 'application/json',
  };

  Future<ReplayDecision> replay(OfflineAction action) async {
    final response = await _send(action);
    // Action incomplète ou d'un type inconnu : impossible à rejouer.
    if (response == null) return ReplayDecision.drop;
    final code = response.statusCode;
    // Déjà dans l'état voulu : c'est un succès (409, ou 400 « Manga already
    // saved » des API antérieures).
    if (action.type == 'addManga' &&
        isAlreadyInLibraryResponse(code, response.body)) {
      return ReplayDecision.done;
    }
    if (action.type == 'removeManga' && code == HttpStatus.notFound) {
      return ReplayDecision.done;
    }
    if (action.type == 'saveChapterProgress') {
      return _decideProgress(action, code);
    }
    return OfflineQueuePolicy.decide(code);
  }

  /// Progression : rattrapage du 406 si l'utilisateur avait affirmé sa
  /// lecture, et refus définitif signalé à l'utilisateur.
  Future<ReplayDecision> _decideProgress(OfflineAction action, int code) async {
    var decision = OfflineQueuePolicy.decide(code);
    if (code == HttpStatus.notAcceptable && action.confirmedByUser) {
      decision = await _reportThenRetry(action);
    }
    if (decision == ReplayDecision.drop) _onProgressRefused(action);
    return decision;
  }

  /// Signale le total lu puis rejoue le PUT **une seule fois** (même règle
  /// qu'en ligne). Une exception réseau remonte : `SyncService` gardera
  /// l'action pour plus tard.
  Future<ReplayDecision> _reportThenRetry(OfflineAction action) async {
    try {
      await _reports.reportMoreChapters(action.muId, action.readChapters!);
    } on ChapterReportException catch (e) {
      // Limite de requêtes ou panne : on retentera ; session : on attend la
      // reconnexion ; bornes / hors bibliothèque : définitif.
      if (e.failure == ChapterReportFailure.throttled) {
        return ReplayDecision.retryLater;
      }
      return e.failure == ChapterReportFailure.unknown
          ? OfflineQueuePolicy.decide(e.statusCode)
          : ReplayDecision.drop;
    }
    final retry = await _send(action);
    if (retry == null) return ReplayDecision.drop;
    return OfflineQueuePolicy.decide(retry.statusCode);
  }

  Future<Response?> _send(OfflineAction a) {
    final muId = a.muId;
    switch (a.type) {
      case 'addManga':
        return _http.postWithAuthTokens(
          buildApiUri('/library/save'),
          headers: _json,
          body: jsonEncode({'muId': muId}),
        );
      case 'removeManga':
        return _http.deleteWithAuthTokens(
          buildApiUri('/library/delete'),
          headers: _json,
          body: jsonEncode({'muId': muId}),
        );
      case 'saveChapterProgress':
        if (a.readChapters == null) return Future.value();
        return _http.putWithAuthTokens(
          buildApiUri('/library/chapter'),
          headers: _json,
          body: jsonEncode({'muId': muId, 'readChapters': a.readChapters}),
        );
      case 'updateStatus':
      case 'updateMangaStatus':
        if (a.status == null) return Future.value();
        return _http.putWithAuthTokens(
          buildApiUri('/library/status'),
          headers: _json,
          body: jsonEncode({'muId': muId, 'readingStatus': a.status!.value}),
        );
      case 'updateCustomLink':
        if (a.customLink == null) return Future.value();
        return _http.putWithAuthTokens(
          buildApiUri('/library/custom-link'),
          headers: _json,
          body: jsonEncode({'muId': muId, 'customLink': a.customLink}),
        );
      case 'deleteCustomLink':
        return _http.deleteWithAuthTokens(
          buildApiUri('/library/custom-link'),
          headers: _json,
          body: jsonEncode({'muId': muId}),
        );
      default:
        return Future.value();
    }
  }
}
