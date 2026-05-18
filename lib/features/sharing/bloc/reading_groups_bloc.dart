import 'dart:async';

import 'package:bloc/bloc.dart';
import 'package:equatable/equatable.dart';
import 'package:mangatracker/core/service_locator/service_locator.dart';
import 'package:mangatracker/features/sharing/dto/reading_group.dto.dart';
import 'package:mangatracker/features/sharing/services/reading_groups.service.dart';

part 'reading_groups_event.dart';
part 'reading_groups_state.dart';

/// BLoC pour la liste des groupes (Phase 8.3 UI).
///
/// Garde la liste fraîche via `LoadGroups` (pas de polling — l'utilisateur
/// fait un pull-to-refresh ou revisite la page). Pour la sync de
/// progression cross-membres en quasi-réel, c'est le `ReadingGroupDetailBloc`
/// dédié qui poll toutes les 30s.
class ReadingGroupsBloc
    extends Bloc<ReadingGroupsEvent, ReadingGroupsState> {
  final ReadingGroupsService _service = getIt<ReadingGroupsService>();

  ReadingGroupsBloc() : super(const ReadingGroupsInitial()) {
    on<LoadReadingGroups>(_onLoad);
    on<LeaveGroupRequested>(_onLeave);
  }

  Future<void> _onLoad(
    LoadReadingGroups event,
    Emitter<ReadingGroupsState> emit,
  ) async {
    emit(const ReadingGroupsLoading());
    try {
      final groups = await _service.getMyGroups();
      emit(ReadingGroupsLoaded(groups: groups));
    } catch (e) {
      emit(ReadingGroupsError(e.toString()));
    }
  }

  Future<void> _onLeave(
    LeaveGroupRequested event,
    Emitter<ReadingGroupsState> emit,
  ) async {
    if (state is! ReadingGroupsLoaded) return;
    final current = state as ReadingGroupsLoaded;
    try {
      await _service.leave(event.groupId);
      emit(current.copyWith(
        groups: current.groups.where((g) => g.id != event.groupId).toList(),
      ));
    } catch (e) {
      emit(current.copyWith(lastError: e.toString()));
    }
  }
}

/// BLoC dédié à la page détail d'un groupe (polling 30s).
///
/// Au mount : LoadDetail + démarrage du polling. Au dispose : cancel timer.
/// Le polling se contente de re-fetch le groupe pour récupérer la
/// progression à jour des autres membres.
class ReadingGroupDetailBloc
    extends Bloc<ReadingGroupDetailEvent, ReadingGroupDetailState> {
  final ReadingGroupsService _service = getIt<ReadingGroupsService>();
  final int groupId;

  Timer? _pollTimer;
  static const Duration _pollInterval = Duration(seconds: 30);

  ReadingGroupDetailBloc(this.groupId)
      : super(const ReadingGroupDetailInitial()) {
    on<LoadGroupDetail>(_onLoad);
    on<PollGroupDetail>(_onPoll);
    on<DeleteGroupRequested>(_onDelete);
  }

  Future<void> _onLoad(
    LoadGroupDetail event,
    Emitter<ReadingGroupDetailState> emit,
  ) async {
    emit(const ReadingGroupDetailLoading());
    try {
      final group = await _service.getGroup(groupId);
      emit(ReadingGroupDetailLoaded(group: group));
      _startPolling();
    } catch (e) {
      emit(ReadingGroupDetailError(e.toString()));
    }
  }

  Future<void> _onPoll(
    PollGroupDetail event,
    Emitter<ReadingGroupDetailState> emit,
  ) async {
    if (state is! ReadingGroupDetailLoaded) return;
    try {
      final group = await _service.getGroup(groupId);
      emit(ReadingGroupDetailLoaded(group: group));
    } catch (_) {
      // Erreur silencieuse pendant le poll — on garde la dernière vue valide.
    }
  }

  Future<void> _onDelete(
    DeleteGroupRequested event,
    Emitter<ReadingGroupDetailState> emit,
  ) async {
    final current = state;
    if (current is! ReadingGroupDetailLoaded) return;
    try {
      _pollTimer?.cancel();
      await _service.deleteGroup(groupId);
      emit(const ReadingGroupDetailDeleted());
    } catch (e) {
      emit(ReadingGroupDetailDeleteFailed(
        group: current.group,
        message: e.toString(),
      ));
      // On reprend l'affichage normal — l'UI a déjà reçu le signal d'échec.
      emit(ReadingGroupDetailLoaded(group: current.group));
      _startPolling();
    }
  }

  void _startPolling() {
    _pollTimer?.cancel();
    _pollTimer = Timer.periodic(_pollInterval, (_) {
      if (!isClosed) add(const PollGroupDetail());
    });
  }

  @override
  Future<void> close() {
    _pollTimer?.cancel();
    return super.close();
  }
}
