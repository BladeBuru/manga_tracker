import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:mangatracker/core/bloc/notification_counts_cubit.dart';
import 'package:mangatracker/core/router/app_modals.dart';
import 'package:mangatracker/core/router/auth_navigation.dart';
import 'package:mangatracker/core/service_locator/service_locator.dart';
import 'package:mangatracker/core/services/notification_counts_service.dart';
import 'package:mangatracker/core/theme/app_colors.dart';
import 'package:mangatracker/features/home/bloc/home_sections_bloc.dart';
import 'package:mangatracker/features/home/bloc/home_sections_event.dart';
import 'package:mangatracker/features/home/bloc/homepage_bloc.dart';
import 'package:mangatracker/features/home/bloc/homepage_event.dart';
import 'package:mangatracker/features/home/views/main_tab.dart';
import 'package:mangatracker/features/home/widgets/consent_refresh_dialog.dart';
import 'package:mangatracker/features/library/bloc/library_bloc.dart';
import 'package:mangatracker/features/library/bloc/library_event.dart';
import 'package:mangatracker/features/manga/services/notification_service.dart';
import 'package:mangatracker/features/profile/services/gdpr.service.dart';
import 'package:mangatracker/l10n/app_localizations.dart';

/// Coque des onglets : barre du bas + onglet affiché ([navigationShell],
/// fourni par le `StatefulShellRoute`, une URL par onglet).
///
/// Conserve tout ce que portait l'ancienne barre à `PageView` interne :
/// pastilles (`NotificationCountsCubit`) et leur cycle de vie, contrôle du
/// re-consentement RGPD, ouverture de l'écran d'une notification.
/// Retour Android sur un autre onglet que l'accueil : retour à l'accueil
/// (puis sortie de l'app).
class BottomNavbar extends StatefulWidget {
  final StatefulNavigationShell navigationShell;

  const BottomNavbar({super.key, required this.navigationShell});

  @override
  State<BottomNavbar> createState() => BottomNavbarState();
}

class BottomNavbarState extends State<BottomNavbar> {
  /// Pastilles « à traiter » (demandes d'ami + recommandations reçues).
  /// Créé avec la barre : le badge existe dès le premier rendu.
  final NotificationCountsCubit _counts = NotificationCountsCubit();

  /// Demande au profil d'amener l'utilisateur à ce qui l'attend.
  final ValueNotifier<int> _profileFocusRequests = ValueNotifier<int>(0);

  late final AppLifecycleListener _lifecycle;

  int get _currentIndex => widget.navigationShell.currentIndex;

