import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:mangatracker/core/service_locator/service_locator.dart';
import 'package:mangatracker/features/friends/services/friends.service.dart';
import 'package:mangatracker/features/manga/services/notification_service.dart';
import 'package:mangatracker/features/sharing/dto/share.dto.dart';
import 'package:mangatracker/features/sharing/services/sharing.service.dart';

/// Compteurs agrégés pour le badge BottomNavBar (Phase 6.2 + 8.2).
///
/// Source : `/friends/pending` + `/sharing/inbox` (utilisé pour à la fois
/// le compteur des unread shares ET la détection de nouveaux shares pour
/// fire des notifications locales).
///
/// Stratégie :
///  - Polling toutes les 60s.
///  - Refresh forcé via [refresh()].
///  - Lors de chaque poll, détecte les nouveaux shares non-vus (vs le dernier
///    snapshot) et déclenche `NotificationService.showShareReceivedNotification`
///    pour chacun.
///  - `start()` lance le polling, `stop()` l'arrête (à appeler au logout).
class NotificationCountsService {
  static const Duration _pollInterval = Duration(seconds: 60);

  final FriendsService _friends = getIt<FriendsService>();
  final SharingService _sharing = getIt<SharingService>();
  final NotificationService _notifications = NotificationService();

  final StreamController<int> _controller = StreamController<int>.broadcast();
  Timer? _timer;
  int _lastValue = 0;

  /// IDs des shares déjà notifiés (anti-doublons).
  final Set<int> _notifiedShareIds = <int>{};

  /// Skip au premier poll : on enregistre les shares existants sans fire de
  /// notification (sinon on inonderait l'utilisateur à chaque démarrage).
  bool _firstSharesPoll = true;

  /// Stream émettant le compteur total (pending friends + unseen shares).
  Stream<int> get countStream => _controller.stream;

  /// Dernière valeur connue — utile pour seed initial.
  int get lastValue => _lastValue;

  /// Lance le polling. Idempotent : appels multiples = un seul timer actif.
  Future<NotificationCountsService> start() async {
    if (_timer != null && _timer!.isActive) return this;
    unawaited(refresh());
    _timer = Timer.periodic(_pollInterval, (_) => refresh());
    return this;
  }

  /// Arrête le polling (à appeler au logout pour libérer le timer).
  void stop() {
    _timer?.cancel();
    _timer = null;
  }

  /// Force un refresh immédiat.
  Future<int> refresh() async {
    try {
      final results = await Future.wait<int>([
        _fetchPendingCount(),
        _fetchUnseenSharesAndNotify(),
      ]);
      final total = results[0] + results[1];
      _lastValue = total;
      if (!_controller.isClosed) _controller.add(total);
      return total;
    } catch (e) {
      debugPrint('NotificationCountsService refresh error: $e');
      return _lastValue;
    }
  }

  Future<int> _fetchPendingCount() async {
    try {
      final pending = await _friends.getPendingRequests();
      return pending.length;
    } catch (_) {
      return 0;
    }
  }

  /// Récupère l'inbox, compte les non-vus et déclenche les notifs locales
  /// pour les nouveaux shares détectés depuis le dernier poll.
  Future<int> _fetchUnseenSharesAndNotify() async {
    try {
      final inbox = await _sharing.getInbox();
      final unseen = inbox.where((s) => s.isNew).toList();
      _maybeNotifyNewShares(unseen);
      return unseen.length;
    } catch (_) {
      // Fallback : tente au moins de récupérer le compte sans détection.
      try {
        return await _sharing.getUnseenCount();
      } catch (_) {
        return 0;
      }
    }
  }

  void _maybeNotifyNewShares(List<MangaShareDto> unseen) {
    if (_firstSharesPoll) {
      _firstSharesPoll = false;
      _notifiedShareIds.addAll(unseen.map((s) => s.id));
      return;
    }
    for (final share in unseen) {
      if (_notifiedShareIds.contains(share.id)) continue;
      _notifiedShareIds.add(share.id);
      _notifications.showShareReceivedNotification(
        senderUsername: share.senderUsername,
        mangaTitle: share.mangaTitle,
        muId: share.mangaMuId,
        title: 'Nouveau manga partagé',
        body: '${share.senderUsername} vous recommande ${share.mangaTitle}',
      );
    }
  }

  void dispose() {
    stop();
    _controller.close();
  }
}
