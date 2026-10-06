import 'package:mangatracker/core/theme/app_colors.dart';
import 'homepage_bloc_view.dart';
import '../../profile/views/profile.dart';
import 'package:mangatracker/features/search/views/search.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:mangatracker/core/service_locator/service_locator.dart';
import 'package:mangatracker/features/library/bloc/library_bloc.dart';
import 'package:mangatracker/features/library/views/library_bloc_view.dart';
import 'package:mangatracker/features/home/bloc/homepage_bloc.dart';
import 'package:mangatracker/features/auth/services/auth.service.dart';
import 'package:mangatracker/features/profile/services/gdpr.service.dart';
import 'package:mangatracker/core/bloc/notification_counts_cubit.dart';
import 'package:mangatracker/core/services/notification_counts_service.dart';
import 'package:mangatracker/features/manga/services/notification_service.dart';
import 'package:mangatracker/l10n/app_localizations.dart';
import 'package:mangatracker/core/router/app_modals.dart';

class BottomNavbar extends StatefulWidget {
  const BottomNavbar({super.key});

  @override
  State<BottomNavbar> createState() => BottomNavbarState();
}

class BottomNavbarState extends State<BottomNavbar> {
  final PageController pageCont = PageController(initialPage: 0);
  int currntIndex = 0;

  /// Couleur des items non sélectionnés — token V1 `dsText3` (avant :
  /// `Color(0xffb8b8d2)` ad-hoc hors design system, audit 2026-06-12).
  Color get unselectedColor =>
      AppColors.dsText3(Theme.of(context).brightness);

  static const int _accountTab = 3;

  /// Pastilles « à traiter » (demandes d'ami + recommandations reçues).
  /// Créé avec la barre : le badge existe dès le premier rendu (avant, il
  /// n'apparaissait qu'après un geste qui reconstruisait la barre).
  final NotificationCountsCubit _counts = NotificationCountsCubit();

  /// Demande au profil d'amener l'utilisateur à ce qui l'attend.
  final ValueNotifier<int> _profileFocusRequests = ValueNotifier<int>(0);

  late final AppLifecycleListener _lifecycle;

  @override
  void initState() {
    super.initState();
    // Retour au premier plan : les pastilles reflètent ce qui est arrivé
    // pendant l'absence, sans attendre la prochaine interrogation.
    _lifecycle = AppLifecycleListener(
      onResume: _counts.resume,
      onPause: _counts.pause,
    );
    // RGPD : vérifier après le premier frame si l'utilisateur doit
    // re-accepter les CGU/Privacy (versions courantes vs versions stockées).
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _checkConsentRefresh();
      _openNotificationLaunchRoute();
    });
  }

  /// Application ouverte en touchant une notification : on va à l'écran
  /// concerné une fois l'accueil affiché.
  void _openNotificationLaunchRoute() {
    final location = NotificationService().takePendingLaunchRoute();
    if (location != null && mounted) context.push(location);
  }

  void _onTabTapped(int index) {
    setState(() => currntIndex = index);
    pageCont.jumpToPage(index);
    if (index == _accountTab) {
      if (_counts.state.total > 0) _profileFocusRequests.value++;
      _counts.refresh();
    }
  }

  @override
  void dispose() {
    _lifecycle.dispose();
    _counts.close();
    _profileFocusRequests.dispose();
    pageCont.dispose();
    super.dispose();
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
      builder: (ctx) => _ConsentRefreshDialog(status: status),
    );

    if (!mounted) return;
    if (accepted == true) {
      // L'utilisateur a accepté → on enregistre côté backend.
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
      // Refus → article 7 RGPD : on déconnecte l'utilisateur.
      // Il pourra revenir et accepter plus tard, ou supprimer son compte
      // depuis l'écran de login (auquel cas /user/delete sera appelé).
      try {
        await getIt<AuthService>().logout();
      } catch (_) {}
      if (!mounted) return;
      context.go('/login');
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    
    return BlocProvider<NotificationCountsCubit>.value(
      value: _counts,
      child: Scaffold(
      // **Fix 2026-05-19** : passé de `false` à `true` (défaut Scaffold).
      // Avec `false`, le PageView gardait sa taille pleine quand le clavier
      // s'ouvre → l'inner Scaffold (Library) avait un espace blanc inutile
      // entre la fin du contenu et le clavier (~1/3 d'écran perdu). Avec
      // `true`, le PageView resize correctement → la bottom nav remonte
      // au-dessus du clavier ET la liste prend tout l'espace dispo.
      resizeToAvoidBottomInset: true,
      body: PageView(
        onPageChanged: (index) {
          setState(() => currntIndex = index);
        },
        controller: pageCont,
        children: <Widget>[
          // `.value` : ces BLoCs sont des singletons GetIt. Avec `create`,
          // le provider en devenait propriétaire et les FERMAIT quand la
          // page quitte le PageView (changement d'onglet).
          BlocProvider<HomePageBloc>.value(
            value: getIt<HomePageBloc>(),
            child: const HomePageBlocView(),
          ),
          BlocProvider<LibraryBloc>.value(
            value: getIt<LibraryBloc>(),
            child: const LibraryBlocView(),
          ),
          const Search(),
          Profile(focusPendingRequests: _profileFocusRequests),
        ],
      ),
      bottomNavigationBar: BottomNavigationBar(
        type: BottomNavigationBarType.fixed,
        currentIndex: currntIndex,
        onTap: _onTabTapped,
        selectedFontSize: 15,
        selectedIconTheme: IconThemeData(color: Theme.of(context).colorScheme.primary, size: 30),
        selectedItemColor: Theme.of(context).colorScheme.primary,
        unselectedIconTheme: IconThemeData(color: unselectedColor),
        unselectedItemColor: unselectedColor,
        items: <BottomNavigationBarItem>[
          BottomNavigationBarItem(
            icon: Icon(
              Icons.home,
              color: currntIndex == 0 ? Theme.of(context).colorScheme.primary : unselectedColor,
            ),
            label: l10n?.home ?? 'Accueil',
          ),
          BottomNavigationBarItem(
            icon: Icon(
              Icons.book,
              color: currntIndex == 1 ? Theme.of(context).colorScheme.primary : unselectedColor,
            ),
            label: l10n?.library ?? 'Bibliothèque',
          ),
          BottomNavigationBarItem(
            icon: Icon(
              Icons.search,
              color: currntIndex == 2 ? Theme.of(context).colorScheme.primary : unselectedColor,
            ),
            label: l10n?.search ?? 'Recherche',
          ),
          BottomNavigationBarItem(
            icon: _NotifBadgedIcon(
              icon: Icons.person,
              color: currntIndex == _accountTab
                  ? Theme.of(context).colorScheme.primary
                  : unselectedColor,
            ),
            label: l10n?.myAccount ?? 'Mon compte',
          ),
        ],
      ),
      ),
    );
  }
}

