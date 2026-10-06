import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mangatracker/core/components/language_selector_button.dart';
import 'package:mangatracker/core/components/welcome_header.dart';
import 'package:mangatracker/core/service_locator/service_locator.dart';
import 'package:mangatracker/core/services/language_service.dart';
import 'package:mangatracker/core/theme/app_theme.dart';
import 'package:mangatracker/features/auth/widgets/auth_footer_link.dart';
import 'package:mangatracker/features/auth/widgets/social_login_buttons.dart';
import 'package:mangatracker/features/comments/dto/comment.dto.dart';
import 'package:mangatracker/features/comments/widgets/comments_section.dart';
import 'package:mangatracker/features/friends/dto/friend.dto.dart';
import 'package:mangatracker/features/friends/widgets/friend_list_tile.dart';
import 'package:mangatracker/features/sharing/widgets/inbox_filter_chips.dart';
import 'package:mangatracker/features/stats/widgets/stats_activity_section.dart';
import 'package:mangatracker/l10n/app_localizations.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Petit téléphone (320 dp) avec texte agrandi (×1,3) : les rangées d'écran
/// (pied de page d'authentification, filtres, demandes d'ami, en-têtes…) ne
/// doivent ni déborder ni casser un libellé lettre par lettre, en français,
/// en allemand (libellés les plus longs) et en japonais (glyphes larges).

/// Un nom affiché peut faire 80 caractères.
const _longName =
    'Un nom affiché vraiment très long, de ceux qui ne tiennent jamais sur une ligne';

const _locales = [Locale('fr'), Locale('de'), Locale('ja')];

Widget _app(Locale locale, Widget home, {double textScale = 1.3}) =>
    MaterialApp(
      locale: locale,
      theme: AppTheme.light,
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      supportedLocales: AppLocalizations.supportedLocales,
      builder:
          (context, child) => MediaQuery(
            data: MediaQuery.of(
              context,
            ).copyWith(textScaler: TextScaler.linear(textScale)),
            child: child!,
          ),
      home: home,
    );

/// Page défilante : chaque rangée reçoit la largeur utile d'un écran de
/// 320 dp moins les marges habituelles (16 dp de chaque côté).
Widget _page(List<Widget> Function(AppLocalizations l10n) rows) => Scaffold(
  body: Builder(
    builder: (context) {
      final l10n = AppLocalizations.of(context)!;
      return SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            for (final row in rows(l10n)) ...[row, const SizedBox(height: 12)],
          ],
        ),
      );
    },
  ),
);

FriendshipDto _friendship(FriendshipStatus status) => FriendshipDto(
  id: 1,
  status: status,
  direction: FriendshipDirection.received,
  otherUserId: 2,
  otherUsername: 'un_pseudo_lui_aussi_particulierement_long',
  otherDisplayName: _longName,
  createdAt: DateTime(2026, 1, 1),
);

String _dayKey(DateTime d) =>
    '${d.year.toString().padLeft(4, '0')}-'
    '${d.month.toString().padLeft(2, '0')}-'
    '${d.day.toString().padLeft(2, '0')}';

/// 8 dernières semaines (clé = lundi), toutes avec un compteur à 3 chiffres.
Map<String, int> _busyWeeks() {
  final now = DateTime.now();
  final thisMonday = DateTime(
    now.year,
    now.month,
    now.day,
  ).subtract(Duration(days: now.weekday - 1));
  return {
    for (var i = 0; i < 8; i++)
      _dayKey(thisMonday.subtract(Duration(days: 7 * i))): 100 + i * 4,
  };
}

