import 'package:bloc/bloc.dart';
import 'package:equatable/equatable.dart';
import 'package:flutter/foundation.dart';
import 'package:mangatracker/core/network/failure_classifier.dart';
import 'package:mangatracker/features/manga/dto/community_recommendation.dto.dart';
import 'package:mangatracker/features/manga/services/community.service.dart';

part 'community_recommendations_state.dart';

/// Issue d'un vote, pour le message affiché par la vue.
enum CommunityVoteResult { added, removed, throttled, offline, failed }

/// Recommandations « si vous avez aimé ce titre… » d'une fiche : votes
/// MangaUpdates + Manga Tracker, et vote de l'utilisateur. Une instance par
/// feuille ouverte.
class CommunityRecommendationsCubit
    extends Cubit<CommunityRecommendationsState> {
  final CommunityService _service;
  final num sourceMuId;

  CommunityRecommendationsCubit({
    required this.sourceMuId,
    CommunityService? service,
  }) : _service = service ?? const CommunityService(),
       super(const CommunityRecommendationsState());

  Future<void> load() async {
    emit(state.copyWith(loading: true, failed: false));
    try {
      final items = await _service.getRecommendations(sourceMuId);
      if (isClosed) return;
      emit(state.copyWith(loading: false, items: items, isOffline: false));
    } catch (e) {
      debugPrint('CommunityRecommendations: chargement échoué ($e)');
      if (isClosed) return;
      emit(
        state.copyWith(
          loading: false,
          failed: true,
          isOffline: showsOfflineIndicator(classifyFailure(e)),
        ),
      );
    }
  }

  /// Recommande [target] (ou retire la recommandation si déjà donnée).
  Future<CommunityVoteResult> toggle(CommunityRecommendationDto target) =>
      _vote(target.muId, remove: target.recommendedByMe);

  /// Recommande une œuvre choisie par l'utilisateur (sélecteur).
  Future<CommunityVoteResult> recommend(num targetMuId) =>
      _vote(targetMuId, remove: false);

  Future<CommunityVoteResult> _vote(
    num targetMuId, {
    required bool remove,
  }) async {
    if (state.pending.contains(targetMuId)) return CommunityVoteResult.failed;
    emit(state.copyWith(pending: {...state.pending, targetMuId}));
    try {
      final updated =
          remove
              ? await _service.unrecommend(sourceMuId, targetMuId)
              : await _service.recommend(sourceMuId, targetMuId);
      final result =
          remove ? CommunityVoteResult.removed : CommunityVoteResult.added;
      // Feuille fermée pendant l'appel : le vote a bien abouti, on le dit
      // (seul l'état n'a plus personne à mettre à jour).
      if (isClosed) return result;
      emit(
        state.copyWith(
          items: _merge(state.items, updated),
          pending: {...state.pending}..remove(targetMuId),
        ),
      );
      return result;
    } catch (e) {
      if (!isClosed) {
        emit(state.copyWith(pending: {...state.pending}..remove(targetMuId)));
      }
      if (e is CommunityException) {
        return e.failure == CommunityFailure.throttled
            ? CommunityVoteResult.throttled
            : CommunityVoteResult.failed;
      }
      return showsOfflineIndicator(classifyFailure(e))
          ? CommunityVoteResult.offline
          : CommunityVoteResult.failed;
    }
  }

  /// Remplace (ou ajoute) l'œuvre mise à jour, retire celles qui n'ont plus
  /// aucun vote, et retrie par total — même ordre que l'API.
  static List<CommunityRecommendationDto> _merge(
    List<CommunityRecommendationDto> items,
    CommunityRecommendationDto updated,
  ) {
    final merged = [
      for (final item in items)
        if (item.muId != updated.muId) item,
      if (updated.totalVotes > 0) updated,
    ]..sort((a, b) {
      final byTotal = b.totalVotes.compareTo(a.totalVotes);
      if (byTotal != 0) return byTotal;
      final byApp = b.appVotes.compareTo(a.appVotes);
      return byApp != 0 ? byApp : a.muId.compareTo(b.muId);
    });
    return merged;
  }
}
