part of 'stats_bloc.dart';

abstract class StatsEvent extends Equatable {
  const StatsEvent();
  @override
  List<Object?> get props => [];
}

/// Charge les stats (depuis cache si frais, sinon réseau).
class LoadStats extends StatsEvent {
  const LoadStats();
}

/// Force un re-fetch réseau (invalidate cache puis fetch).
class RefreshStats extends StatsEvent {
  const RefreshStats();
}
