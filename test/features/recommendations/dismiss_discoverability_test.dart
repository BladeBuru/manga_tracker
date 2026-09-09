import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mangatracker/features/manga/dto/manga_quick_view.dto.dart';
import 'package:mangatracker/features/manga/widgets/manga_card.dart';
import 'package:mangatracker/features/recommendations/services/recommendation_tip_store.dart';
import 'package:mangatracker/features/recommendations/widgets/dismiss_recommendation_tip.dart';
import 'package:mangatracker/features/recommendations/widgets/dismissible_recommendation_card.dart';
import 'package:mangatracker/l10n/app_localizations.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Store en memoire : permet de verifier le « une seule fois » sans toucher
/// aux preferences reelles.
class _FakeTipStore implements RecommendationTipStore {
  bool seen;
  int marks = 0;

  _FakeTipStore({this.seen = false});

  @override
  Future<bool> hasSeenDismissTip() async => seen;

  @override
  Future<void> markDismissTipSeen() async {
    seen = true;
    marks++;
  }
}

/// Le geste « pas interesse » existait mais restait invisible : zero rejet
/// enregistre en production. Ces tests verrouillent le dispositif de
/// decouvrabilite — l'astuce vue une seule fois, le point d'entree explicite
/// sur la page « Tout voir » — sans casser le geste d'origine.
void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUpAll(() {
    // La cover passe par le proxy d'images, qui lit MT_API_URL via dotenv.
    dotenv.testLoad(fileInput: 'MT_API_URL=https://api.test');
  });

  Widget harness(Widget child, {double width = 360, double height = 400}) =>
      MaterialApp(
        locale: const Locale('fr'),
        localizationsDelegates: const [
          AppLocalizations.delegate,
          GlobalMaterialLocalizations.delegate,
          GlobalWidgetsLocalizations.delegate,
          GlobalCupertinoLocalizations.delegate,
        ],
        supportedLocales: AppLocalizations.supportedLocales,
        home: Scaffold(
          body: Center(
            child: SizedBox(width: width, height: height, child: child),
          ),
        ),
      );

  const manga = MangaQuickViewDto(
    muId: 12345,
    title: 'One Piece',
    year: '1997',
    rating: '9.1',
  );

  group('astuce d\'usage — montree une fois, puis plus jamais', () {
    testWidgets('premiere visite : l\'astuce s\'affiche et est memorisee',
        (tester) async {
      final store = _FakeTipStore(seen: false);

      await tester.pumpWidget(harness(DismissRecommendationTip(store: store)));
      await tester.pumpAndSettle();

      expect(find.text('Un titre qui ne t’intéresse pas ?'), findsOneWidget);
      expect(find.text('Compris'), findsOneWidget);
      expect(store.seen, isTrue,
          reason: 'memorisee des l\'affichage, pas seulement sur « Compris »');
      expect(store.marks, 1);
    });

    testWidgets('visite suivante : plus rien, meme sans acquittement',
        (tester) async {
      final store = _FakeTipStore(seen: true);

      await tester.pumpWidget(harness(DismissRecommendationTip(store: store)));
      await tester.pumpAndSettle();

      expect(find.text('Un titre qui ne t’intéresse pas ?'), findsNothing);
      expect(find.byType(TextButton), findsNothing);
      expect(store.marks, 0);
    });

    testWidgets('« Compris » range l\'astuce immediatement', (tester) async {
      final store = _FakeTipStore(seen: false);

      await tester.pumpWidget(harness(DismissRecommendationTip(store: store)));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Compris'));
      await tester.pumpAndSettle();

      expect(find.text('Un titre qui ne t’intéresse pas ?'), findsNothing);
    });

    testWidgets('rien ne clignote avant la lecture de la preference',
        (tester) async {
      await tester.pumpWidget(
        harness(DismissRecommendationTip(store: _FakeTipStore(seen: false))),
      );
      // Premiere frame : la preference n'est pas encore lue.
      expect(find.text('Un titre qui ne t’intéresse pas ?'), findsNothing);
      await tester.pumpAndSettle();
      expect(find.text('Un titre qui ne t’intéresse pas ?'), findsOneWidget);
    });

    testWidgets('la persistance reelle survit a un remontage', (tester) async {
      SharedPreferences.setMockInitialValues(<String, Object>{});

      await tester.pumpWidget(harness(const DismissRecommendationTip()));
      await tester.pumpAndSettle();
      expect(find.text('Un titre qui ne t’intéresse pas ?'), findsOneWidget);

      // Ecran quitte puis rouvert : instance neuve, meme preference.
      await tester.pumpWidget(harness(const SizedBox.shrink()));
      await tester.pumpWidget(harness(const DismissRecommendationTip()));
      await tester.pumpAndSettle();

      expect(find.text('Un titre qui ne t’intéresse pas ?'), findsNothing);
      final prefs = await SharedPreferences.getInstance();
      expect(prefs.getBool('reco_dismiss_tip_seen'), isTrue);
    });
  });

  group('point d\'entree explicite sur la page « Tout voir »', () {
    Finder actionButton() => find.bySemanticsLabel(
          'Ne plus me recommander ce titre',
        );

    testWidgets('active : un bouton explicite apparait sur la carte',
        (tester) async {
      await tester.pumpWidget(
        harness(
          const DismissibleRecommendationCard(
            manga: manga,
            onDismissed: _noop,
            showDismissAction: true,
          ),
          width: 120,
          height: 260,
        ),
      );

      expect(actionButton(), findsOneWidget);
      expect(find.byIcon(Icons.more_vert), findsOneWidget);
    });

    testWidgets('par defaut : aucun bouton (accueil et page par genre)',
        (tester) async {
      await tester.pumpWidget(
        harness(
          const DismissibleRecommendationCard(
            manga: manga,
            onDismissed: _noop,
          ),
          width: 120,
          height: 260,
        ),
      );

      expect(actionButton(), findsNothing);
      expect(find.byIcon(Icons.more_vert), findsNothing);
    });

    testWidgets('le bouton ouvre la feuille de rejet', (tester) async {
      await tester.pumpWidget(
        harness(
          const DismissibleRecommendationCard(
            manga: manga,
            onDismissed: _noop,
            showDismissAction: true,
          ),
          width: 120,
          height: 260,
        ),
      );

      await tester.tap(actionButton());
      // `pumpAndSettle` ne converge pas ici : la couverture de la carte reste
      // en chargement perpetuel sous test. On avance de l'animation de la
      // feuille, ce qui suffit largement.
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 600));

      expect(find.text('Ne plus me recommander ce titre'), findsWidgets,
          reason: 'la feuille demande la raison avant tout rejet');
      expect(find.text('Déjà lu'), findsOneWidget);
      expect(find.text('Pas intéressé'), findsOneWidget);
    });

    testWidgets('le geste d\'origine reste branche quand le bouton est la',
        (tester) async {
      await tester.pumpWidget(
        harness(
          const DismissibleRecommendationCard(
            manga: manga,
            onDismissed: _noop,
            showDismissAction: true,
          ),
          width: 120,
          height: 260,
        ),
      );

      expect(
        tester.widget<MangaCard>(find.byType(MangaCard)).onLongPress,
        isNotNull,
        reason: 'la decouvrabilite s\'ajoute au geste, elle ne le remplace pas',
      );
    });
  });
}

void _noop(num _) {}
