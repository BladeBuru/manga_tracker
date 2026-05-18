import 'package:bloc/bloc.dart';
import 'package:equatable/equatable.dart';
import 'package:mangatracker/core/network/network_compat.dart';
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
      final stats = await _statsService.getUserStats();
      emit(StatsLoaded(stats: stats));
    } on SocketException catch (_) {
      // Le service tente déjà un fallback cache — si on arrive ici, pas de
      // cache disponible. On émet une erreur explicite "hors ligne".
      emit(const StatsError('Hors ligne et aucune statistique en cache.'));
    } catch (e) {
      emit(StatsError(e.toString()));
    }
  }

  Future<void> _onRefreshStats(
    RefreshStats event,
    Emitter<StatsState> emit,
  ) async {
    try {
      await _statsService.invalidateCache();
      final stats = await _statsService.getUserStats(forceRefresh: true);
      emit(StatsLoaded(stats: stats));
    } on SocketException catch (_) {
      emit(const StatsError('Hors ligne.'));
    } catch (e) {
      emit(StatsError(e.toString()));
    }
  }
}
