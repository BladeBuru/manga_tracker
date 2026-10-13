import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart' show Locale;
import 'package:mangatracker/core/service_locator/service_locator.dart';
import 'package:mangatracker/core/services/language_service.dart';
import 'package:mangatracker/features/friends/dto/friend.dto.dart';
import 'package:mangatracker/features/manga/services/notification_payload.dart';
import 'package:mangatracker/features/manga/services/notification_preferences_service.dart';
import 'package:mangatracker/features/manga/services/notification_service.dart';
import 'package:mangatracker/features/notifications/dto/app_notification.dto.dart';
import 'package:mangatracker/features/notifications/helpers/notification_presenter.dart';
import 'package:mangatracker/features/sharing/dto/share.dto.dart';
import 'package:mangatracker/l10n/app_localizations.dart';

/// Source observée par l'interrogation périodique.
enum AlertSource { feed, friendRequests, shares }

/// Notifications locales « il s'est passé quelque chose » — **un seul
/// chemin**, un seul registre anti-doublon.
///
/// Trois sources peuvent annoncer la même chose (le centre de notifications,
/// et, sur un serveur qui ne l'a pas encore, la boîte de réception et les
/// demandes en attente). Toutes passent par une clé commune
/// ([NotificationPresenter.dedupeKey]) : une demande d'ami ou une
/// recommandation ne sonne qu'une fois, quelle que soit la source qui l'a vue
/// la première.
///
/// **Premier regard silencieux, par source** : ce qui existe déjà quand une
/// source répond pour la première fois est mémorisé sans notifier (sinon
/// chaque démarrage renotifierait tout l'historique). Ce silence ne vaut
/// QUE pour ce premier regard — l'ancien `FriendsBloc` gardait un compteur
/// remis à « jamais chargé » à chaque ouverture de la page Amis, si bien que
/// les demandes d'ami ne notifiaient jamais.
class NotificationAlerter {
  /// Au-delà, on n'empile plus : le centre de notifications suffit.
  static const int maxAlertsPerPass = 5;

  final NotificationService _notifications;
  final NotificationPreferencesService _preferences;
  final AppLocalizations Function() _l10n;

  final Set<String> _alerted = <String>{};
  final Set<AlertSource> _seen = <AlertSource>{};

  NotificationAlerter({
    NotificationService? notifications,
    NotificationPreferencesService? preferences,
    AppLocalizations Function()? localizations,
  })  : _notifications = notifications ?? NotificationService(),
        _preferences = preferences ?? NotificationPreferencesService(),
        _l10n = localizations ?? _appLocalizations;

  /// La source a-t-elle déjà été regardée une fois (référence posée) ?
  bool hasBaseline(AlertSource source) => _seen.contains(source);

  /// Oublie tout (déconnexion, changement de compte).
  void reset() {
    _alerted.clear();
    _seen.clear();
  }

  /// Lignes les plus récentes du centre de notifications.
  Future<int> onFeedItems(List<AppNotificationDto> items) {
    final unread = items.where((n) => n.isUnread).toList();
    return _process(
      AlertSource.feed,
      [for (final n in unread) _Alert.fromFeed(n)],
    );
  }

  /// Demandes d'ami en attente (serveur sans centre de notifications).
  Future<int> onPendingRequests(List<FriendshipDto> pending) {
    final received = pending.where((p) =>
        p.direction == FriendshipDirection.received &&
        p.status == FriendshipStatus.pending);
    return _process(
      AlertSource.friendRequests,
      [for (final p in received) _Alert.fromFriendRequest(p)],
    );
  }

  /// Recommandations non vues (serveur sans centre de notifications).
  Future<int> onUnseenShares(List<MangaShareDto> unseen) {
    return _process(
      AlertSource.shares,
      [for (final s in unseen.where((s) => s.isNew)) _Alert.fromShare(s)],
    );
  }

  Future<int> _process(AlertSource source, List<_Alert> candidates) async {
    // Section synchrone : vérification ET inscription au registre avant le
    // moindre `await`, pour que deux passes concurrentes ne notifient pas
    // deux fois la même chose.
    if (!_seen.contains(source)) {
      _seen.add(source);
      _alerted.addAll(candidates.map((a) => a.key));
      return 0;
    }
    final fresh = <_Alert>[];
    for (final alert in candidates) {
      if (_alerted.add(alert.key)) fresh.add(alert);
    }
    if (fresh.isEmpty) return 0;
    final l10n = _l10n();
    // Interrupteurs des réglages : une famille coupée ne sonne pas (et ne
    // sonnera pas en rattrapage quand elle sera rallumée — déjà inscrite).
    final allowed = <_Alert>[];
    for (final alert in fresh) {
      if (await _preferences.isEnabled(alert.family)) allowed.add(alert);
    }
    final shown = allowed.take(maxAlertsPerPass).toList().reversed;
    for (final alert in shown) {
      try {
        await _notifications.showFamilyNotification(
          family: alert.family,
          key: alert.key,
          title: alert.title(l10n),
          body: alert.body(l10n),
          payload: alert.payload,
          muId: alert.muId,
        );
      } catch (e) {
        debugPrint('NotificationAlerter: affichage impossible ($e)');
      }
    }
    return shown.length;
  }

  /// Textes dans la langue choisie par l'utilisateur (pas de `BuildContext`).
  static AppLocalizations _appLocalizations() {
    try {
      return lookupAppLocalizations(getIt<LanguageService>().getCurrentLocale());
    } catch (_) {
      return lookupAppLocalizations(const Locale('fr'));
    }
  }
}

/// Une annonce possible, indépendante de sa source.
class _Alert {
  final String key;
  final NotificationFamily family;
  final String Function(AppLocalizations) title;
  final String Function(AppLocalizations) body;
  final String? payload;
  final int? muId;

  const _Alert({
    required this.key,
    required this.family,
    required this.title,
    required this.body,
    this.payload,
    this.muId,
  });

  factory _Alert.fromFeed(AppNotificationDto n) => _Alert(
        key: NotificationPresenter.dedupeKey(n),
        family: _familyOf(n.type),
        title: (l10n) => NotificationPresenter.pushTitle(n, l10n),
        body: (l10n) => NotificationPresenter.text(n, l10n),
        payload: NotificationPresenter.payload(n),
        muId: n.manga?.muId,
      );

  factory _Alert.fromFriendRequest(FriendshipDto p) => _Alert(
        key: NotificationPresenter.friendshipKey(p.id),
        family: NotificationFamily.friendRequests,
        title: (l10n) => l10n.pushNotifFriendRequestTitle,
        body: (l10n) => l10n.pushNotifFriendRequestBody(p.displayName),
        payload: NotificationPayload.friendRequest,
      );

  factory _Alert.fromShare(MangaShareDto s) => _Alert(
        key: NotificationPresenter.shareKey(s.id),
        family: NotificationFamily.sharesReceived,
        title: (l10n) => l10n.pushNotifShareTitle,
        body: (l10n) => l10n.pushNotifShareBody(s.senderUsername, s.mangaTitle),
        payload: NotificationPayload.share(s.mangaMuId),
      );

  static NotificationFamily _familyOf(AppNotificationType type) {
    switch (type) {
      case AppNotificationType.friendRequest:
        return NotificationFamily.friendRequests;
      case AppNotificationType.friendAccepted:
        return NotificationFamily.friendAccepted;
      case AppNotificationType.mangaShare:
        return NotificationFamily.sharesReceived;
      case AppNotificationType.readingGroupInvite:
        return NotificationFamily.readingGroups;
      case AppNotificationType.newChapters:
        return NotificationFamily.newChapters;
    }
  }
}
