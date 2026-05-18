import 'package:flutter/material.dart';
import 'package:package_info_plus/package_info_plus.dart';

import 'package:mangatracker/core/service_locator/service_locator.dart';
import 'package:mangatracker/core/services/language_service.dart';
import 'package:mangatracker/core/services/theme_service.dart';
import 'package:mangatracker/core/theme/app_colors.dart';
import 'package:mangatracker/features/auth/services/biometric.service.dart';
import 'package:mangatracker/features/profile/widgets/profile_dialogs.dart';
import 'package:mangatracker/features/profile/widgets/profile_header.dart';
import 'package:mangatracker/features/profile/widgets/profile_highlight_card.dart';
import 'package:mangatracker/features/profile/widgets/profile_sections.dart';
import 'package:mangatracker/l10n/app_localizations.dart';

// ╔═══════════════════════════════════════════════════════════════════════╗
// ║  ProfileBody — corps scrollable de la page « Mon compte ».           ║
// ║  Header + ProfileHighlightCard + sections + footer. Découpé de       ║
// ║  `profile.dart` pour respecter la limite 400 lignes / fichier        ║
// ║  (CLAUDE.md). Chaque section vit dans `profile_sections.dart`.       ║
// ╚═══════════════════════════════════════════════════════════════════════╝

class ProfileBody extends StatelessWidget {
  final String username;
  final String email;
  final String? avatarUrl;
  final Locale? currentLocale;
  final ThemeMode? currentThemeMode;
  final bool? biometricEnabled;
  final BiometricService biometricService;

  final VoidCallback onAvatarTap;
  final VoidCallback onChangePassword;
  final VoidCallback onEditProfile;
  final VoidCallback onMyStats;
  final VoidCallback onMyFriends;
  final VoidCallback onMyInbox;
  final VoidCallback onReadingGroups;
  final VoidCallback onPickLanguage;
  final VoidCallback onNotifications;
  final VoidCallback onPickTheme;
  final VoidCallback onToggleBiometric;
  final VoidCallback onMyData;
  final VoidCallback onLogout;
  final VoidCallback onDeleteAccount;
  final VoidCallback onOpenDiscord;
  final VoidCallback onDownloads;
  final VoidCallback onCustomSelectors;

  const ProfileBody({
    super.key,
    required this.username,
    required this.email,
    required this.avatarUrl,
    required this.currentLocale,
    required this.currentThemeMode,
    required this.biometricEnabled,
    required this.biometricService,
    required this.onAvatarTap,
    required this.onChangePassword,
    required this.onEditProfile,
    required this.onMyStats,
    required this.onMyFriends,
    required this.onMyInbox,
    required this.onReadingGroups,
    required this.onPickLanguage,
    required this.onNotifications,
    required this.onPickTheme,
    required this.onToggleBiometric,
    required this.onMyData,
    required this.onLogout,
    required this.onDeleteAccount,
    required this.onOpenDiscord,
    required this.onDownloads,
    required this.onCustomSelectors,
  });

  @override
  Widget build(BuildContext context) {
    final languageService = getIt<LanguageService>();
    final effectiveLocale = currentLocale ?? languageService.getCurrentLocale();
    final languageName =
        languageService.getLanguageName(effectiveLocale, context);
    final themeService = getIt<ThemeService>();
    final effectiveThemeMode =
        currentThemeMode ?? themeService.getCurrentThemeMode();
    final themeName = ProfileDialogs.themeModeName(effectiveThemeMode, context);

    return CustomScrollView(
      slivers: [
        SliverToBoxAdapter(
          child: ProfileHeader(
            username: username,
            email: email,
            avatarUrl: avatarUrl,
            onAvatarTap: onAvatarTap,
          ),
        ),
        const SliverPadding(
          padding: EdgeInsets.fromLTRB(16, 0, 16, 18),
          sliver: SliverToBoxAdapter(child: ProfileHighlightCard()),
        ),
        SliverPadding(
          padding: const EdgeInsets.fromLTRB(16, 0, 16, 24),
          sliver: SliverList(
            delegate: SliverChildListDelegate([
              AccountSection(
                onChangePassword: onChangePassword,
              ),
              const SizedBox(height: 22),
              ProfileSocialSection(
                onEditProfile: onEditProfile,
                onMyStats: onMyStats,
                onMyFriends: onMyFriends,
                onMyInbox: onMyInbox,
                onReadingGroups: onReadingGroups,
              ),
              const SizedBox(height: 22),
              SettingsSection(
                languageName: languageName,
                themeName: themeName,
                biometricEnabled: biometricEnabled,
                biometricService: biometricService,
                onPickLanguage: onPickLanguage,
                onNotifications: onNotifications,
                onPickTheme: onPickTheme,
                onToggleBiometric: onToggleBiometric,
              ),
              const SizedBox(height: 22),
              ActionsSection(
                onMyData: onMyData,
                onLogout: onLogout,
                onDeleteAccount: onDeleteAccount,
              ),
              const SizedBox(height: 22),
              ContactSection(onOpenDiscord: onOpenDiscord),
              const SizedBox(height: 22),
              DownloadsSection(onDownloads: onDownloads),
              const SizedBox(height: 22),
              SelectorsSection(onCustomSelectors: onCustomSelectors),
              const SizedBox(height: 16),
              const ProfileFooter(),
              const SizedBox(height: 24),
            ]),
          ),
        ),
      ],
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// ProfileFooter — petit footer mono « MANGA TRACKER · vX.Y.Z » centré.
// ─────────────────────────────────────────────────────────────────────────────

class ProfileFooter extends StatefulWidget {
  const ProfileFooter({super.key});

  @override
  State<ProfileFooter> createState() => _ProfileFooterState();
}

class _ProfileFooterState extends State<ProfileFooter> {
  String? _version;

  @override
  void initState() {
    super.initState();
    _loadVersion();
  }

  Future<void> _loadVersion() async {
    try {
      final info = await PackageInfo.fromPlatform();
      if (!mounted) return;
      setState(() => _version = info.version);
    } catch (_) {
      // Si on ne peut pas charger la version, on affiche juste la marque.
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final brightness = Theme.of(context).brightness;
    final brand = l10n.profileFooterBrand;
    final label = _version == null ? brand : '$brand · v$_version';

    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 8),
        child: Text(
          label,
          textAlign: TextAlign.center,
          style: TextStyle(
            fontFamily: 'JetBrainsMono',
            fontFeatures: const [FontFeature.tabularFigures()],
            fontSize: 11,
            letterSpacing: 0.44, // 0.04em * 11
            color: AppColors.dsText3(brightness),
          ),
        ),
      ),
    );
  }
}
