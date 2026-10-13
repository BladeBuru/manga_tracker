part of 'reading_groups_bloc.dart';

// ─── List BLoC ───

abstract class ReadingGroupsEvent extends Equatable {
  const ReadingGroupsEvent();
  @override
  List<Object?> get props => [];
}

class LoadReadingGroups extends ReadingGroupsEvent {
  /// Rechargement sans indicateur (retour sur la page) : la liste affichée
  /// reste en place pendant la requête et si elle échoue.
  final bool silent;

  const LoadReadingGroups({this.silent = false});

  @override
  List<Object?> get props => [silent];
}

class LeaveGroupRequested extends ReadingGroupsEvent {
  final int groupId;
  const LeaveGroupRequested(this.groupId);
  @override
  List<Object?> get props => [groupId];
}

// ─── Detail BLoC ───

abstract class ReadingGroupDetailEvent extends Equatable {
  const ReadingGroupDetailEvent();
  @override
  List<Object?> get props => [];
}

class LoadGroupDetail extends ReadingGroupDetailEvent {
  const LoadGroupDetail();
}

/// Rafraîchissement silencieux (minuterie, retour sur la page).
class PollGroupDetail extends ReadingGroupDetailEvent {
  const PollGroupDetail();
}

/// La page du groupe passe au premier plan ([visible]) ou est recouverte :
/// le rafraîchissement périodique ne tourne que pour la page affichée.
class GroupDetailVisibilityChanged extends ReadingGroupDetailEvent {
  final bool visible;
  const GroupDetailVisibilityChanged(this.visible);
  @override
  List<Object?> get props => [visible];
}

/// Enregistre MA progression sur le titre du groupe (« dernier chapitre
/// TERMINÉ »), affirmée dans la fenêtre « Ma progression ».
class UpdateMyGroupProgress extends ReadingGroupDetailEvent {
  final int readChapters;
  const UpdateMyGroupProgress(this.readChapters);
  @override
  List<Object?> get props => [readChapters];
}

class DeleteGroupRequested extends ReadingGroupDetailEvent {
  const DeleteGroupRequested();
}
