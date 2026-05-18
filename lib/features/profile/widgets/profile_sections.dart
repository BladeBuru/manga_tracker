import 'package:flutter/material.dart';

import 'package:mangatracker/core/components/pastel_tile.dart';
import 'package:mangatracker/features/auth/services/biometric.service.dart';
import 'package:mangatracker/features/profile/widgets/profile_edit_sections.dart';
import 'package:mangatracker/features/profile/widgets/profile_menu_row.dart';
import 'package:mangatracker/l10n/app_localizations.dart';

// ╔═══════════════════════════════════════════════════════════════════════╗
// ║  Sections de la page « Mon compte ».                                  ║
// ║  Chaque section = un `ProfileEditSection` + ses `ProfileMenuRow`.     ║
// ║  Découpé en sous-widgets pour respecter les limites CLAUDE.md         ║
// ║  (150 lignes par widget, 400 lignes par fichier).                     ║
// ╚═══════════════════════════════════════════════════════════════════════╝

class AccountSection extends StatelessWidget {
  final VoidCallback onChangePassword;

  const AccountSection({
    super.key,
    required this.onChangePassword,
  });

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    // Note 2026-05-18 : "Informations du compte" retiré sur demande utilisateur
    // — l'email/username sont déjà visibles dans le header + page "Modifier le
    // profil". Ne reste que le changement de mot de passe ici.
    return ProfileEditSection(label: l10n.account, children: [
      ProfileMenuRow(
        leading: const PastelTile(
            icon: Icons.lock_outline, color: PastelTileColor.yellow),
        title: l10n.changePassword,
        subtitle: l10n.changePasswordSubtitle,
        onTap: onChangePassword,
      ),
    ]);
  }
}

class ProfileSocialSection extends StatelessWidget {
  final VoidCallback onEditProfile;
  final VoidCallback onMyStats;
  final VoidCallback onMyFriends;
  final VoidCallback onMyInbox;
  final VoidCallback onReadingGroups;

  const ProfileSocialSection({
    super.key,
    required this.onEditProfile,
    required this.onMyStats,
    required this.onMyFriends,
    required this.onMyInbox,
    required this.onReadingGroups,
  });

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return ProfileEditSection(label: l10n.profile, children: [
      ProfileMenuRow(
        leading: const PastelTile(
            icon: Icons.edit_outlined, color: PastelTileColor.teal),
        title: l10n.profileEditMenuTitle,
        subtitle: l10n.profileEditMenuSubtitle,
        onTap: onEditProfile,
      ),
      ProfileMenuRow(
        leading: const PastelTile(
            icon: Icons.bar_chart_outlined, color: PastelTileColor.green),
        title: l10n.profileMyStats,
        onTap: onMyStats,
      ),
      ProfileMenuRow(
        leading: const PastelTile(
            icon: Icons.people_outline, color: PastelTileColor.purple),
        title: l10n.profileMyFriends,
        onTap: onMyFriends,
      ),
      ProfileMenuRow(
        leading: const PastelTile(
            icon: Icons.inbox_outlined, color: PastelTileColor.pink),
        title: l10n.profileMyInbox,
        onTap: onMyInbox,
      ),
      ProfileMenuRow(
        leading: const PastelTile(
            icon: Icons.groups_outlined, color: PastelTileColor.blue),
        title: l10n.profileMyReadingGroups,
        onTap: onReadingGroups,
      ),
    ]);
  }
}

class SettingsSection extends StatelessWidget {
  final String languageName;
  final String themeName;
  final bool? biometricEnabled;
  final BiometricService biometricService;
  final VoidCallback onPickLanguage;
  final VoidCallback onNotifications;
  final VoidCallback onPickTheme;
  final VoidCallback onToggleBiometric;

  const SettingsSection({
    super.key,
    required this.languageName,
    required this.themeName,
    required this.biometricEnabled,
    required this.biometricService,
    required this.onPickLanguage,
    required this.onNotifications,
    required this.onPickTheme,
    required this.onToggleBiometric,
  });

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return ProfileEditSection(label: l10n.settings, children: [
      ProfileMenuRow(
        leading: const PastelTile(
            icon: Icons.language_outlined, color: PastelTileColor.blue),
        title: l10n.language,
        subtitle: languageName,
        onTap: onPickLanguage,
      ),
      ProfileMenuRow(
        leading: const PastelTile(
            icon: Icons.notifications_outlined, color: PastelTileColor.blue),
        title: l10n.notifications,
        subtitle: l10n.manageNotifications,
        onTap: onNotifications,
      ),
      ProfileMenuRow(
        leading: const PastelTile(
            icon: Icons.dark_mode_outlined, color: PastelTileColor.purple),
        title: l10n.theme,
        subtitle: themeName,
        onTap: onPickTheme,
      ),
      _BiometricRow(
        biometricEnabled: biometricEnabled,
        biometricService: biometricService,
        onToggle: onToggleBiometric,
      ),
    ]);
  }
}

