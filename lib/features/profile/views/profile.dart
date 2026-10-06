import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:url_launcher/url_launcher.dart';

import 'package:mangatracker/core/bloc/notification_counts_cubit.dart';
import 'package:mangatracker/core/components/language_selector_button.dart';
import 'package:mangatracker/core/notifier/notifier.dart';
import 'package:mangatracker/core/service_locator/service_locator.dart';
import 'package:mangatracker/core/services/language_service.dart';
import 'package:mangatracker/core/services/notification_counts_service.dart';
import 'package:mangatracker/core/services/theme_service.dart';
import 'package:mangatracker/core/theme/app_breakpoints.dart';
import 'package:mangatracker/core/theme/app_colors.dart';
import 'package:mangatracker/features/auth/services/auth.service.dart';
import 'package:mangatracker/features/home/bloc/homepage_bloc.dart';
import 'package:mangatracker/features/home/bloc/homepage_event.dart';
import 'package:mangatracker/features/profile/dto/user_information.dto.dart';
import 'package:mangatracker/features/profile/services/user.service.dart';
import 'package:mangatracker/features/profile/widgets/profile_body.dart';
import 'package:mangatracker/features/profile/widgets/profile_dialogs.dart';
import 'package:mangatracker/l10n/app_localizations.dart';

// ╔═══════════════════════════════════════════════════════════════════════╗
// ║  Page « Mon compte » — Design System V1 « Refined Classic ».          ║
// ║  Source design : `.claude-design/manga-tracker/project/screen-       ║
// ║  account.jsx`. Toutes les actions métier (biométrie, thème, langue,   ║
// ║  logout, deletion, password change, RGPD, Discord, downloads,        ║
// ║  custom selectors) sont préservées depuis la version précédente.     ║
// ║                                                                       ║
// ║  Découpage : la state class porte uniquement les loaders/actions ;    ║
// ║  l'arbre visuel est dans `widgets/profile_body.dart`, les dialogs    ║
// ║  sont dans `widgets/profile_dialogs.dart` pour respecter la limite    ║
// ║  400 lignes / fichier (CLAUDE.md).                                    ║
// ╚═══════════════════════════════════════════════════════════════════════╝

class Profile extends StatefulWidget {
  /// Signal « amener l'utilisateur à ce qui l'attend » : émis quand il
  /// touche l'onglet « Mon compte » alors qu'une pastille y est affichée.
  final Listenable? focusPendingRequests;

  const Profile({super.key, this.focusPendingRequests});

  @override
  State<Profile> createState() => _ProfileState();
}

class _ProfileState extends State<Profile> {
  final AuthService _authService = getIt<AuthService>();
  final UserService _userService = getIt<UserService>();
  final Notifier _notifier = getIt<Notifier>();

  UserInformationDto? _userInfo;
  bool _isLoading = true;
  Locale? _currentLocale;
  bool? _biometricEnabled;
  ThemeMode? _currentThemeMode;

  final GlobalKey _socialSectionKey = GlobalKey();
  bool _focusRequested = false;
  bool _highlightPending = false;
  Timer? _highlightTimer;

  @override
  void initState() {
    super.initState();
    widget.focusPendingRequests?.addListener(_onFocusRequested);
    _loadUserInformation();
    _loadLanguageService();
    _loadBiometricStatus();
    _loadThemeMode();
  }

