import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mangatracker/core/services/notification_counts_service.dart';
import 'package:mangatracker/features/profile/widgets/profile_sections.dart';
import 'package:mangatracker/l10n/app_localizations.dart';

Widget _section(NotificationCounts counts) => MaterialApp(
  locale: const Locale('fr'),
  localizationsDelegates: AppLocalizations.localizationsDelegates,
  supportedLocales: AppLocalizations.supportedLocales,
  home: Scaffold(
    body: SingleChildScrollView(
      child: ProfileSocialSection(
        onEditProfile: () {},
        onMyStats: () {},
        onMyFriends: () {},
        onMyInbox: () {},
        onReadingGroups: () {},
        counts: counts,
      ),
    ),
  ),
);

void main() {
  testWidgets('chaque ligne montre ce qui l\'attend', (tester) async {
    final semantics = tester.ensureSemantics();
    await tester.pumpWidget(
      _section(
        const NotificationCounts(pendingFriendRequests: 2, unseenShares: 3),
      ),
    );
    await tester.pumpAndSettle();
    expect(
      find.bySemanticsLabel(RegExp("2 demandes d'ami en attente")),
      findsOneWidget,
    );
    expect(
      find.bySemanticsLabel(RegExp('3 nouvelles recommandations')),
      findsOneWidget,
    );
    expect(find.text('2'), findsOneWidget);
    expect(find.text('3'), findsOneWidget);
    semantics.dispose();
  });

  testWidgets('aucune pastille quand rien n\'attend', (tester) async {
    await tester.pumpWidget(_section(NotificationCounts.zero));
    await tester.pumpAndSettle();
    expect(find.text('0'), findsNothing);
  });
}
