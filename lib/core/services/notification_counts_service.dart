import 'dart:async';

import 'package:equatable/equatable.dart';
import 'package:flutter/foundation.dart';
import 'package:mangatracker/core/service_locator/service_locator.dart';
import 'package:mangatracker/features/friends/dto/friend.dto.dart';
import 'package:mangatracker/features/friends/services/friends.service.dart';
import 'package:mangatracker/features/manga/services/notification_service.dart';
import 'package:mangatracker/features/notifications/services/notification_alerter.dart';
import 'package:mangatracker/features/notifications/services/notifications.service.dart';
import 'package:mangatracker/features/sharing/dto/share.dto.dart';
import 'package:mangatracker/features/sharing/services/sharing.service.dart';

/// Compteurs « à traiter », **par source** : chaque pastille de l'interface
/// lit la sienne. Un total seul ne disait pas où aller.
///
/// - onglet « Mon compte » : [total] (demandes d'ami + recommandations) ;
/// - lignes du profil : [pendingFriendRequests], [unseenShares] ;
/// - cloche de l'accueil : [unreadNotifications] (centre de notifications).
class NotificationCounts extends Equatable {
  final int pendingFriendRequests;
  final int unseenShares;
  final int unreadNotifications;

  const NotificationCounts({
    this.pendingFriendRequests = 0,
    this.unseenShares = 0,
    this.unreadNotifications = 0,
  });

  static const NotificationCounts zero = NotificationCounts();

  /// Ce qui attend dans « Mon compte » (inchangé : la cloche a sa pastille).
  int get total => pendingFriendRequests + unseenShares;

  NotificationCounts copyWith({
    int? pendingFriendRequests,
    int? unseenShares,
    int? unreadNotifications,
  }) =>
      NotificationCounts(
        pendingFriendRequests:
            pendingFriendRequests ?? this.pendingFriendRequests,
        unseenShares: unseenShares ?? this.unseenShares,
        unreadNotifications: unreadNotifications ?? this.unreadNotifications,
      );

  @override
  List<Object?> get props =>
      [pendingFriendRequests, unseenShares, unreadNotifications];
}

/// Compteurs des notifications de l'application + notifications locales.
///
/// Sources : `/friends/pending`, `/sharing/inbox` (repli
/// `/sharing/inbox/unseen-count`) et `/notifications/unread-count`.
///
/// - Interrogation toutes les 60 s ([start] / [stop]) et à la demande
///   ([refresh] : retour au premier plan, onglet « Mon compte », actions).
/// - Une source en échec garde sa dernière valeur (pas de clignotement).
/// - **Notifications locales, un seul chemin** ([NotificationAlerter]) : si
///   le serveur expose le centre de notifications, c'est lui qui annonce
///   (demandes d'ami comprises) quand le nombre de non lues augmente ; sinon
///   (ancien serveur) la boîte de réception et les demandes en attente
///   prennent le relais. Registre anti-doublon commun aux deux.
/// - [reset] à la déconnexion : rien ne fuit d'un compte à l'autre.
class NotificationCountsService {
  static const Duration _pollInterval = Duration(seconds: 60);

  /// Lignes relues quand le nombre de non lues augmente.
  static const int _newestPageSize = 10;

  final FriendsService _friends;
  final SharingService _sharing;
  final NotificationsService? _feedOverride;
  final NotificationAlerter _alerter;

  NotificationCountsService({
    FriendsService? friends,
    SharingService? sharing,
    NotificationService? notifications,
    NotificationsService? feed,
    NotificationAlerter? alerter,
  })  : _friends = friends ?? getIt<FriendsService>(),
        _sharing = sharing ?? getIt<SharingService>(),
        _feedOverride = feed,
        _alerter = alerter ?? NotificationAlerter(notifications: notifications);

  /// Résolu à l'appel (lazy singleton enregistré en fin de service locator).
  NotificationsService get _feed =>
      _feedOverride ?? getIt<NotificationsService>();

  final StreamController<NotificationCounts> _controller =
      StreamController<NotificationCounts>.broadcast();
  Timer? _timer;
  NotificationCounts _last = NotificationCounts.zero;

