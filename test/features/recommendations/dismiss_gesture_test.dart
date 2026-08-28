import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mangatracker/features/manga/dto/manga_quick_view.dto.dart';
import 'package:mangatracker/features/manga/widgets/manga_card.dart';
import 'package:mangatracker/features/recommendations/widgets/dismissible_recommendation_card.dart';
import 'package:mangatracker/l10n/app_localizations.dart';

/// Le geste de rejet est un **appui long**, choisi pour ne pas encombrer
/// chaque carte d'un bouton. Ces tests verrouillent ce que ce choix suppose :
/// le geste declenche bien le rejet la ou il est branche, il est annonce aux
/// lecteurs d'ecran, et les ecrans qui ne le branchent pas sont inchanges.
void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUpAll(() {
    // La cover passe par le proxy d'images, qui lit MT_API_URL via dotenv.
    dotenv.testLoad(fileInput: 'MT_API_URL=https://api.test');
  });

  // Hauteur bornee : la carte utilise un `Expanded` pour le titre.
  Widget harness(Widget child) => MaterialApp(
    locale: const Locale('fr'),
    localizationsDelegates: const [
      AppLocalizations.delegate,
      GlobalMaterialLocalizations.delegate,
      GlobalWidgetsLocalizations.delegate,
      GlobalCupertinoLocalizations.delegate,
    ],
    supportedLocales: AppLocalizations.supportedLocales,
    home: Scaffold(
      body: Center(child: SizedBox(width: 120, height: 260, child: child)),
    ),
  );

  const manga = MangaQuickViewDto(
    muId: 12345,
    title: 'One Piece',
    year: '1997',
    rating: '9.1',
  );

  testWidgets('l’appui long declenche le rejet quand il est branche', (
    tester,
  ) async {
    var longPressed = 0;

    await tester.pumpWidget(
      harness(
        MangaCard(
          mangaTitle: 'One Piece',
          muId: '12345',
          mangaAuthor: '1997',
          onLongPress: () => longPressed++,
        ),
      ),
    );

    await tester.longPress(find.byType(MangaCard));
    await tester.pump(const Duration(milliseconds: 100));

    expect(longPressed, 1);
  });

  testWidgets('la carte de recommandation branche le geste sur MangaCard', (
    tester,
  ) async {
    await tester.pumpWidget(
      harness(
        DismissibleRecommendationCard(manga: manga, onDismissed: (_) {}),
      ),
    );

    final card = tester.widget<MangaCard>(find.byType(MangaCard));
    expect(card.onLongPress, isNotNull);
    // Le mapping DTO -> carte est centralise ici : on verifie qu'il tient.
    expect(card.muId, '12345');
    expect(card.mangaTitle, 'One Piece');
    expect(card.rating, '9.1');
  });

  testWidgets('le geste est annonce aux lecteurs d’ecran', (tester) async {
    await tester.pumpWidget(
      harness(
        DismissibleRecommendationCard(manga: manga, onDismissed: (_) {}),
      ),
    );

    final semantics = tester.widget<Semantics>(
      find
          .ancestor(
            of: find.byType(MangaCard),
            matching: find.byType(Semantics),
          )
          .first,
    );
    expect(
      semantics.properties.hint,
      'Appui long pour ne plus recommander ce titre',
    );
  });

  testWidgets(
    'une note « N/A » n’est pas affichee comme une vraie note',
    (tester) async {
      const noRating = MangaQuickViewDto(
        muId: 999,
        title: 'Sans note',
        year: '2024',
        rating: 'N/A',
      );

      await tester.pumpWidget(
        harness(
          DismissibleRecommendationCard(manga: noRating, onDismissed: (_) {}),
        ),
      );

      expect(tester.widget<MangaCard>(find.byType(MangaCard)).rating, isNull);
    },
  );

  testWidgets(
    'sans callback, la carte reste inchangee (bibliotheque, profil ami)',
    (tester) async {
      await tester.pumpWidget(
        harness(
          const MangaCard(
            mangaTitle: 'One Piece',
            muId: '12345',
            mangaAuthor: '1997',
          ),
        ),
      );

      expect(
        tester.widget<MangaCard>(find.byType(MangaCard)).onLongPress,
        isNull,
        reason: 'les ecrans non concernes ne branchent aucun geste',
      );
    },
  );
}