class ActionsSection extends StatelessWidget {
  final VoidCallback onMyData;
  final VoidCallback onLogout;
  final VoidCallback onDeleteAccount;

  const ActionsSection({
    super.key,
    required this.onMyData,
    required this.onLogout,
    required this.onDeleteAccount,
  });

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return ProfileEditSection(label: l10n.actions, children: [
      ProfileMenuRow(
        leading: const PastelTile(
            icon: Icons.shield_outlined, color: PastelTileColor.teal),
        title: l10n.myDataTitle,
        subtitle: l10n.myDataSubtitle,
        onTap: onMyData,
      ),
      ProfileMenuRow(
        leading: const PastelTile(
            icon: Icons.logout_outlined, color: PastelTileColor.red),
        title: l10n.logout,
        subtitle: l10n.logoutSubtitle,
        onTap: onLogout,
      ),
      ProfileMenuRow(
        leading: const PastelTile(
            icon: Icons.delete_outline, color: PastelTileColor.red),
        title: l10n.deleteAccount,
        subtitle: l10n.deleteAccountSubtitle,
        danger: true,
        onTap: onDeleteAccount,
      ),
    ]);
  }
}

class ContactSection extends StatelessWidget {
  final VoidCallback onOpenDiscord;
  const ContactSection({super.key, required this.onOpenDiscord});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return ProfileEditSection(label: l10n.contactUs, children: [
      ProfileMenuRow(
        leading: const PastelTile(
            icon: Icons.chat_bubble_outline, color: PastelTileColor.purple),
        title: l10n.joinDiscord,
        subtitle: l10n.joinDiscordSubtitle,
        onTap: onOpenDiscord,
      ),
    ]);
  }
}

class DownloadsSection extends StatelessWidget {
  final VoidCallback onDownloads;
  const DownloadsSection({super.key, required this.onDownloads});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return ProfileEditSection(label: l10n.downloads, children: [
      ProfileMenuRow(
        leading: const PastelTile(
            icon: Icons.download_outlined, color: PastelTileColor.red),
        title: l10n.manageDownloads,
        subtitle: l10n.manageDownloadsSubtitle,
        onTap: onDownloads,
      ),
    ]);
  }
}

class SelectorsSection extends StatelessWidget {
  final VoidCallback onCustomSelectors;
  const SelectorsSection({super.key, required this.onCustomSelectors});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return ProfileEditSection(label: l10n.customSelectors, children: [
      ProfileMenuRow(
        leading: const PastelTile(
            icon: Icons.code, color: PastelTileColor.purple),
        title: l10n.manageCustomSelectors,
        subtitle: l10n.manageCustomSelectorsSubtitle,
        onTap: onCustomSelectors,
      ),
    ]);
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// _BiometricRow — wrap `FutureBuilder<bool>` (support biométrique) pour ne
// pas alourdir `SettingsSection`.
// ─────────────────────────────────────────────────────────────────────────────

class _BiometricRow extends StatelessWidget {
  final bool? biometricEnabled;
  final BiometricService biometricService;
  final VoidCallback onToggle;

  const _BiometricRow({
    required this.biometricEnabled,
    required this.biometricService,
    required this.onToggle,
  });

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return FutureBuilder<bool>(
      future: biometricService.hasBiometricSupport(),
      builder: (context, snapshot) {
        if (snapshot.connectionState != ConnectionState.done) {
          return const SizedBox.shrink();
        }
        if (snapshot.data != true) return const SizedBox.shrink();
        return ProfileMenuRow(
          leading: const PastelTile(
              icon: Icons.fingerprint, color: PastelTileColor.purple),
          title: l10n.biometricAuthTitle,
          subtitle: biometricEnabled == true
              ? l10n.biometricAuthEnabled
              : l10n.biometricAuthDisabled,
          onTap: onToggle,
          trailing: Switch(
            value: biometricEnabled ?? false,
            onChanged: (_) => onToggle(),
          ),
        );
      },
    );
  }
}
