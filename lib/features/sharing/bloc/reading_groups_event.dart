part of 'reading_groups_bloc.dart';

// ─── List BLoC ───

abstract class ReadingGroupsEvent extends Equatable {
  const ReadingGroupsEvent();
  @override
  List<Object?> get props => [];
}

class LoadReadingGroups extends ReadingGroupsEvent {
  const LoadReadingGroups();
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

class PollGroupDetail extends ReadingGroupDetailEvent {
  const PollGroupDetail();
}

class DeleteGroupRequested extends ReadingGroupDetailEvent {
  const DeleteGroupRequested();
}
