import 'dart:async';

import 'package:bloc/bloc.dart';
import 'package:equatable/equatable.dart';
import 'package:mangatracker/core/service_locator/service_locator.dart';
import 'package:mangatracker/features/library/services/chapter_progress.service.dart';
import 'package:mangatracker/features/library/services/chapter_progress_result.dart';
import 'package:mangatracker/features/sharing/dto/reading_group.dto.dart';
import 'package:mangatracker/features/sharing/services/reading_groups.service.dart';

part 'reading_groups_event.dart';
part 'reading_groups_state.dart';
part 'reading_group_detail_bloc.dart';

/// BLoC pour la liste des groupes (Phase 8.3 UI).
///
/// Garde la liste fraîche via `LoadGroups` (pas de polling — l'utilisateur
/// fait un pull-to-refresh, ou la page se recharge en silence quand elle
/// repasse au premier plan). Pour la sync de progression cross-membres en
/// quasi-réel, c'est le `ReadingGroupDetailBloc` dédié qui poll toutes les
/// 30s.
class ReadingGroupsBloc
    extends Bloc<ReadingGroupsEvent, ReadingGroupsState> {
  final ReadingGroupsService _service;

  ReadingGroupsBloc({ReadingGroupsService? service})
      : _service = service ?? getIt<ReadingGroupsService>(),
        super(const ReadingGroupsInitial()) {
    on<LoadReadingGroups>(_onLoad);
    on<LeaveGroupRequested>(_onLeave);
  }

  Future<void> _onLoad(
    LoadReadingGroups event,
    Emitter<ReadingGroupsState> emit,
  ) async {
    // Rechargement silencieux (retour sur la page) : la liste affichée reste
    // en place, sans indicateur ni écran d'erreur s'il échoue.
    final silent = event.silent && state is ReadingGroupsLoaded;
    if (!silent) emit(const ReadingGroupsLoading());
    try {
      final groups = await _service.getMyGroups();
      emit(ReadingGroupsLoaded(groups: groups));
    } catch (e) {
      if (!silent) emit(ReadingGroupsError(e.toString()));
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