  @override
  void didUpdateWidget(covariant Profile oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.focusPendingRequests != widget.focusPendingRequests) {
      oldWidget.focusPendingRequests?.removeListener(_onFocusRequested);
      widget.focusPendingRequests?.addListener(_onFocusRequested);
    }
  }

  @override
  void dispose() {
    widget.focusPendingRequests?.removeListener(_onFocusRequested);
    _highlightTimer?.cancel();
    super.dispose();
  }

  // ─── Pastilles : amener à la section concernée ─────────────────────────

  void _onFocusRequested() {
    _focusRequested = true;
    if (!_isLoading) _revealPendingSection();
  }

  /// Fait défiler jusqu'aux lignes « Mes amis » / « Recommandations reçues »
  /// et les met brièvement en évidence.
  void _revealPendingSection() {
    if (!_focusRequested) return;
    _focusRequested = false;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final target = _socialSectionKey.currentContext;
      if (!mounted || target == null) return;
      Scrollable.ensureVisible(
        target,
        duration: const Duration(milliseconds: 350),
        curve: Curves.easeOutCubic,
        alignment: 0.05,
      );
      setState(() => _highlightPending = true);
      _highlightTimer?.cancel();
      _highlightTimer = Timer(const Duration(milliseconds: 2500), () {
        if (mounted) setState(() => _highlightPending = false);
      });
    });
  }

  /// Compteurs fournis par la barre de navigation ; zéro hors de celle-ci.
  Widget _withCounts(Widget Function(NotificationCounts counts) builder) {
    NotificationCountsCubit? cubit;
    try {
      cubit = context.read<NotificationCountsCubit>();
    } catch (_) {
      cubit = null;
    }
    if (cubit == null) return builder(NotificationCounts.zero);
    return BlocBuilder<NotificationCountsCubit, NotificationCounts>(
      bloc: cubit,
      builder: (_, counts) => builder(counts),
    );
  }

  // ─── Loaders ───────────────────────────────────────────────────────────

  Future<void> _loadLanguageService() async {
    final languageService = await getIt.getAsync<LanguageService>();
    if (!mounted) return;
    setState(() => _currentLocale = languageService.getCurrentLocale());
  }

  Future<void> _loadBiometricStatus() async {
    final isEnabled = await _authService.isBiometricEnabled();
    if (!mounted) return;
    setState(() => _biometricEnabled = isEnabled);
  }

  Future<void> _loadThemeMode() async {
    try {
      final themeService = await getIt.getAsync<ThemeService>();
      if (!mounted) return;
      setState(() => _currentThemeMode = themeService.getCurrentThemeMode());
    } catch (_) {}
  }

  Future<void> _loadUserInformation() async {
    try {
      final userInfo = await _userService.getUserInformation();
      if (!mounted) return;
      setState(() {
        _userInfo = userInfo;
        _isLoading = false;
      });
      _revealPendingSection();
    } catch (_) {
      if (!mounted) return;
      setState(() => _isLoading = false);
      _revealPendingSection();
      final l10n = AppLocalizations.of(context);
      _notifier.error(l10n?.userInfoLoadError ??
          'Impossible de charger les informations utilisateur');
    }
  }

  // ─── Actions ───────────────────────────────────────────────────────────

  void _redirectToLoginPage() {
    HapticFeedback.lightImpact();
    context.go('/login');
  }

  /// Nouvelle page dédiée `/change-password` (mot de passe actuel requis +
  /// déconnexion des autres appareils) — remplace l'ancien dialog legacy.
  void _onChangePassword() {
    context.push('/change-password');
  }

  Future<void> _onDeleteAccount() async {
    final l10n = AppLocalizations.of(context)!;
    final confirmed = await ProfileDialogs.showDeleteAccountConfirm(context);
    if (!confirmed) return;
    try {
      await _userService.deleteAccount();
      // Le compte n'existe plus : le cache local doit partir avec lui, sinon
      // ses donnees resteraient lisibles sur l'appareil. `my_data_view` le
      // faisait deja, pas ce chemin-ci.
      await _authService.logout();
      if (!mounted) return;
      _redirectToLoginPage();
      _notifier.success(l10n.accountDeletedSuccess);
    } catch (_) {
      _notifier.error(l10n.accountDeleteError);
    }
  }

  Future<void> _onLogout() async {
    final confirmed = await ProfileDialogs.showLogoutConfirm(context);
    if (!confirmed) return;
    await _authService.logout();
    if (!mounted) return;
    _redirectToLoginPage();
  }

  Future<void> _onEditProfile() async {
    if (_userInfo == null) return;
    final updated = await context.push<bool>('/profile/edit', extra: _userInfo);
    if (updated != true) return;
    _loadUserInformation();
    // La salutation de l'accueil (BLoC singleton) reprend le nouveau nom.
    getIt<HomePageBloc>().add(const LoadUserInfo());
  }

  Future<void> _onPickTheme() async {
    final themeService = await getIt.getAsync<ThemeService>();
    if (!mounted) return;
    final currentMode = _currentThemeMode ?? themeService.getCurrentThemeMode();
    final selected = await ProfileDialogs.showThemeSelector(
      context: context,
      currentMode: currentMode,
    );
    if (selected != null && selected != currentMode) {
      await themeService.setThemeMode(selected);
      if (!mounted) return;
      setState(() => _currentThemeMode = selected);
    }
  }

  Future<void> _onPickLanguage() async {
    await LanguageSelectorButton.showLanguageSelector(
      context,
      onLanguageChanged: (locale) {
        if (mounted) setState(() => _currentLocale = locale);
      },
    );
  }

  Future<void> _onToggleBiometric() async {
    final l10n = AppLocalizations.of(context)!;
    final currentStatus = _biometricEnabled ?? false;

    if (currentStatus) {
      await _authService.setBiometricEnabled(false);
      if (!mounted) return;
      setState(() => _biometricEnabled = false);
      _notifier.success(l10n.disableBiometricAuth);
      return;
    }

    final hasSupport = await _authService.biometricService.hasBiometricSupport();
    final availableTypes =
        await _authService.biometricService.getAvailableBiometrics();

    if (availableTypes.isEmpty) {
      if (!mounted) return;
      final testResult = await _authService.biometricService
          .authenticateWithBiometrics(context);
      if (!testResult) return;
    }

    if (!hasSupport && availableTypes.isEmpty) {
      _notifier.info(l10n.biometricAuthNotAvailable);
      return;
    }

    final hasCreds =
        await _authService.storageService.hasBiometricCredentials();
    if (!hasCreds) {
      if (!mounted) return;
      final wantsLogout =
          await ProfileDialogs.showBiometricReconnectDialog(context);
      if (wantsLogout) _onLogout();
      return;
    }

    await _authService.setBiometricEnabled(true);
    if (!mounted) return;
    setState(() => _biometricEnabled = true);
    _notifier.success(l10n.enableBiometricAuth);
  }

  Future<void> _onOpenDiscord() async {
    final l10n = AppLocalizations.of(context)!;
    final uri = Uri.parse('https://discord.gg/X6sBgFY7');
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    } else {
      _notifier.error(l10n.discordLinkError);
    }
  }

  // ─── Build ─────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final brightness = Theme.of(context).brightness;
    final isDark = brightness == Brightness.dark;
    final bgColor = isDark ? AppColors.dsBgDark : AppColors.dsBgLight;
    // Nom à afficher (modifiable) en titre, identifiant en second : afficher
    // `username` rendait toute modification du nom invisible.
    final username = _userInfo?.effectiveDisplayName ?? l10n.user;
    final handle = _userInfo?.username;
    final email = _userInfo?.email ?? '';

    return Scaffold(
      backgroundColor: bgColor,
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          // Responsive (audit 2026-06-12) : centrage via le wrapper unifié
          // AppContentWidth (700 conservé : contenu type formulaire) +
          // breakpoint AppBreakpoints au lieu du seuil local 700.
          : LayoutBuilder(
              builder: (context, constraints) {
                final bp = AppBreakpoints.of(constraints.maxWidth);
                final horizontalPadding = bp.isAtLeastTablet ? 24.0 : 0.0;
                return AppContentWidth(
                  maxWidth: 700,
                  child: Padding(
                    padding: EdgeInsets.symmetric(
                        horizontal: horizontalPadding),
                    child: _withCounts((counts) => ProfileBody(
                      counts: counts,
                      highlightPending: _highlightPending,
                      socialSectionKey: _socialSectionKey,
                      username: username,
                      handle: handle,
                      email: email,
                      avatarUrl: _userInfo?.avatarUrl,
                      currentLocale: _currentLocale,
                      currentThemeMode: _currentThemeMode,
                      biometricEnabled: _biometricEnabled,
                      biometricService: _authService.biometricService,
                      onAvatarTap: () =>
                          _notifier.info(l10n.comingSoonAvatar),
                      onChangePassword: _onChangePassword,
                      onEditProfile: _onEditProfile,
                      onMyStats: () => context.push('/stats'),
                      onMyFriends: () => context.push(
                        counts.pendingFriendRequests > 0
                            ? '/friends?tab=pending'
                            : '/friends',
                      ),
                      onMyInbox: () => context.push('/inbox'),
                      onReadingGroups: () => context.push('/reading-groups'),
                      onPickLanguage: _onPickLanguage,
                      onNotifications: () =>
                          context.push('/notifications-settings'),
                      onPickTheme: _onPickTheme,
                      onToggleBiometric: _onToggleBiometric,
                      onMyData: () => context.push('/my-data'),
                      onLogout: _onLogout,
                      onDeleteAccount: _onDeleteAccount,
                      onOpenDiscord: _onOpenDiscord,
                      onDownloads: () => context.push('/downloads'),
                      onCustomSelectors: () =>
                          context.push('/custom-selectors'),
                    )),
                  ),
                );
              },
            ),
    );
  }
}
