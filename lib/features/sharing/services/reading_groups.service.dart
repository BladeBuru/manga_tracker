import 'dart:convert';

import 'package:mangatracker/core/network/http_service.dart';
import 'package:mangatracker/core/network/network_compat.dart';
import 'package:mangatracker/core/network/uri_builder.dart';
import 'package:mangatracker/core/service_locator/service_locator.dart';
import 'package:mangatracker/features/sharing/dto/reading_group.dto.dart';

/// Service "lecture à deux" — reading groups (Phase 8.3).
///
/// Pas de cache local pour MVP : la progression des autres membres change
/// de leur côté, on doit poll en temps quasi-réel (interval suggéré côté
/// front : 30s) pour rester à jour. Si charge réseau devient un souci,
/// passer à du WebSocket plus tard.
class ReadingGroupsService {
  final HttpService _http = getIt<HttpService>();

  Future<ReadingGroupsService> init() async => this;

  /// Crée un groupe sur un manga + invite optionnelle d'amis (max 10 total).
  Future<ReadingGroupDto> createGroup({
    required int muId,
    String? name,
    List<int>? inviteFriendIds,
  }) async {
    final res = await _http.postWithAuthTokens(
      buildApiUri('/reading-groups'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({
        'muId': muId,
        if (name != null) 'name': name,
        if (inviteFriendIds != null) 'inviteFriendIds': inviteFriendIds,
      }),
    );
    if (res.statusCode == HttpStatus.ok ||
        res.statusCode == HttpStatus.created) {
      return ReadingGroupDto.fromJson(jsonDecode(res.body));
    }
    throw Exception('createGroup failed: ${res.statusCode} ${res.body}');
  }

  /// Liste de mes groupes (peu importe si je suis owner ou membre simple).
  Future<List<ReadingGroupDto>> getMyGroups() async {
    final res = await _http.getWithAuthTokens(buildApiUri('/reading-groups'));
    if (res.statusCode != HttpStatus.ok) {
      throw Exception('getMyGroups failed: ${res.statusCode}');
    }
    return (jsonDecode(res.body) as List<dynamic>)
        .map((g) => ReadingGroupDto.fromJson(g as Map<String, dynamic>))
        .toList();
  }

  /// Détail d'un groupe + progression de chaque membre (à poll régulièrement
  /// côté UI pour la sync de "lecture à deux").
  Future<ReadingGroupDto> getGroup(int groupId) async {
    final res = await _http.getWithAuthTokens(
      buildApiUri('/reading-groups/$groupId'),
    );
    if (res.statusCode != HttpStatus.ok) {
      throw Exception('getGroup failed: ${res.statusCode}');
    }
    return ReadingGroupDto.fromJson(jsonDecode(res.body));
  }

  /// Invite un nouvel ami dans un groupe (owner uniquement, vérifié serveur).
  Future<ReadingGroupDto> invite(int groupId, int friendId) async {
    final res = await _http.postWithAuthTokens(
      buildApiUri('/reading-groups/$groupId/invite'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({'friendId': friendId}),
    );
    if (res.statusCode == HttpStatus.ok ||
        res.statusCode == HttpStatus.created) {
      return ReadingGroupDto.fromJson(jsonDecode(res.body));
    }
    throw Exception('invite failed: ${res.statusCode} ${res.body}');
  }

  /// Quitte le groupe. Si je suis owner ET qu'il reste d'autres membres,
  /// l'ownership est transféré au plus ancien restant côté serveur.
  /// Si je suis owner seul, le groupe est supprimé.
  Future<void> leave(int groupId) async {
    final res = await _http.deleteWithAuthTokens(
      buildApiUri('/reading-groups/$groupId/leave'),
    );
    if (res.statusCode != HttpStatus.ok) {
      throw Exception('leave failed: ${res.statusCode}');
    }
  }

  /// Supprime définitivement le groupe (owner uniquement, vérifié serveur).
  /// Différent de `leave` : ne transfère pas l'ownership — tue le groupe.
  Future<void> deleteGroup(int groupId) async {
    final res = await _http.deleteWithAuthTokens(
      buildApiUri('/reading-groups/$groupId'),
    );
    if (res.statusCode != HttpStatus.ok &&
        res.statusCode != HttpStatus.noContent) {
      throw Exception('deleteGroup failed: ${res.statusCode} ${res.body}');
    }
  }

  /// Cherche un groupe pour ce manga dans la liste de mes groupes. Retourne
  /// `null` s'il n'y en a pas. Côté server on a déjà `listMyGroups`, on
  /// filtre côté client pour éviter d'ajouter un endpoint dédié.
  Future<ReadingGroupDto?> findGroupForManga(int muId) async {
    final groups = await getMyGroups();
    for (final g in groups) {
      if (g.mangaMuId == muId.toString()) return g;
    }
    return null;
  }
}
