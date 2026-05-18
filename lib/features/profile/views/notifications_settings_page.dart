import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:mangatracker/core/components/pastel_tile.dart';
import 'package:mangatracker/core/notifier/notifier.dart';
import 'package:mangatracker/core/service_locator/service_locator.dart';
import 'package:mangatracker/core/theme/app_colors.dart';
import 'package:mangatracker/core/theme/app_spacing.dart';
import 'package:mangatracker/features/manga/services/notification_preferences_service.dart';
import 'package:mangatracker/features/profile/widgets/profile_edit_sections.dart';
import 'package:mangatracker/l10n/app_localizations.dart';

/// Page de gestion des notifications — Design System V1 « Refined Classic ».
///
/// Trois toggles indépendants :
///  - Nouveaux chapitres (existant, ne pas casser).
///  - Demandes d'ami (nouveau).
///  - Recommandations reçues / partages (nouveau).
///
/// Plus une carte d'info expliquant la permission système.
class NotificationsSettingsPage extends StatefulWidget {
  const NotificationsSettingsPage({super.key});

  @override
  State<NotificationsSettingsPage> createState() =>
      _NotificationsSettingsPageState();
}

class _NotificationsSettingsPageState extends State<NotificationsSettingsPage> {
  final NotificationPreferencesService _prefs =
      NotificationPreferencesService();
  final Notifier _notifier = getIt<Notifier>();

  bool? _newChapters;
  bool? _friendRequests;
  bool? _sharesReceived;

  @override
  void initState() {
    super.initState();
    _loadAll();
  }

  Future<void> _loadAll() async {
    final results = await Future.wait([
      _prefs.areNewChapterNotificationsEnabled(),
      _prefs.areFriendRequestNotificationsEnabled(),
      _prefs.areShareReceivedNotificationsEnabled(),
    ]);
    if (!mounted) return;
    setState(() {
      _newChapters = results[0];
      _friendRequests = results[1];
      _sharesReceived = results[2];
    });
  }

  Future<void> _toggleNewChapters(bool v) async {
    await _prefs.setNewChapterNotificationsEnabled(v);
    if (!mounted) return;
    setState(() => _newChapters = v);
    final l10n = AppLocalizations.of(context)!;
    _notifier.success(v
        ? l10n.newChapterNotificationsEnabled
        : l10n.newChapterNotificationsDisabled);
  }

  Future<void> _toggleFriendReq(bool v) async {
    await _prefs.setFriendRequestNotificationsEnabled(v);
    if (mounted) setState(() => _friendRequests = v);
  }

  Future<void> _toggleShares(bool v) async {
    await _prefs.setShareReceivedNotificationsEnabled(v);
    if (mounted) setState(() => _sharesReceived = v);
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final brightness = Theme.of(context).brightness;
    final scheme = Theme.of(context).colorScheme;
    final bg = brightness == Brightness.dark
        ? AppColors.dsBgDark
        : AppColors.dsBgLight;
    return Scaffold(
      backgroundColor: bg,
      appBar: AppBar(
        backgroundColor: bg,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        scrolledUnderElevation: 0,
        shape: Border(
          bottom: BorderSide(
            color: AppColors.dsHairline(brightness),
            width: 1,
          ),
        ),
        title: Text(
          l10n.notifications,
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w700,
            color: scheme.onSurface,
          ),
        ),
        centerTitle: true,
        leading: IconButton(
          icon: Icon(Icons.chevron_left, color: scheme.primary, size: 24),
          onPressed: () => context.pop(),
        ),
      ),
      body: LayoutBuilder(
        builder: (context, constraints) {
          final hPad = constraints.maxWidth >= 600 ? 32.0 : 16.0;
          return Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 560),
              child: ListView(
                padding: EdgeInsets.fromLTRB(hPad, AppSpacing.m, hPad, AppSpacing.l),
                children: [
                  ProfileEditSection(
                    label: l10n.notifSectionApp,
                    children: [
                      _NotifToggleRow(
                        icon: Icons.menu_book_outlined,
                        color: PastelTileColor.blue,
                        title: l10n.notifNewChaptersTitle,
                        subtitle: l10n.notifNewChaptersSubtitle,
                        value: _newChapters ?? true,
                        onChanged: _toggleNewChapters,
                      ),
                      _NotifToggleRow(
                        icon: Icons.people_outline,
                        color: PastelTileColor.purple,
                        title: l10n.notifFriendReqTitle,
                        subtitle: l10n.notifFriendReqSubtitle,
                        value: _friendRequests ?? true,
                        onChanged: _toggleFriendReq,
                      ),
                      _NotifToggleRow(
                        icon: Icons.inbox_outlined,
                        color: PastelTileColor.pink,
                        title: l10n.notifSharesTitle,
                        subtitle: l10n.notifSharesSubtitle,
                        value: _sharesReceived ?? true,
                        onChanged: _toggleShares,
                      ),
                    ],
                  ),
                  const SizedBox(height: AppSpacing.l),
                  ProfileEditSection(
                    label: l10n.notifSectionInfo,
                    children: const [_NotifPermissionInfoRow()],
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}

/// Row de toggle : PastelTile + titre + sous-titre + Switch.
/// Toute la row est cliquable pour toggler le switch (UX V1).
class _NotifToggleRow extends StatelessWidget {
  final IconData icon;
  final PastelTileColor color;
  final String title;
  final String subtitle;
  final bool value;
  final ValueChanged<bool> onChanged;

  const _NotifToggleRow({
    required this.icon,
    required this.color,
    required this.title,
    required this.subtitle,
    required this.value,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    final brightness = Theme.of(context).brightness;
    final scheme = Theme.of(context).colorScheme;
    return InkWell(
      onTap: () => onChanged(!value),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 14, 16, 14),
        child: Row(
          children: [
            PastelTile(icon: icon, color: color),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w600,
                      color: scheme.onSurface,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    subtitle,
                    style: TextStyle(
                      fontSize: 12.5,
                      height: 1.35,
                      color: AppColors.dsText2(brightness),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 12),
            Switch(value: value, onChanged: onChanged),
          ],
        ),
      ),
    );
  }
}

/// Carte d'info expliquant la permission système + bouton vers les réglages.
class _NotifPermissionInfoRow extends StatelessWidget {
  const _NotifPermissionInfoRow();

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final brightness = Theme.of(context).brightness;
    final scheme = Theme.of(context).colorScheme;
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 14, 16, 14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                Icons.info_outline,
                size: 18,
                color: AppColors.dsText2(brightness),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  l10n.notifPermissionExplanation,
                  style: TextStyle(
                    fontSize: 12.5,
                    height: 1.4,
                    color: AppColors.dsText2(brightness),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Align(
            alignment: Alignment.centerLeft,
            child: TextButton.icon(
              onPressed: openAppSettings,
              icon: Icon(Icons.open_in_new, size: 16, color: scheme.primary),
              label: Text(
                l10n.notifOpenSystemSettings,
                style: TextStyle(
                  fontSize: 13.5,
                  fontWeight: FontWeight.w600,
                  color: scheme.primary,
                ),
              ),
              style: TextButton.styleFrom(
                padding: const EdgeInsets.symmetric(
                    horizontal: 8, vertical: 4),
                minimumSize: const Size(0, 32),
                tapTargetSize: MaterialTapTargetSize.shrinkWrap,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
