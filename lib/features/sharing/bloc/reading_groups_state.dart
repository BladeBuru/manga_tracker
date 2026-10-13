part of 'reading_groups_bloc.dart';

// ─── List BLoC ───

abstract class ReadingGroupsState extends Equatable {
  const ReadingGroupsState();
  @override
  List<Object?> get props => [];
}

class ReadingGroupsInitial extends ReadingGroupsState {
  const ReadingGroupsInitial();
}

class ReadingGroupsLoading extends ReadingGroupsState {
  const ReadingGroupsLoading();
}

class ReadingGroupsLoaded extends ReadingGroupsState {
  final List<ReadingGroupDto> groups;
  final String? lastError;
  const ReadingGroupsLoaded({required this.groups, this.lastError});

  ReadingGroupsLoaded copyWith({
    List<ReadingGroupDto>? groups,
    String? lastError,
  }) {
    return ReadingGroupsLoaded(
      groups: groups ?? this.groups,
      lastError: lastError,
    );
  }

  @override
  List<Object?> get props => [groups, lastError];
}

class ReadingGroupsError extends ReadingGroupsState {
  final String message;
  const ReadingGroupsError(this.message);
  @override
  List<Object?> get props => [message];
}

// ─── Detail BLoC ───

abstract class ReadingGroupDetailState extends Equatable {
  const ReadingGroupDetailState();
  @override
  List<Object?> get props => [];
}

class ReadingGroupDetailInitial extends ReadingGroupDetailState {
  const ReadingGroupDetailInitial();
}

class ReadingGroupDetailLoading extends ReadingGroupDetailState {
  const ReadingGroupDetailLoading();
}

class ReadingGroupDetailLoaded extends ReadingGroupDetailState {
  final ReadingGroupDto group;

  /// Un enregistrement de MA progression est en cours.
  final bool isSavingProgress;

  const ReadingGroupDetailLoaded({
    required this.group,
    this.isSavingProgress = false,
  });

  @override
  List<Object?> get props => [group, isSavingProgress];
}

/// Issue d'un enregistrement de MA progression (effet ponctuel : la page
/// affiche le message adapté). Reste un [ReadingGroupDetailLoaded] : le
/// contenu ne disparaît jamais derrière un écran d'erreur. [attempt] rend
/// chaque issue distincte (deux échecs identiques s'affichent tous les deux).
class ReadingGroupProgressUpdated extends ReadingGroupDetailLoaded {
  final int readChapters;
  final ChapterProgressResult result;
  final int attempt;

  const ReadingGroupProgressUpdated({
    required super.group,
    required this.readChapters,
    required this.result,
    required this.attempt,
  });

  @override
  List<Object?> get props => [...super.props, readChapters, result, attempt];
}

class ReadingGroupDetailError extends ReadingGroupDetailState {
  final String message;
  const ReadingGroupDetailError(this.message);
  @override
  List<Object?> get props => [message];
}

/// Émis après une suppression réussie pour signaler à l'UI de pop la page.
class ReadingGroupDetailDeleted extends ReadingGroupDetailState {
  const ReadingGroupDetailDeleted();
}

/// Émis si la suppression échoue (rare — l'UI affiche un SnackBar et reste
/// sur la page).
class ReadingGroupDetailDeleteFailed extends ReadingGroupDetailState {
  final ReadingGroupDto group;
  final String message;
  const ReadingGroupDetailDeleteFailed({
    required this.group,
    required this.message,
  });
  @override
  List<Object?> get props => [group, message];
}
