import 'dart:async';

import 'package:equatable/equatable.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart' show Locale;
import 'package:mangatracker/core/service_locator/service_locator.dart';
import 'package:mangatracker/core/services/language_service.dart';
import 'package:mangatracker/features/friends/services/friends.service.dart';
import 'package:mangatracker/features/manga/services/notification_service.dart';
import 'package:mangatracker/features/sharing/dto/share.dto.dart';
import 'package:mangatracker/features/sharing/services/sharing.service.dart';
import 'package:mangatracker/l10n/app_localizations.dart';

/// Compteurs « à traiter », **par source** : chaque pastille de l'interface
/// (onglet « Mon compte », lignes « Mes amis », « Recommandations reçues »)
/// lit la sienne. Un total seul ne disait pas où aller.
class NotificationCounts extends Equatable {
  final int pendingFriendRequests;
  final int unseenShares;

  const NotificationCounts({
    this.pendingFriendRequests = 0,
    this.unseenShares = 0,
  });

  static const NotificationCounts zero = NotificationCounts();

  int get total => pendingFriendRequests + unseenShares;

  @override
  List<Object?> get props => [pendingFriendRequests, unseenShares];
}

/// Compteurs des notifications de l'application (Phase 6.2 + 8.2).
///
/// Sources : `/friends/pending` (demandes reçues) et `/sharing/inbox`
/// (recommandations d'amis non vues — aussi utilisé pour détecter les
/// nouvelles et déclencher une notification locale).
///
/// - Interrogation toutes les 60 s ([start] / [stop]) et à la demande
///   ([refresh] : retour au premier plan, onglet « Mon compte », actions).
/// - Une source en échec garde sa dernière valeur (un réseau capricieux ne
///   fait pas clignoter les pastilles).
/// - [reset] à la déconnexion : rien ne fuit d'un compte à l'autre.
class NotificationCountsService {
  static const Duration _pollInterval = Duration(seconds: 60);

  final FriendsService _friends;
  final SharingService _sharing;
  final NotificationService _notifications;

  NotificationCountsService({
    FriendsService? friends,
    SharingService? sharing,
    NotificationService? notifications,
  }) : _friends = friends ?? getIt<FriendsService>(),
       _sharing = sharing ?? getIt<SharingService>(),
       _notifications = notifications ?? NotificationService();

  final StreamController<NotificationCounts> _controller =
      StreamController<NotificationCounts>.broadcast();
  Timer? _timer;
  NotificationCounts _last = NotificationCounts.zero;

  /// IDs des partages déjà notifiés (anti-doublons).
  final Set<int> _notifiedShareIds = <int>{};

  /// Premier passage : on mémorise les partages existants sans notifier
  /// (sinon chaque démarrage renotifierait tout l'historique).
  bool _firstSharesPoll = true;

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
    _notifiedShareIds.clear();
    _firstSharesPoll = true;
    _emit(NotificationCounts.zero);
  }

  Future<NotificationCounts> refresh() async {
    final results = await Future.wait<int?>([
      _fetchPendingCount(),
      _fetchUnseenSharesAndNotify(),
    ]);
    final counts = NotificationCounts(
      pendingFriendRequests: results[0] ?? _last.pendingFriendRequests,
      unseenShares: results[1] ?? _last.unseenShares,
    );
    _emit(counts);
    return counts;
  }

  /// Mise à jour immédiate après « tout marquer comme vu », sans attendre la
  /// prochaine interrogation.
  void markSharesSeen() {
    _emit(
      NotificationCounts(
        pendingFriendRequests: _last.pendingFriendRequests,
        unseenShares: 0,
      ),
    );
  }

  void _emit(NotificationCounts counts) {
    _last = counts;
    if (!_controller.isClosed) _controller.add(counts);
  }

  Future<int?> _fetchPendingCount() async {
    try {
      final pending = await _friends.getPendingRequests();
      return pending.length;
    } catch (e) {
      debugPrint('NotificationCountsService: demandes indisponibles ($e)');
      return null;
    }
  }

  Future<int?> _fetchUnseenSharesAndNotify() async {
    try {
      final inbox = await _sharing.getInbox();
      final unseen = inbox.where((s) => s.isNew).toList();
      _maybeNotifyNewShares(unseen);
      return unseen.length;
    } catch (_) {
      try {
        return await _sharing.getUnseenCount();
      } catch (e) {
        debugPrint('NotificationCountsService: partages indisponibles ($e)');
        return null;
      }
    }
  }

  void _maybeNotifyNewShares(List<MangaShareDto> unseen) {
    if (_firstSharesPoll) {
      _firstSharesPoll = false;
      _notifiedShareIds.addAll(unseen.map((s) => s.id));
      return;
    }
    final fresh = unseen.where((s) => !_notifiedShareIds.contains(s.id));
    if (fresh.isEmpty) return;
    final l10n = _localizations();
    for (final share in fresh) {
      _notifiedShareIds.add(share.id);
      _notifications.showShareReceivedNotification(
        senderUsername: share.senderUsername,
        mangaTitle: share.mangaTitle,
        muId: share.mangaMuId,
        title: l10n.pushNotifShareTitle,
        body: l10n.pushNotifShareBody(share.senderUsername, share.mangaTitle),
      );
    }
  }

  /// Textes des notifications dans la langue choisie par l'utilisateur
  /// (pas de `BuildContext` ici).
  static AppLocalizations _localizations() {
    try {
      return lookupAppLocalizations(getIt<LanguageService>().getCurrentLocale());
    } catch (_) {
      return lookupAppLocalizations(const Locale('fr'));
    }
  }

  void dispose() {
    stop();
    _controller.close();
  }
}
