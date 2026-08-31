import 'package:bloc/bloc.dart';
import 'package:equatable/equatable.dart';
import 'package:mangatracker/core/network/failure_classifier.dart';
import 'package:mangatracker/core/service_locator/service_locator.dart';
import 'package:mangatracker/features/stats/dto/user_stats.dto.dart';
import 'package:mangatracker/features/stats/services/stats.service.dart';

part 'stats_event.dart';
part 'stats_state.dart';

/// BLoC des statistiques profil (Phase 2).
///
/// Lecture seule — pas de mutations côté front. Le cache 1h est géré
/// dans `StatsService`. Le BLoC se contente de mapper service → states.
class StatsBloc extends Bloc<StatsEvent, StatsState> {
  final StatsService _statsService = getIt<StatsService>();

  StatsBloc() : super(const StatsInitial()) {
    on<LoadStats>(_onLoadStats);
    on<RefreshStats>(_onRefreshStats);
  }

  Future<void> _onLoadStats(LoadStats event, Emitter<StatsState> emit) async {
    emit(const StatsLoading());
    try {
      final result = await _statsService.getUserStatsWithSource();
      // isOffline reflète la SOURCE réelle de la donnée : sans ça, le
      // bandeau hors ligne des stats n'était jamais atteignable.
      emit(StatsLoaded(stats: result.stats, isOffline: result.fromStaleCache));
    } catch (e) {
      // Le service tente déjà un fallback cache — si on arrive ici, pas de
      // cache disponible.
      final mode = classifyFailure(e);
      emit(StatsError(
        showsOfflineIndicator(mode)
            ? 'Hors ligne et aucune statistique en cache.'
            : e.toString(),
        isOffline: showsOfflineIndicator(mode),
      ));
    }
  }

  Future<void> _onRefreshStats(
    RefreshStats event,
    Emitter<StatsState> emit,
  ) async {
    try {
      await _statsService.invalidateCache();
      final result =
          await _statsService.getUserStatsWithSource(forceRefresh: true);
      emit(StatsLoaded(stats: result.stats, isOffline: result.fromStaleCache));
    } catch (e) {
      final mode = classifyFailure(e);
      emit(StatsError(
        showsOfflineIndicator(mode) ? 'Hors ligne.' : e.toString(),
        isOffline: showsOfflineIndicator(mode),
      ));
    }
  }
}