List<Widget> _rows(
  AppLocalizations l10n, {
  VoidCallback? onAccept,
  VoidCallback? onReject,
  VoidCallback? onFooterTap,
}) => [
  WelcomeHeader(username: _longName),
  AuthFooterLink(
    message: l10n.noAccount,
    actionLabel: l10n.signUp,
    onTap: onFooterTap ?? () {},
  ),
  AuthFooterLink(
    message: l10n.alreadyHaveAccount,
    actionLabel: l10n.login,
    onTap: () {},
  ),
  SocialLoginButtons(
    googleLabel: l10n.loginWithGoogle,
    appleLabel: l10n.continueWithApple,
    onGoogle: () async {},
    onApple: () {},
  ),
  InboxFilterChips(
    selected: InboxFilter.unread,
    totalCount: 128,
    unreadCount: 128,
    readCount: 128,
    onChanged: (_) {},
    labelAll: l10n.inboxFilterAll,
    labelUnread: l10n.inboxFilterUnread,
    labelRead: l10n.inboxFilterRead,
  ),
  FriendListTile(
    friendship: _friendship(FriendshipStatus.pending),
    showAcceptReject: true,
    onAccept: onAccept ?? () {},
    onReject: onReject ?? () {},
  ),
  FriendListTile(
    friendship: _friendship(FriendshipStatus.accepted),
    onRemove: () {},
  ),
  CommentsHeader(count: 1280, sort: CommentSort.recent, onSortChanged: (_) {}),
  StatsActivitySection(chaptersPerWeek: _busyWeeks()),
];

void _smallPhone(WidgetTester tester, {double width = 320}) {
  tester.view.physicalSize = Size(width, 640);
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.reset);
}

