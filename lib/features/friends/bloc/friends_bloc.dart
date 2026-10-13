import 'package:bloc/bloc.dart';
import 'package:equatable/equatable.dart';
import 'package:mangatracker/core/network/failure_classifier.dart';
import 'package:mangatracker/core/service_locator/service_locator.dart';
import 'package:mangatracker/core/services/notification_counts_service.dart';
import 'package:mangatracker/features/friends/dto/friend.dto.dart';
import 'package:mangatracker/features/friends/services/friends.service.dart';

part 'friends_event.dart';
part 'friends_state.dart';
part 'friends_search_handlers.dart';

/// BLoC de la page Amis (Phase 6.1).
///
/// Quatre listes couplées dans le même état : amis, demandes reçues,
/// demandes envoyées, résultats de recherche (avec leur relation).
///
/// Les notifications locales des demandes d'ami ne vivent plus ici : elles
/// passent par `NotificationCountsService` (interrogation périodique de
/// toute l'application). L'ancien compteur de ce BLoC repartait de zéro à
/// chaque ouverture de la page et ne notifiait donc jamais.
class FriendsBloc extends Bloc<FriendsEvent, FriendsState>
    with _FriendsSearchHandlers {
  @override
  final FriendsService _service;
  final void Function() _refreshBadges;

  FriendsBloc({FriendsService? service, void Function()? refreshBadges})
      : _service = service ?? getIt<FriendsService>(),
        _refreshBadges = refreshBadges ?? _refreshNotificationCounts,
        super(const FriendsInitial()) {
    on<LoadFriends>(_onLoad);
    on<SearchUsers>(_onSearch);
    on<SendFriendRequest>(_onSend);
    on<RespondToRequest>(_onRespond);
    on<RemoveFriend>(_onRemove);
    on<CancelFriendRequest>(_onCancel);
  }

  /// Trois listes en parallèle ; une source en échec n'empêche pas d'afficher
  /// les autres (repli cache des amis). Tout en échec → état d'erreur.
  Future<void> _onLoad(LoadFriends event, Emitter<FriendsState> emit) async {
    final previous = state is FriendsLoaded ? state as FriendsLoaded : null;
    if (previous == null) emit(const FriendsLoading());
    Object? failure;
    Future<List<FriendshipDto>?> guard(
        Future<List<FriendshipDto>> Function() call) async {
      try {
        return await call();
      } catch (e) {
        failure ??= e;
        return null;
      }
    }

    final results = await Future.wait([
      guard(() => _service.getAcceptedFriends(forceRefresh: event.forceRefresh)),
      guard(_service.getPendingRequests),
      guard(_service.getSentRequests),
    ]);
    final error = failure;
    if (results.every((r) => r == null) && error != null) {
      final mode = classifyFailure(error);
      emit(FriendsError(error, isOffline: showsOfflineIndicator(mode)));
      return;
    }
    emit(FriendsLoaded(
      accepted: results[0] ?? previous?.accepted ?? const [],
      pending: results[1] ?? previous?.pending ?? const [],
      sent: results[2] ?? previous?.sent ?? const [],
      searchQuery: previous?.searchQuery ?? '',
      searchResults: previous?.searchResults ?? const [],
      isOffline: error != null && showsOfflineIndicator(classifyFailure(error)),
    ));
  }

  Future<void> _onSend(
    SendFriendRequest event,
    Emitter<FriendsState> emit,
  ) async {
    if (state is! FriendsLoaded) return;
    try {
      final created = await _service.sendRequest(addresseeId: event.userId);
      final current = state as FriendsLoaded;
      // Demande inverse déjà en attente : le serveur accepte d'office.
      if (created.status == FriendshipStatus.accepted) {
        emit(current.copyWith(
          accepted: [created, ...current.accepted],
          pending: current.pending
              .where((p) => p.otherUserId != event.userId)
              .toList(),
          searchResults:
              current.resultsWith(event.userId, FriendRelation.friends),
          feedback: FriendsFeedback.nowFriends,
          feedbackName: event.displayName ?? created.displayName,
        ));
        _refreshBadges();
        return;
      }
      emit(current.copyWith(
        sent: [created, ...current.sent],
        searchResults:
            current.resultsWith(event.userId, FriendRelation.pendingSent),
        feedback: FriendsFeedback.requestSent,
      ));
    } catch (e) {
      _emitActionError(emit, e);
    }
  }

  Future<void> _onRespond(
    RespondToRequest event,
    Emitter<FriendsState> emit,
  ) async {
    if (state is! FriendsLoaded) return;
    try {
      final updated =
          await _service.updateStatus(event.friendshipId, event.newStatus);
      final current = state as FriendsLoaded;
      final accepted = event.newStatus == FriendshipStatus.accepted;
      emit(current.copyWith(
        accepted: accepted ? [updated, ...current.accepted] : current.accepted,
        pending:
            current.pending.where((p) => p.id != event.friendshipId).toList(),
        searchResults: current.resultsWith(
          updated.otherUserId,
          accepted ? FriendRelation.friends : FriendRelation.none,
        ),
        feedback: accepted ? FriendsFeedback.nowFriends : null,
        feedbackName: accepted ? updated.displayName : null,
      ));
      // Décrémente les pastilles sans attendre la prochaine interrogation.
      _refreshBadges();
    } catch (e) {
      _emitActionError(emit, e);
    }
  }

  /// Retire un ami ou refuse une demande reçue.
  Future<void> _onRemove(
    RemoveFriend event,
    Emitter<FriendsState> emit,
  ) async {
    if (state is! FriendsLoaded) return;
    try {
      await _service.deleteFriendship(event.friendshipId);
      final current = state as FriendsLoaded;
      final removed = [...current.accepted, ...current.pending]
          .where((f) => f.id == event.friendshipId).firstOrNull;
      emit(current.copyWith(
        accepted:
            current.accepted.where((f) => f.id != event.friendshipId).toList(),
        pending:
            current.pending.where((f) => f.id != event.friendshipId).toList(),
        searchResults: removed == null
            ? current.searchResults
            : current.resultsWith(removed.otherUserId, FriendRelation.none),
      ));
      // Refuser une demande la retire aussi des pastilles.
      _refreshBadges();
    } catch (e) {
      _emitActionError(emit, e);
    }
  }

  Future<void> _onCancel(
    CancelFriendRequest event,
    Emitter<FriendsState> emit,
  ) async {
    if (state is! FriendsLoaded) return;
    try {
      await _service.deleteFriendship(event.friendshipId);
      final current = state as FriendsLoaded;
      final cancelled =
          current.sent.where((f) => f.id == event.friendshipId).firstOrNull;
      emit(current.copyWith(
        sent: current.sent.where((f) => f.id != event.friendshipId).toList(),
        searchResults: cancelled == null
            ? current.searchResults
            : current.resultsWith(cancelled.otherUserId, FriendRelation.none),
        feedback: FriendsFeedback.requestCancelled,
      ));
    } catch (e) {
      _emitActionError(emit, e);
    }
  }

  /// Une action en échec émet TOUJOURS un état (jamais de spinner sans
  /// issue) ; le texte vient de `userFacingErrorMessage` dans la vue.
  void _emitActionError(Emitter<FriendsState> emit, Object error) {
    final current = state;
    if (current is FriendsLoaded) emit(current.copyWith(actionError: error));
  }

  static void _refreshNotificationCounts() {
    try {
      getIt<NotificationCountsService>().refresh();
    } catch (_) {}
  }
}
