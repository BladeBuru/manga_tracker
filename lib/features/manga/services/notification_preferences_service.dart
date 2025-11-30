import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Service pour gérer les préférences de notifications
class NotificationPreferencesService {
  static const String _prefsKeyNewChapterNotifications = 'new_chapter_notifications_enabled';

  /// Vérifie si les notifications pour les nouveaux chapitres sont activées
  Future<bool> areNewChapterNotificationsEnabled() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      // Par défaut, les notifications sont activées
      return prefs.getBool(_prefsKeyNewChapterNotifications) ?? true;
    } catch (e) {
      debugPrint('❌ NotificationPreferencesService: Erreur areNewChapterNotificationsEnabled: $e');
      return true; // Par défaut activé en cas d'erreur
    }
  }

  /// Active ou désactive les notifications pour les nouveaux chapitres
  Future<void> setNewChapterNotificationsEnabled(bool enabled) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool(_prefsKeyNewChapterNotifications, enabled);
      debugPrint('✅ NotificationPreferencesService: Notifications ${enabled ? "activées" : "désactivées"}');
    } catch (e) {
      debugPrint('❌ NotificationPreferencesService: Erreur setNewChapterNotificationsEnabled: $e');
    }
  }
}

