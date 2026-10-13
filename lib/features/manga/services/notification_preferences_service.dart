import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Familles de notifications locales, chacune avec son interrupteur dans
/// « Notifications » (réglages du profil).
enum NotificationFamily {
  newChapters('new_chapter_notifications_enabled'),
  friendRequests('notifications_friend_requests_enabled'),
  friendAccepted('notifications_friend_accepted_enabled'),
  sharesReceived('notifications_shares_received_enabled'),
  readingGroups('notifications_reading_groups_enabled');

  /// Clé `SharedPreferences` (les trois premières existaient déjà : ne pas
  /// les renommer, les choix des utilisateurs y sont stockés).
  final String prefsKey;
  const NotificationFamily(this.prefsKey);
}

/// Service pour gérer les préférences de notifications locales.
///
/// Cinq familles gérées indépendamment ([NotificationFamily]) : nouveaux
/// chapitres, demandes d'ami, demandes acceptées, recommandations reçues,
/// lectures partagées. Toutes activées par défaut.
class NotificationPreferencesService {
  /// Vérifie si une famille de notifications est activée.
  Future<bool> isEnabled(NotificationFamily family) => _read(family.prefsKey);

  /// Active ou désactive une famille de notifications.
  Future<void> setEnabled(NotificationFamily family, bool enabled) =>
      _write(family.prefsKey, enabled);

  // ─── Accès historiques (conservés pour les appelants existants) ───

  Future<bool> areNewChapterNotificationsEnabled() =>
      isEnabled(NotificationFamily.newChapters);

  Future<void> setNewChapterNotificationsEnabled(bool enabled) =>
      setEnabled(NotificationFamily.newChapters, enabled);

  Future<bool> areFriendRequestNotificationsEnabled() =>
      isEnabled(NotificationFamily.friendRequests);

  Future<void> setFriendRequestNotificationsEnabled(bool enabled) =>
      setEnabled(NotificationFamily.friendRequests, enabled);

  Future<bool> areShareReceivedNotificationsEnabled() =>
      isEnabled(NotificationFamily.sharesReceived);

  Future<void> setShareReceivedNotificationsEnabled(bool enabled) =>
      setEnabled(NotificationFamily.sharesReceived, enabled);

  // ─── Helpers internes ───

  Future<bool> _read(String key) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      return prefs.getBool(key) ?? true; // Par défaut activé
    } catch (e) {
      debugPrint(
        '❌ NotificationPreferencesService: Erreur lecture $key: $e',
      );
      return true;
    }
  }

  Future<void> _write(String key, bool value) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool(key, value);
      debugPrint(
        '✅ NotificationPreferencesService: $key = $value',
      );
    } catch (e) {
      debugPrint(
        '❌ NotificationPreferencesService: Erreur écriture $key: $e',
      );
    }
  }
}
