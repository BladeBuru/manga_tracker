import 'dart:convert';

import 'package:http/http.dart';
import 'package:mangatracker/core/network/http_service.dart';
import 'package:mangatracker/core/network/network_compat.dart';
import 'package:mangatracker/core/network/uri_builder.dart';
import 'package:mangatracker/core/service_locator/service_locator.dart';
import 'package:mangatracker/core/services/offline_cache_service.dart';
import 'package:mangatracker/core/services/offline_queue_policy.dart';
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
class OfflineReplayService {
  final HttpService? _httpOverride;

  OfflineReplayService({HttpService? http}) : _httpOverride = http;

  HttpService get _http => _httpOverride ?? getIt<HttpService>();

  static const Map<String, String> _json = {
    HttpHeaders.contentTypeHeader: 'application/json',
  };

  Future<ReplayDecision> replay(OfflineAction action) async {
    final response = await _send(action);
    // Action incomplète ou d'un type inconnu : impossible à rejouer.
    if (response == null) return ReplayDecision.drop;
    final code = response.statusCode;
    // Déjà dans l'état voulu : c'est un succès.
    if (action.type == 'addManga' && code == HttpStatus.conflict) {
      return ReplayDecision.done;
    }
    if (action.type == 'removeManga' && code == HttpStatus.notFound) {
      return ReplayDecision.done;
    }
    return OfflineQueuePolicy.decide(code);
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
