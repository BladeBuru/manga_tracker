import 'package:bloc/bloc.dart';
import 'package:equatable/equatable.dart';
import 'package:get_it/get_it.dart';
import 'package:mangatracker/core/network/network_compat.dart';
import 'package:mangatracker/core/service_locator/service_locator.dart';
import 'package:mangatracker/core/services/notification_counts_service.dart';
import 'package:mangatracker/features/friends/dto/friend.dto.dart';
import 'package:mangatracker/features/friends/services/friends.service.dart';
import 'package:mangatracker/features/manga/services/notification_service.dart';

part 'friends_event.dart';
part 'friends_state.dart';

/// BLoC de la page Amis (Phase 6.1).
///
/// Gère 3 listes en parallèle dans le même state :
///  - `accepted` : mes amis confirmés (cache 24h via FriendsService).
///  - `pending` : demandes reçues à traiter (toujours fresh).
///  - `searchResults` : autocomplete pour envoyer une nouvelle demande.
///
/// On garde un seul BLoC (pas un par onglet) parce que les 3 listes sont
/// fortement couplées : accepter une demande la déplace de pending vers
/// accepted, envoyer une demande la retire des résultats de recherche, etc.
class FriendsBloc extends Bloc<FriendsEvent, FriendsState> {
  final FriendsService _service = getIt<FriendsService>();
  final NotificationService _notifications = NotificationService();

  /// Compteur de demandes pending observé au dernier load.
  /// -1 = "jamais chargé" → on n'émet pas de notif au premier load (sinon on
  /// notifierait toutes les demandes pré-existantes à chaque démarrage).
  int _lastPendingCount = -1;

  /// IDs des demandes pending déjà notifiées (évite les doublons sur les
  /// reloads successifs entre deux events réels).
  final Set<int> _notifiedPendingIds = <int>{};

  FriendsBloc() : super(const FriendsInitial()) {
    on<LoadFriends>(_onLoad);
    on<SearchUsers>(_onSearch);
    on<SendFriendRequest>(_onSend);
    on<RespondToRequest>(_onRespond);
    on<RemoveFriend>(_onRemove);
  }

  Future<void> _onLoad(LoadFriends event, Emitter<FriendsState> emit) async {
    emit(const FriendsLoading());
    try {
      final accepted = await _service.getAcceptedFriends(
        forceRefresh: event.forceRefresh,
      );
      final pending = await _service.getPendingRequests();
      _maybeNotifyNewPending(pending);
      emit(FriendsLoaded(
        accepted: accepted,
        pending: pending,
        searchResults: const [],
      ));
    } on SocketException catch (_) {
      // FriendsService a déjà tenté un fallback cache pour `accepted`. Si
      // on arrive ici, c'est qu'on n'a rien de exploitable.
      emit(const FriendsError('Hors ligne'));
    } catch (e) {
      emit(FriendsError(e.toString()));
    }
  }

  Future<void> _onSearch(
    SearchUsers event,
    Emitter<FriendsState> emit,
  ) async {
    if (state is! FriendsLoaded) return;
    final current = state as FriendsLoaded;
    if (event.query.trim().length < 2) {
      emit(current.copyWith(searchResults: const []));
      return;
    }
    try {
      final results = await _service.searchUsers(event.query);
      emit(current.copyWith(searchResults: results));
    } catch (e) {
      // Erreur silencieuse sur la recherche (on garde l'état actuel + log).
      emit(current.copyWith(searchError: e.toString()));
    }
  }

  Future<void> _onSend(
    SendFriendRequest event,
    Emitter<FriendsState> emit,
  ) async {
    if (state is! FriendsLoaded) return;
    final current = state as FriendsLoaded;
    try {
      final created = await _service.sendRequest(addresseeId: event.userId);
      // Retire le user des résultats de recherche, ajoute la demande
      // appropriée (accepted si auto-acceptée côté serveur, sinon ignorée
      // car c'est une demande sortante non visible dans pending/accepted).
      final newResults = current.searchResults
          .where((r) => r.id != event.userId)
          .toList();
      // Si le serveur a auto-accepté (demande inverse pending), on ajoute
      // à accepted directement.
      final newAccepted = created.status == FriendshipStatus.accepted
          ? [created, ...current.accepted]
          : current.accepted;
      emit(current.copyWith(
        accepted: newAccepted,
        searchResults: newResults,
        lastActionMessage: 'request_sent',
      ));
    } catch (e) {
      emit(current.copyWith(lastActionError: e.toString()));
    }
  }

  Future<void> _onRespond(
    RespondToRequest event,
    Emitter<FriendsState> emit,
  ) async {
    if (state is! FriendsLoaded) return;
    final current = state as FriendsLoaded;
    try {
      final updated =
          await _service.updateStatus(event.friendshipId, event.newStatus);
      final newPending = current.pending
          .where((p) => p.id != event.friendshipId)
          .toList();
      final newAccepted = event.newStatus == FriendshipStatus.accepted
          ? [updated, ...current.accepted]
          : current.accepted;
      emit(current.copyWith(
        accepted: newAccepted,
        pending: newPending,
      ));
      // Décrémente le badge BottomNavBar sans attendre le prochain poll
      // (cf. NotificationCountsService Phase 6.2 + 8.2).
      _refreshNotificationsBadge();
    } catch (e) {
      emit(current.copyWith(lastActionError: e.toString()));
    }
  }

  /// Refresh non-bloquant du badge de notifs. Catch silencieux : si le
  /// service n'est pas (encore) enregistré, on laisse tomber.
  void _refreshNotificationsBadge() {
    try {
      final svc = GetIt.instance<NotificationCountsService>();
      svc.refresh();
    } catch (_) {}
  }

  /// Détecte les nouvelles demandes pending entrantes et fire une notif
  /// locale pour chacune. Skip au tout premier load pour ne pas notifier
  /// l'historique pré-existant à chaque démarrage de l'app.
  void _maybeNotifyNewPending(List<FriendshipDto> pending) {
    final received = pending
        .where((p) =>
            p.direction == FriendshipDirection.received &&
            p.status == FriendshipStatus.pending)
        .toList();
    if (_lastPendingCount == -1) {
      _lastPendingCount = received.length;
      _notifiedPendingIds.addAll(received.map((r) => r.id));
      return;
    }
    for (final req in received) {
      if (_notifiedPendingIds.contains(req.id)) continue;
      _notifiedPendingIds.add(req.id);
      _notifications.showFriendRequestNotification(
        senderUsername: req.displayName,
        title: 'Nouvelle demande d\'ami',
        body: '${req.displayName} veut vous ajouter en ami',
      );
    }
    _lastPendingCount = received.length;
  }

  Future<void> _onRemove(
    RemoveFriend event,
    Emitter<FriendsState> emit,
  ) async {
    if (state is! FriendsLoaded) return;
    final current = state as FriendsLoaded;
    try {
      await _service.deleteFriendship(event.friendshipId);
      emit(current.copyWith(
        accepted:
            current.accepted.where((f) => f.id != event.friendshipId).toList(),
        pending:
            current.pending.where((f) => f.id != event.friendshipId).toList(),
      ));
    } catch (e) {
      emit(current.copyWith(lastActionError: e.toString()));
    }
  }
}
