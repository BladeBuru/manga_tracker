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
import 'package:mangatracker/l10n/app_localizations.dart';

class BottomNavbar extends StatefulWidget {
  const BottomNavbar({super.key});

  @override
  State<BottomNavbar> createState() => BottomNavbarState();
}

class BottomNavbarState extends State<BottomNavbar> {
  final PageController pageCont = PageController(initialPage: 0);
  int currntIndex = 0;

  final Color unselectedColor = const Color(0xffb8b8d2);

  @override
  void initState() {
    super.initState();
    // RGPD : vérifier après le premier frame si l'utilisateur doit
    // re-accepter les CGU/Privacy (versions courantes vs versions stockées).
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _checkConsentRefresh();
    });
  }

  Future<void> _checkConsentRefresh() async {
    final gdpr = getIt<GdprService>();
    final status = await gdpr.getConsentStatus();
    if (!mounted || status == null) return;
    if (!status.needsAnyAcceptance) return;

    // Modal blocking — l'utilisateur ne peut pas fermer sans accepter ou
    // se déconnecter (article 7 RGPD : consentement libre, donc on doit
    // proposer une issue alternative à l'acceptation).
    final accepted = await showDialog<bool>(
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
  void dispose() {
    pageCont.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    
    return Scaffold(
      resizeToAvoidBottomInset: false,
      body: PageView(
        onPageChanged: (index) {
          setState(() => currntIndex = index);
        },
        controller: pageCont,
        children: <Widget>[
          BlocProvider<HomePageBloc>(
            create: (context) => getIt<HomePageBloc>(),
            child: const HomePageBlocView(),
          ),
          BlocProvider<LibraryBloc>(
            create: (context) => getIt<LibraryBloc>(),
            child: const LibraryBlocView(),
          ),
          const Search(),
          const Profile(),
        ],
      ),
      bottomNavigationBar: BottomNavigationBar(
        type: BottomNavigationBarType.fixed,
        currentIndex: currntIndex,
        onTap: (index) {
          setState(() {
            currntIndex = index;
          });
          pageCont.jumpToPage(currntIndex);
        },
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
            icon: Icon(
              Icons.person,
              color: currntIndex == 3 ? Theme.of(context).colorScheme.primary : unselectedColor,
            ),
            label: l10n?.myAccount ?? 'Mon compte',
          ),
        ],
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
