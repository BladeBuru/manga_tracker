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

  /// Le serveur a rejeté la session (401/403) : l'utilisateur est invité à se
  /// reconnecter, **sans être bloqué**. Le contenu en cache reste affiché
  /// derrière l'invitation — cf. `failure_classifier.dart`, frontière de
  /// sécurité. Ne jamais rebrancher une redirection forcée dessus.
  final bool requiresReauth;

  const StatsLoaded({
    required this.stats,
    this.isOffline = false,
    this.requiresReauth = false,
  });

  @override
  List<Object?> get props => [stats, isOffline, requiresReauth];
}

class StatsError extends StatsState {
  final String message;

  /// L'échec vient d'une indisponibilité réseau (et non d'une erreur
  /// serveur) : l'écran doit dire « hors ligne », pas « erreur ».
  final bool isOffline;

  /// Le serveur a rejeté la session (401/403) : l'utilisateur est invité à se
  /// reconnecter, **sans être bloqué**. Le contenu en cache reste affiché
  /// derrière l'invitation — cf. `failure_classifier.dart`, frontière de
  /// sécurité. Ne jamais rebrancher une redirection forcée dessus.
  final bool requiresReauth;

  const StatsError(this.message,
      {this.isOffline = false, this.requiresReauth = false});
  @override
  List<Object?> get props => [message, isOffline, requiresReauth];
}
