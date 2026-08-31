part of 'stats_bloc.dart';

abstract class StatsState extends Equatable {
  const StatsState();
  @override
  List<Object?> get props => [];
}

class StatsInitial extends StatsState {
  const StatsInitial();
}

class StatsLoading extends StatsState {
  const StatsLoading();
}

class StatsLoaded extends StatsState {
  final UserStatsDto stats;
  final bool isOffline;

  const StatsLoaded({required this.stats, this.isOffline = false});

  @override
  List<Object?> get props => [stats, isOffline];
}

class StatsError extends StatsState {
  final String message;

  /// L'échec vient d'une indisponibilité réseau (et non d'une erreur
  /// serveur) : l'écran doit dire « hors ligne », pas « erreur ».
  final bool isOffline;

  const StatsError(this.message, {this.isOffline = false});
  @override
  List<Object?> get props => [message, isOffline];
}
