import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mangatracker/core/components/app_chip.dart';
import 'package:mangatracker/core/components/app_count_badge.dart';
import 'package:mangatracker/core/components/app_empty_state.dart';
import 'package:mangatracker/core/components/app_error_state.dart';
import 'package:mangatracker/core/components/app_list_tile.dart';
import 'package:mangatracker/core/components/offline_banner.dart';
import 'package:mangatracker/core/components/pastel_tile.dart';
import 'package:mangatracker/core/components/session_rejected_banner.dart';
import 'package:mangatracker/core/theme/app_theme.dart';
import 'package:mangatracker/features/manga/widgets/last_site_link_suggestion.dart';
import 'package:mangatracker/features/profile/widgets/profile_menu_row.dart';
import 'package:mangatracker/features/reader/services/last_site_link_policy.dart';
import 'package:mangatracker/features/reader/widgets/link_discovery_banner.dart';
import 'package:mangatracker/l10n/app_localizations.dart';

/// Petit téléphone (320 dp) avec texte agrandi (×1,3) : aucun composant
/// partagé ne doit déborder, quelle que soit la langue (l'allemand a les
/// libellés les plus longs).
const _longTitle =
    'Le titre extrêmement long d’une œuvre qui ne tient jamais sur une ligne';

Widget _app(Locale locale, List<Widget> children) => MaterialApp(
  locale: locale,
  theme: AppTheme.light,
  localizationsDelegates: AppLocalizations.localizationsDelegates,
  supportedLocales: AppLocalizations.supportedLocales,
  builder:
      (context, child) => MediaQuery(
        data: MediaQuery.of(
          context,
        ).copyWith(textScaler: const TextScaler.linear(1.3)),
        child: child!,
      ),
  home: Scaffold(
    body: SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          for (final c in children) ...[c, const SizedBox(height: 12)],
        ],
      ),
    ),
  ),
);

List<Widget> _components() => [
  const OfflineBanner(pendingActions: 112),
  PendingSyncBanner(pendingActions: 112, onSync: () {}),
  SessionRejectedBanner(onReconnect: () {}),
  AppListTile(
    leadingIcon: Icons.person_outline,
    title: _longTitle,
    subtitle: _longTitle,
    trailing: const AppCountBadge(count: 128),
    onTap: () {},
  ),
  const Wrap(children: [AppChip(label: _longTitle, icon: Icons.bookmark)]),
  AppEmptyState(
    icon: Icons.inbox_outlined,
    title: _longTitle,
    subtitle: _longTitle,
    actionLabel: _longTitle,
    onAction: () {},
  ),
  AppErrorState(message: _longTitle, retryLabel: _longTitle, onRetry: () {}),
  ProfileMenuRow(
    leading: const PastelTile(
      icon: Icons.group_outlined,
      color: PastelTileColor.blue,
    ),
    title: _longTitle,
    subtitle: _longTitle,
    badgeCount: 128,
    highlighted: true,
    onTap: () {},
  ),
  LastSiteLinkSuggestion(
    suggestion: const LastSiteLink(
      sourceTitle: _longTitle,
      link:
          'https://www.un-site-de-lecture-au-nom-tres-long.example/chapitre-1',
      siteRoot: 'https://www.un-site-de-lecture-au-nom-tres-long.example/',
      host: 'un-site-de-lecture-au-nom-tres-long.example',
    ),
    onCopyLink: () {},
    onSearchOnSite: () {},
  ),
  LinkDiscoveryBanner(
    mangaTitle: _longTitle,
    onSaveLink: () {},
    onDismiss: () {},
  ),
];

void main() {
  for (final locale in const [Locale('fr'), Locale('de'), Locale('ja')]) {
    testWidgets(
      '320 dp, texte ×1,3 (${locale.languageCode}) : aucun débordement',
      (tester) async {
        tester.view.physicalSize = const Size(320, 640);
        tester.view.devicePixelRatio = 1;
        addTearDown(tester.view.reset);

        await tester.pumpWidget(_app(locale, _components()));
        await tester.pump(const Duration(milliseconds: 500));

        expect(tester.takeException(), isNull);
      },
    );
  }
}
