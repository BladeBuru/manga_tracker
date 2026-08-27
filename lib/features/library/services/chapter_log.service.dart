import 'dart:convert';

import 'package:mangatracker/core/network/http_service.dart';
import 'package:mangatracker/core/network/network_compat.dart';
import 'package:mangatracker/core/network/uri_builder.dart';
import 'package:mangatracker/core/service_locator/service_locator.dart';
import 'package:mangatracker/features/library/dto/chapter_log.dto.dart';

/// Journal additif des chapitres (Phase 5 / Stats v2).
///
/// Extrait de [LibraryService] : le journal est **additif** et n'écrit
/// jamais le pointeur de progression `userReadChapters` (RETRO-015). Les
/// deux responsabilités sont distinctes, d'où deux services distincts.
///
/// Pas de queue offline : le log enrichit les statistiques, pas la
/// progression — si la requête échoue, l'utilisateur perd une entrée
/// d'historique, jamais son avancement.
class ChapterLogService {
  final HttpService _http;

  ChapterLogService({HttpService? httpService})
      : _http = httpService ?? getIt<HttpService>();

  /// Enregistre une session de lecture (insertion additive — replays OK).
  Future<ChapterLogDto> recordChapterLog(
    int muId, {
    required num chapterNumber,
    bool isBonus = false,
    int? scrollPosition,
  }) async {
    final body = <String, dynamic>{
      'chapterNumber': chapterNumber,
      'isBonus': isBonus,
      if (scrollPosition != null) 'scrollPosition': scrollPosition,
    };
    final res = await _http.postWithAuthTokens(
      buildApiUri('/library/$muId/chapter-log'),
      headers: {HttpHeaders.contentTypeHeader: 'application/json'},
      body: jsonEncode(body),
    );
    if (res.statusCode == HttpStatus.ok ||
        res.statusCode == HttpStatus.created) {
      return ChapterLogDto.fromJson(
        jsonDecode(res.body) as Map<String, dynamic>,
      );
    }
    throw Exception('recordChapterLog failed: ${res.statusCode}');
  }

  /// Toggle skip pour un chapitre (hors-série filler, etc.).
  Future<ChapterLogDto> toggleChapterSkip(
    int muId,
    num chapterNumber, {
    required bool skipped,
  }) async {
    final res = await _http.putWithAuthTokens(
      buildApiUri('/library/$muId/chapter/$chapterNumber/skip'),
      headers: {HttpHeaders.contentTypeHeader: 'application/json'},
      body: jsonEncode({'skipped': skipped}),
    );
    if (res.statusCode == HttpStatus.ok) {
      return ChapterLogDto.fromJson(
        jsonDecode(res.body) as Map<String, dynamic>,
      );
    }
    throw Exception('toggleChapterSkip failed: ${res.statusCode}');
  }

  /// Historique des sessions de lecture (replays, skips, bonus) pour un
  /// manga. Trié date décroissante côté serveur, max 500 entrées.
  Future<List<ChapterLogDto>> getChapterLog(int muId) async {
    final res = await _http.getWithAuthTokens(
      buildApiUri('/library/$muId/chapter-log'),
    );
    if (res.statusCode != HttpStatus.ok) {
      throw Exception('getChapterLog failed: ${res.statusCode}');
    }
    final list = jsonDecode(res.body) as List<dynamic>;
    return list
        .map((e) => ChapterLogDto.fromJson(e as Map<String, dynamic>))
        .toList();
  }
}
