import 'package:flutter/material.dart';
import 'package:mangatracker/l10n/app_localizations.dart';
import 'package:mangatracker/features/manga/services/notification_preferences_service.dart';
import 'package:mangatracker/core/notifier/notifier.dart';
import 'package:mangatracker/core/service_locator/service_locator.dart';

/// Page de gestion des notifications
class NotificationsSettingsPage extends StatefulWidget {
  const NotificationsSettingsPage({super.key});

  @override
  State<NotificationsSettingsPage> createState() => _NotificationsSettingsPageState();
}

class _NotificationsSettingsPageState extends State<NotificationsSettingsPage> {
  final NotificationPreferencesService _notificationPreferences = NotificationPreferencesService();
  final Notifier _notifier = getIt<Notifier>();
  bool? _newChapterNotificationsEnabled;

  @override
  void initState() {
    super.initState();
    _loadNotificationPreferences();
  }

  Future<void> _loadNotificationPreferences() async {
    final isEnabled = await _notificationPreferences.areNewChapterNotificationsEnabled();
    if (mounted) {
      setState(() {
        _newChapterNotificationsEnabled = isEnabled;
      });
    }
  }

  Future<void> _handleNotificationToggle() async {
    final currentStatus = _newChapterNotificationsEnabled ?? true;
    await _notificationPreferences.setNewChapterNotificationsEnabled(!currentStatus);
    if (mounted) {
      setState(() {
        _newChapterNotificationsEnabled = !currentStatus;
      });
      final l10n = AppLocalizations.of(context)!;
      _notifier.success(
        !currentStatus 
          ? l10n.newChapterNotificationsEnabled
          : l10n.newChapterNotificationsDisabled
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return Scaffold(
      appBar: AppBar(
        title: Text(l10n.notifications),
      ),
      body: ListView(
        children: [
          ListTile(
            leading: const Icon(Icons.new_releases, color: Colors.orange),
            title: Text(l10n.newChapterNotifications),
            subtitle: Text(
              _newChapterNotificationsEnabled == true
                  ? l10n.newChapterNotificationsEnabled
                  : l10n.newChapterNotificationsDisabled,
            ),
            trailing: Switch(
              value: _newChapterNotificationsEnabled ?? true,
              onChanged: (value) async {
                await _handleNotificationToggle();
              },
            ),
          ),
        ],
      ),
    );
  }
}

