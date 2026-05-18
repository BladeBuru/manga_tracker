import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Service pour gérer les préférences de notifications locales.
///
/// Trois familles de notifs gérées indépendamment :
///  - Nouveaux chapitres (`new_chapter_notifications_enabled`).
///  - Demandes d'ami (`notifications_friend_requests_enabled`).
///  - Recommandations / partages reçus (`notifications_shares_received_enabled`).
///
/// Toutes les préférences sont activées par défaut (true).
class NotificationPreferencesService {
  static const String _prefsKeyNewChapterNotifications =
      'new_chapter_notifications_enabled';
  static const String _prefsKeyFriendRequestNotifications =
      'notifications_friend_requests_enabled';
  static const String _prefsKeyShareReceivedNotifications =
      'notifications_shares_received_enabled';

  // ─── Nouveaux chapitres ───

  /// Vérifie si les notifications pour les nouveaux chapitres sont activées.
  Future<bool> areNewChapterNotificationsEnabled() async {
    return _read(_prefsKeyNewChapterNotifications);
  }

  /// Active ou désactive les notifications pour les nouveaux chapitres.
  Future<void> setNewChapterNotificationsEnabled(bool enabled) async {
    await _write(_prefsKeyNewChapterNotifications, enabled);
  }

  // ─── Demandes d'ami ───

  /// Vérifie si les notifications pour les demandes d'ami sont activées.
  Future<bool> areFriendRequestNotificationsEnabled() async {
    return _read(_prefsKeyFriendRequestNotifications);
  }

  /// Active ou désactive les notifications pour les demandes d'ami.
  Future<void> setFriendRequestNotificationsEnabled(bool enabled) async {
    await _write(_prefsKeyFriendRequestNotifications, enabled);
  }

  // ─── Partages reçus / recommandations ───

  /// Vérifie si les notifications pour les recommandations reçues sont activées.
  Future<bool> areShareReceivedNotificationsEnabled() async {
    return _read(_prefsKeyShareReceivedNotifications);
  }

  /// Active ou désactive les notifications pour les recommandations reçues.
  Future<void> setShareReceivedNotificationsEnabled(bool enabled) async {
    await _write(_prefsKeyShareReceivedNotifications, enabled);
  }

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
