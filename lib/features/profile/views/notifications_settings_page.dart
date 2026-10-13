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
/// Un interrupteur par famille ([NotificationFamily]) : nouveaux chapitres,
/// demandes d'ami, demandes acceptées, recommandations reçues, lectures
/// partagées.
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

  /// État de chaque interrupteur ; absent tant que la lecture n'est pas
  /// faite (affiché activé, la valeur par défaut).
  final Map<NotificationFamily, bool> _enabled = {};

  @override
  void initState() {
    super.initState();
    _loadAll();
  }

  Future<void> _loadAll() async {
    final values = await Future.wait([
      for (final family in NotificationFamily.values) _prefs.isEnabled(family),
    ]);
    if (!mounted) return;
    setState(() {
      for (var i = 0; i < NotificationFamily.values.length; i++) {
        _enabled[NotificationFamily.values[i]] = values[i];
      }
    });
  }

  Future<void> _toggle(NotificationFamily family, bool v) async {
    await _prefs.setEnabled(family, v);
    if (!mounted) return;
    setState(() => _enabled[family] = v);
    if (family != NotificationFamily.newChapters) return;
    final l10n = AppLocalizations.of(context)!;
    _notifier.success(v
        ? l10n.newChapterNotificationsEnabled
        : l10n.newChapterNotificationsDisabled);
  }

  /// Une ligne par famille, dans l'ordre d'affichage.
  List<_NotifToggleRow> _rows(AppLocalizations l10n) {
    _NotifToggleRow row(NotificationFamily family, IconData icon,
            PastelTileColor color, String title, String subtitle) =>
        _NotifToggleRow(
          icon: icon,
          color: color,
          title: title,
          subtitle: subtitle,
          value: _enabled[family] ?? true,
          onChanged: (v) => _toggle(family, v),
        );
    return [
      row(NotificationFamily.newChapters, Icons.menu_book_outlined,
          PastelTileColor.blue, l10n.notifNewChaptersTitle,
          l10n.notifNewChaptersSubtitle),
      row(NotificationFamily.friendRequests, Icons.people_outline,
          PastelTileColor.purple, l10n.notifFriendReqTitle,
          l10n.notifFriendReqSubtitle),
      row(NotificationFamily.friendAccepted, Icons.how_to_reg_outlined,
          PastelTileColor.teal, l10n.notifFriendAcceptedTitle,
          l10n.notifFriendAcceptedSubtitle),
      row(NotificationFamily.sharesReceived, Icons.inbox_outlined,
          PastelTileColor.pink, l10n.notifSharesTitle,
          l10n.notifSharesSubtitle),
      row(NotificationFamily.readingGroups, Icons.groups_outlined,
          PastelTileColor.green, l10n.notifReadingGroupsTitle,
          l10n.notifReadingGroupsSubtitle),
    ];
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
                    children: _rows(l10n),
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
