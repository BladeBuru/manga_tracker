import 'dart:convert';

import 'package:mangatracker/core/network/http_service.dart';
import 'package:mangatracker/core/network/network_compat.dart';
import 'package:mangatracker/core/network/uri_builder.dart';
import 'package:mangatracker/core/service_locator/service_locator.dart';
import 'package:mangatracker/features/comments/dto/comment.dto.dart';

/// Service côté Flutter pour les commentaires (Phase 7).
///
/// Pas de cache local : les commentaires sont par nature très volatils
/// (poster, supprimer, éditer en temps réel) et l'usage attendu est
/// "j'ouvre la page détail manga, je scroll les comm". Un BLoC dédié
/// gérera la pagination + retry.
class CommentsService {
  final HttpService _http = getIt<HttpService>();

  Future<CommentsService> init() async => this;

  Future<CommentsPage> listForManga(
    int muId, {
    int page = 1,
    CommentSort sort = CommentSort.recent,
  }) async {
    final res = await _http.getWithAuthTokens(
      buildApiUri('/mangas/$muId/comments', {
        'page': page.toString(),
        'sort': sort.value,
      }),
    );
    if (res.statusCode != HttpStatus.ok) {
      throw Exception('listForManga failed: ${res.statusCode}');
    }
    return CommentsPage.fromJson(jsonDecode(res.body));
  }

  Future<List<CommentDto>> listReplies(int commentId) async {
    final res = await _http.getWithAuthTokens(
      buildApiUri('/mangas/comments/$commentId/replies'),
    );
    if (res.statusCode != HttpStatus.ok) {
      throw Exception('listReplies failed: ${res.statusCode}');
    }
    return (jsonDecode(res.body) as List<dynamic>)
        .map((e) => CommentDto.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  Future<CommentDto> create(
    int muId, {
    required String content,
    int? rating,
  }) async {
    final res = await _http.postWithAuthTokens(
      buildApiUri('/mangas/$muId/comments'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({
        'content': content,
        if (rating != null) 'rating': rating,
      }),
    );
    if (res.statusCode == HttpStatus.ok ||
        res.statusCode == HttpStatus.created) {
      return CommentDto.fromJson(jsonDecode(res.body));
    }
    throw Exception('create comment failed: ${res.statusCode} ${res.body}');
  }

  Future<CommentDto> reply(
    int commentId, {
    required String content,
    int? rating,
  }) async {
    final res = await _http.postWithAuthTokens(
      buildApiUri('/mangas/comments/$commentId/reply'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({
        'content': content,
        if (rating != null) 'rating': rating,
      }),
    );
    if (res.statusCode == HttpStatus.ok ||
        res.statusCode == HttpStatus.created) {
      return CommentDto.fromJson(jsonDecode(res.body));
    }
    throw Exception('reply failed: ${res.statusCode}');
  }

  Future<CommentDto> update(
    int commentId, {
    required String content,
    int? rating,
  }) async {
    final res = await _http.patchWithAuthTokens(
      buildApiUri('/mangas/comments/$commentId'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({
        'content': content,
        if (rating != null) 'rating': rating,
      }),
    );
    if (res.statusCode != HttpStatus.ok) {
      throw Exception('update comment failed: ${res.statusCode}');
    }
    return CommentDto.fromJson(jsonDecode(res.body));
  }

  Future<void> delete(int commentId) async {
    final res = await _http.deleteWithAuthTokens(
      buildApiUri('/mangas/comments/$commentId'),
    );
    if (res.statusCode != HttpStatus.ok) {
      throw Exception('delete comment failed: ${res.statusCode}');
    }
  }

  Future<void> report(int commentId, {String? reason}) async {
    final res = await _http.postWithAuthTokens(
      buildApiUri('/mangas/comments/$commentId/report'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({if (reason != null) 'reason': reason}),
    );
    if (res.statusCode != HttpStatus.ok) {
      throw Exception('report failed: ${res.statusCode}');
    }
  }
}