  @override
  void initState() {
    super.initState();
    // Retour au premier plan : les pastilles reflètent ce qui est arrivé
    // pendant l'absence, sans attendre la prochaine interrogation.
    _lifecycle = AppLifecycleListener(
      onResume: _counts.resume,
      onPause: _counts.pause,
    );
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _checkConsentRefresh();
      _openNotificationLaunchRoute();
    });
  }

  @override
  void didUpdateWidget(covariant BottomNavbar oldWidget) {
    super.didUpdateWidget(oldWidget);
    final previous = oldWidget.navigationShell.currentIndex;
    if (previous != _currentIndex) _onTabShown(MainTab.values[_currentIndex]);
  }

  @override
  void dispose() {
    _lifecycle.dispose();
    _counts.close();
    _profileFocusRequests.dispose();
    super.dispose();
  }

  /// Application ouverte en touchant une notification : on va à l'écran
  /// concerné une fois l'accueil affiché.
  void _openNotificationLaunchRoute() {
    final location = NotificationService().takePendingLaunchRoute();
    if (location != null && mounted) context.push(location);
  }

  /// Les onglets restent vivants : on relance en arrière-plan les mêmes
  /// chargements qu'à leur ouverture (avant, l'onglet était reconstruit à
  /// chaque visite). Le cache reste affiché pendant ce temps.
  void _onTabShown(MainTab tab) {
    switch (tab) {
      case MainTab.home:
        getIt<HomePageBloc>().add(const LoadHomePage());
        getIt<HomeSectionsBloc>().add(const LoadHomeSections());
      case MainTab.library:
        getIt<LibraryBloc>().add(const LoadLibrary());
      case MainTab.search:
      case MainTab.profile:
        break;
    }
  }

  void _goTab(int index) {
    widget.navigationShell.goBranch(index);
    if (index == MainTab.profile.index) {
      if (_counts.state.total > 0) _profileFocusRequests.value++;
      _counts.refresh();
    }
  }

  Future<void> _checkConsentRefresh() async {
    final gdpr = getIt<GdprService>();
    final status = await gdpr.getConsentStatus();
    if (!mounted || status == null) return;
    if (!status.needsAnyAcceptance) return;

    // Modal blocking — l'utilisateur ne peut pas fermer sans accepter ou
    // se déconnecter (article 7 RGPD : consentement libre, donc on doit
    // proposer une issue alternative à l'acceptation).
    final accepted = await showAppDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => ConsentRefreshDialog(status: status),
    );

    if (!mounted) return;
    if (accepted == true) {
      final ok = await gdpr.recordConsent(
        tosVersion: status.currentTosVersion,
        privacyVersion: status.currentPrivacyVersion,
      );
      if (!ok && mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text(
              "Échec d'enregistrement du consentement. Réessayez plus tard.",
            ),
          ),
        );
      }
    } else {
      // Refus → article 7 RGPD : on déconnecte l'utilisateur. Il pourra
      // revenir et accepter plus tard, ou supprimer son compte.
      try {
        await AuthNavigation.signOut();
      } catch (_) {}
    }
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final unselected = AppColors.dsText3(Theme.of(context).brightness);
    return BlocProvider<NotificationCountsCubit>.value(
      value: _counts,
      child: MainShellScope(
        profileFocusRequests: _profileFocusRequests,
        child: PopScope(
          canPop: _currentIndex == MainTab.home.index,
          onPopInvokedWithResult: (didPop, _) {
            if (!didPop) _goTab(MainTab.home.index);
          },
          child: Scaffold(
            // Le contenu se redimensionne avec le clavier : la barre du bas
            // remonte au-dessus et la liste garde tout l'espace (2026-05-19).
            resizeToAvoidBottomInset: true,
            body: widget.navigationShell,
            bottomNavigationBar: BottomNavigationBar(
              type: BottomNavigationBarType.fixed,
              currentIndex: _currentIndex,
              onTap: _goTab,
              selectedFontSize: 13,
              selectedIconTheme: IconThemeData(color: scheme.primary, size: 30),
              selectedItemColor: scheme.primary,
              unselectedIconTheme: IconThemeData(color: unselected),
              unselectedItemColor: unselected,
              items: _items(context, scheme.primary, unselected),
            ),
          ),
        ),
      ),
    );
  }

  List<BottomNavigationBarItem> _items(
    BuildContext context,
    Color selected,
    Color unselected,
  ) {
    final l10n = AppLocalizations.of(context);
    Color colorOf(MainTab tab) =>
        _currentIndex == tab.index ? selected : unselected;
    return [
      BottomNavigationBarItem(
        icon: Icon(Icons.home, color: colorOf(MainTab.home)),
        label: l10n?.home ?? 'Accueil',
      ),
      BottomNavigationBarItem(
        icon: Icon(Icons.book, color: colorOf(MainTab.library)),
        label: l10n?.library ?? 'Bibliothèque',
      ),
      BottomNavigationBarItem(
        icon: Icon(Icons.search, color: colorOf(MainTab.search)),
        label: l10n?.search ?? 'Recherche',
      ),
      BottomNavigationBarItem(
        icon: _NotifBadgedIcon(
          icon: Icons.person,
          color: colorOf(MainTab.profile),
        ),
        label: l10n?.myAccount ?? 'Mon compte',
      ),
    ];
  }
}

/// Icône de l'onglet « Mon compte » avec la pastille du total « à traiter »
/// (Material 3 `Badge`), lue dans [NotificationCountsCubit].
class _NotifBadgedIcon extends StatelessWidget {
  final IconData icon;
  final Color color;

  const _NotifBadgedIcon({required this.icon, required this.color});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return BlocSelector<NotificationCountsCubit, NotificationCounts, int>(
      selector: (counts) => counts.total,
      builder: (context, total) {
        final iconWidget = Icon(icon, color: color);
        if (total <= 0) return iconWidget;
        return Semantics(
          label: l10n?.accountTabPendingBadge(total),
          child: Badge.count(count: total, child: iconWidget),
        );
      },
    );
  }
}