void main() {
  for (final locale in _locales) {
    testWidgets(
      '320 dp, texte ×1,3 (${locale.languageCode}) : rangées sans débordement',
      (tester) async {
        _smallPhone(tester);
        await tester.pumpWidget(_app(locale, _page(_rows)));
        await tester.pump(const Duration(milliseconds: 900));

        expect(tester.takeException(), isNull);
      },
    );

    testWidgets(
      '320 dp, texte ×1,3 (${locale.languageCode}) : le choix de la langue '
      'défile et reste utilisable',
      (tester) async {
        _smallPhone(tester);
        SharedPreferences.setMockInitialValues({});
        final prefs = await SharedPreferences.getInstance();
        getIt.registerSingleton<LanguageService>(LanguageService(prefs));
        addTearDown(() => getIt.unregister<LanguageService>());

        await tester.pumpWidget(
          _app(
            locale,
            Scaffold(
              body: Builder(
                builder:
                    (context) => TextButton(
                      onPressed:
                          () => LanguageSelectorButton.showLanguageSelector(
                            context,
                          ),
                      child: const Text('open'),
                    ),
              ),
            ),
          ),
        );
        await tester.tap(find.text('open'));
        await tester.pumpAndSettle();

        expect(tester.takeException(), isNull);
        expect(find.byType(Dialog), findsOneWidget);

        // La dernière langue est joignable en faisant défiler la liste.
        final list = find.descendant(
          of: find.byType(Dialog),
          matching: find.byType(Scrollable),
        );
        await tester.scrollUntilVisible(
          find.text('Español'),
          50,
          scrollable: list,
        );
        await tester.tap(find.text('Español'));
        await tester.pumpAndSettle();

        expect(find.byType(Dialog), findsNothing);
        expect(prefs.getString('app_language'), 'es');
      },
    );
  }

  testWidgets('demande d\'ami : boutons icône de 40 dp, libellés accessibles', (
    tester,
  ) async {
    _smallPhone(tester);
    final handle = tester.ensureSemantics();
    var accepted = 0;
    var rejected = 0;
    late AppLocalizations l10n;
    await tester.pumpWidget(
      _app(
        const Locale('de'),
        _page((l) {
          l10n = l;
          return [
            FriendListTile(
              friendship: _friendship(FriendshipStatus.pending),
              showAcceptReject: true,
              onAccept: () => accepted++,
              onReject: () => rejected++,
            ),
          ];
        }),
      ),
    );

    final accept = find.byTooltip(l10n.friendsAccept);
    final reject = find.byTooltip(l10n.friendsReject);
    expect(tester.getSize(accept).shortestSide, greaterThanOrEqualTo(40));
    expect(tester.getSize(reject).shortestSide, greaterThanOrEqualTo(40));
    // Un seul nœud par bouton, actionnable, nommé par l'infobulle traduite.
    expect(
      tester.getSemantics(accept),
      matchesSemantics(
        tooltip: l10n.friendsAccept,
        isButton: true,
        hasTapAction: true,
        hasFocusAction: true,
        hasEnabledState: true,
        isEnabled: true,
        isFocusable: true,
      ),
    );
    expect(
      tester.getSemantics(reject),
      matchesSemantics(
        tooltip: l10n.friendsReject,
        isButton: true,
        hasTapAction: true,
        hasFocusAction: true,
        hasEnabledState: true,
        isEnabled: true,
        isFocusable: true,
      ),
    );

    await tester.tap(accept);
    await tester.tap(reject);
    expect(accepted, 1);
    expect(rejected, 1);
    handle.dispose();
  });

  testWidgets('pied de page auth : lien de 40 dp de haut, appui transmis', (
    tester,
  ) async {
    _smallPhone(tester);
    var taps = 0;
    late AppLocalizations l10n;
    await tester.pumpWidget(
      _app(
        const Locale('de'),
        _page((l) {
          l10n = l;
          return [
            AuthFooterLink(
              message: l.noAccount,
              actionLabel: l.signUp,
              onTap: () => taps++,
            ),
          ];
        }),
      ),
    );

    final link = find.widgetWithText(TextButton, l10n.signUp);
    expect(tester.getSize(link).height, greaterThanOrEqualTo(40));
    await tester.tap(link);
    expect(taps, 1);
  });

  testWidgets(
    'connexion sociale : empilée sur petit écran, côte à côte sinon',
    (tester) async {
      Future<(Offset, Offset)> positions(double width, double scale) async {
        tester.view.physicalSize = Size(width, 900);
        tester.view.devicePixelRatio = 1;
        late AppLocalizations l10n;
        await tester.pumpWidget(
          _app(
            const Locale('fr'),
            _page((l) {
              l10n = l;
              return [
                SocialLoginButtons(
                  googleLabel: l.loginWithGoogle,
                  appleLabel: l.continueWithApple,
                  onGoogle: () async {},
                  onApple: () {},
                ),
              ];
            }),
            textScale: scale,
          ),
        );
        return (
          tester.getTopLeft(find.text(l10n.loginWithGoogle)),
          tester.getTopLeft(find.text(l10n.continueWithApple)),
        );
      }

      addTearDown(tester.view.reset);

      final (smallGoogle, smallApple) = await positions(320, 1.3);
      expect(smallApple.dy, greaterThan(smallGoogle.dy), reason: 'empilés');
      expect(tester.takeException(), isNull);

      final (wideGoogle, wideApple) = await positions(900, 1.0);
      expect(wideApple.dy, wideGoogle.dy, reason: 'côte à côte');
      expect(wideApple.dx, greaterThan(wideGoogle.dx));
    },
  );

  testWidgets('en-tête des commentaires : le tri reste actionnable', (
    tester,
  ) async {
    _smallPhone(tester);
    CommentSort? chosen;
    late AppLocalizations l10n;
    await tester.pumpWidget(
      _app(
        const Locale('de'),
        _page((l) {
          l10n = l;
          return [
            CommentsHeader(
              count: 1280,
              sort: CommentSort.recent,
              onSortChanged: (s) => chosen = s,
            ),
          ];
        }),
      ),
    );

    expect(tester.takeException(), isNull);
    // Le tri passe sous le titre, qui garde toute la largeur (avant : ~79 px
    // et une coupure en plein mot).
    final title = find.text('${l10n.commentsTitle} (1280)');
    final sortChip = find.text(l10n.commentsSortTop);
    expect(tester.getSize(title).width, greaterThan(200));
    expect(
      tester.getTopLeft(sortChip).dy,
      greaterThan(tester.getBottomLeft(title).dy),
    );

    await tester.tap(find.text(l10n.commentsSortTop));
    expect(chosen, CommentSort.top);
  });
}