/// Dialog modal blocking demandant à l'utilisateur d'accepter les nouvelles
/// versions des CGU / Politique de confidentialité.
///
/// L'utilisateur a deux choix :
///  - Accepter (return true)
///  - Refuser → l'app le déconnecte (return false). Article 7 RGPD : le
///    consentement doit être libre, on doit donc proposer une issue.
class _ConsentRefreshDialog extends StatefulWidget {
  final ConsentStatus status;

  const _ConsentRefreshDialog({required this.status});

  @override
  State<_ConsentRefreshDialog> createState() => _ConsentRefreshDialogState();
}

class _ConsentRefreshDialogState extends State<_ConsentRefreshDialog> {
  bool _acceptedTos = false;
  bool _acceptedPrivacy = false;

  bool get _canAccept {
    final s = widget.status;
    final tosOk = !s.needsTosAcceptance || _acceptedTos;
    final privacyOk = !s.needsPrivacyAcceptance || _acceptedPrivacy;
    return tosOk && privacyOk;
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final s = widget.status;

    return AlertDialog(
      title: Text(l10n?.consentRefreshTitle ??
          'Mise à jour de nos conditions'),
      content: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              l10n?.consentRefreshIntro ??
                  'Nos conditions d\'utilisation et notre politique de confidentialité ont été mises à jour. '
                      'Veuillez les accepter pour continuer.',
              style: Theme.of(context).textTheme.bodyMedium,
            ),
            const SizedBox(height: 16),
            if (s.needsTosAcceptance)
              CheckboxListTile(
                value: _acceptedTos,
                onChanged: (v) => setState(() => _acceptedTos = v ?? false),
                title: Text(
                  l10n?.iAcceptTos ??
                      "J'accepte les Conditions d'utilisation",
                  style: const TextStyle(fontSize: 14),
                ),
                subtitle: Text(
                  '${l10n?.versionLabel ?? 'Version'} ${s.currentTosVersion}',
                  style: const TextStyle(fontSize: 11),
                ),
                controlAffinity: ListTileControlAffinity.leading,
                contentPadding: EdgeInsets.zero,
              ),
            if (s.needsPrivacyAcceptance)
              CheckboxListTile(
                value: _acceptedPrivacy,
                onChanged: (v) =>
                    setState(() => _acceptedPrivacy = v ?? false),
                title: Text(
                  l10n?.iAcceptPrivacy ??
                      "J'accepte la Politique de confidentialité",
                  style: const TextStyle(fontSize: 14),
                ),
                subtitle: Text(
                  '${l10n?.versionLabel ?? 'Version'} ${s.currentPrivacyVersion}',
                  style: const TextStyle(fontSize: 11),
                ),
                controlAffinity: ListTileControlAffinity.leading,
                contentPadding: EdgeInsets.zero,
              ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(false),
          child: Text(l10n?.refuseAndLogout ?? 'Refuser et se déconnecter'),
        ),
        FilledButton(
          onPressed: _canAccept
              ? () => Navigator.of(context).pop(true)
              : null,
          child: Text(l10n?.iAccept ?? 'Accepter'),
        ),
      ],
    );
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