  /// Le serveur a répondu au moins une fois sur `/notifications` : c'est lui
  /// qui annonce, plus la boîte de réception (pas de double annonce).
  bool _feedAvailable = false;

  /// Non lues à la dernière interrogation réussie du centre.
  int? _lastUnread;

  Stream<NotificationCounts> get countsStream => _controller.stream;

  NotificationCounts get lastCounts => _last;

  /// Lance l'interrogation périodique. Idempotent.
  Future<NotificationCountsService> start() async {
    if (_timer != null && _timer!.isActive) return this;
    unawaited(refresh());
    _timer = Timer.periodic(_pollInterval, (_) => refresh());
    return this;
  }

  void stop() {
    _timer?.cancel();
    _timer = null;
  }

  /// Oublie tout (déconnexion, changement de compte).
  void reset() {
    stop();
    _alerter.reset();
    _feedAvailable = false;
    _lastUnread = null;
    try {
      _sharing.clearCache();
    } catch (_) {}
    _emit(NotificationCounts.zero);
  }

  Future<NotificationCounts> refresh() async {
    final results = await Future.wait<Object?>([
      _quietly(() => _friends.getPendingRequests()),
      _quietly(() => _sharing.getInbox()),
      _quietly(() => _feed.fetchUnreadCount()),
    ]);
    final pending = results[0] as List<FriendshipDto>?;
    final inbox = results[1] as List<MangaShareDto>?;
    final unread = results[2] as int?;
    final unseen = inbox?.where((s) => s.isNew).toList();
    final unseenCount =
        unseen?.length ?? await _quietly(() => _sharing.getUnseenCount());

    if (unread != null) _feedAvailable = true;
    await _announce(pending: pending, unseen: unseen, unread: unread);

    final counts = NotificationCounts(
      pendingFriendRequests: pending?.length ?? _last.pendingFriendRequests,
      unseenShares: unseenCount ?? _last.unseenShares,
      unreadNotifications: unread ?? _last.unreadNotifications,
    );
    _emit(counts);
    return counts;
  }

  Future<void> _announce({
    required List<FriendshipDto>? pending,
    required List<MangaShareDto>? unseen,
    required int? unread,
  }) async {
    if (!_feedAvailable) {
      if (pending != null) await _alerter.onPendingRequests(pending);
      if (unseen != null) await _alerter.onUnseenShares(unseen);
      return;
    }
    if (unread == null) return;
    final firstLook = !_alerter.hasBaseline(AlertSource.feed);
    if (firstLook && unread == 0) {
      _lastUnread = 0;
      await _alerter.onFeedItems(const []); // référence vide posée
      return;
    }
    if (!firstLook && unread <= (_lastUnread ?? 0)) {
      _lastUnread = unread; // baisse ou statu quo : rien de nouveau
      return;
    }
    final page = await _quietly(() => _feed.fetchPage(
          limit: firstLook ? NotificationsService.pageSize : _newestPageSize,
        ));
    // Lecture ratée : le compteur précédent est gardé, la hausse sera vue
    // à la prochaine interrogation.
    if (page == null) return;
    _lastUnread = unread;
    await _alerter.onFeedItems(page.items);
  }

  /// Mise à jour immédiate après « tout marquer comme vu », sans attendre la
  /// prochaine interrogation.
  void markSharesSeen() => _emit(_last.copyWith(unseenShares: 0));

  /// Mise à jour immédiate de la cloche (ligne lue, « tout marquer comme
  /// lu ») — une baisse n'est jamais prise pour une nouveauté.
  void setUnreadNotifications(int count) {
    final value = count < 0 ? 0 : count;
    _lastUnread = value;
    _emit(_last.copyWith(unreadNotifications: value));
  }

  void _emit(NotificationCounts counts) {
    _last = counts;
    if (!_controller.isClosed) _controller.add(counts);
  }

  static Future<T?> _quietly<T>(Future<T> Function() call) async {
    try {
      return await call();
    } catch (e) {
      debugPrint('NotificationCountsService: source indisponible ($e)');
      return null;
    }
  }

  void dispose() {
    stop();
    _controller.close();
  }
}
