import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mangatracker/core/service_locator/service_locator.dart';
import 'package:mangatracker/core/services/offline_cache_service.dart';
import 'package:mangatracker/core/theme/app_theme.dart';
import 'package:mangatracker/features/authors/widgets/author_works_grid.dart';
import 'package:mangatracker/features/friends/services/friends.service.dart';
import 'package:mangatracker/features/friends/views/friend_profile_view.dart';
import 'package:mangatracker/features/home/bloc/home_section_page_bloc.dart';
import 'package:mangatracker/features/home/bloc/home_section_page_state.dart';
import 'package:mangatracker/features/home/bloc/homepage_state.dart';
import 'package:mangatracker/features/home/dto/home_section.dto.dart';
import 'package:mangatracker/features/home/dto/home_section_kind.dart';
import 'package:mangatracker/features/home/helpers/home_layout_metrics.dart';
import 'package:mangatracker/features/home/widgets/home_recommendations_section.dart';
import 'package:mangatracker/features/home/widgets/home_section_carousel.dart';
import 'package:mangatracker/features/home/widgets/home_section_grid.dart';
import 'package:mangatracker/features/home/widgets/home_sections_skeleton.dart';
import 'package:mangatracker/features/library/widgets/library_grid_view.dart';
import 'package:mangatracker/features/manga/dto/manga_quick_view.dto.dart';
import 'package:mangatracker/features/manga/dto/manga_recommendation_view.dto.dart';
import 'package:mangatracker/features/manga/dto/reading_status.enum.dart';
import 'package:mangatracker/features/manga/services/recommendation.service.dart';
import 'package:mangatracker/features/manga/widgets/detail_recommendations_section.dart';
import 'package:mangatracker/features/manga/widgets/manga_card.dart';
import 'package:mangatracker/features/recommendations/views/paginated_recommendations_view.dart';
import 'package:mangatracker/features/recommendations/views/recommendations_by_genre_view.dart';
import 'package:mangatracker/l10n/app_localizations.dart';
import 'package:mocktail/mocktail.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'views/home_test_harness.dart';

class _MockRecommendationService extends Mock
    implements RecommendationService {}

class _MockOfflineCacheService extends Mock implements OfflineCacheService {}

class _MockFriendsService extends Mock implements FriendsService {}

/// Titre assez long pour occuper les deux lignes de la carte.
const _longTitle = 'Le titre extrêmement long d’une œuvre interminable';

/// Six titres longs ; `read` / `total` affichent la progression bibliotheque.
List<MangaQuickViewDto> _mangas({num? read, num? total, String? type}) => [
  for (var i = 1; i <= 6; i++)
    MangaQuickViewDto(
      muId: i,
      title: '$_longTitle $i',
      year: '2014',
      rating: '8.4',
      readChapters: read,
      totalChapters: total,
      type: type,
    ),
];

/// Petit telephone (320 dp par defaut) avec texte agrandi (x1,3) : aucune
/// carte ne doit deborder de sa cellule, ni rogner son titre sous la ligne
/// annee / note.
void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUpAll(() {
    // La cover passe par le proxy d'images, qui lit MT_API_URL via dotenv.
    dotenv.testLoad(fileInput: 'MT_API_URL=https://api.test');
  });

  setUp(() async {
    await getIt.reset();
    SharedPreferences.setMockInitialValues(<String, Object>{});
  });

  tearDown(() async => getIt.reset());

  void useSmallPhone(WidgetTester tester, {double width = 320}) {
    tester.view.physicalSize = Size(width, 640);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(() {
      tester.view.resetPhysicalSize();
      tester.view.resetDevicePixelRatio();
    });
  }

  Widget app(Widget home) => MaterialApp(
    locale: const Locale('fr'),
    theme: AppTheme.light,
    localizationsDelegates: testLocalizationDelegates,
    supportedLocales: AppLocalizations.supportedLocales,
    builder:
        (context, child) => MediaQuery(
          data: MediaQuery.of(
            context,
          ).copyWith(textScaler: const TextScaler.linear(1.3)),
          child: child!,
        ),
    home: home,
  );

  /// Un titre dont le cadre est plus court que son texte est rogne : c'est
  /// le symptome « deuxieme ligne du titre sous la ligne annee / note », qui
  /// ne leve aucune exception de debordement.
  void expectNoClippedCardText(WidgetTester tester) {
    final texts = find.descendant(
      of: find.byType(MangaCard),
      matching: find.byType(RichText),
    );
    expect(texts, findsWidgets);
    for (final element in texts.evaluate()) {
      final paragraph = element.renderObject! as RenderParagraph;
      final needed = paragraph.getMaxIntrinsicHeight(paragraph.size.width);
      expect(
        paragraph.size.height,
        greaterThanOrEqualTo(needed - 0.01),
        reason: 'texte rogne : ${paragraph.text.toPlainText()}',
      );
    }
  }

  Future<void> pumpAndCheck(WidgetTester tester, Widget home) async {
    await tester.pumpWidget(app(home));
    await pumpFrames(tester);
    expect(tester.takeException(), isNull);
    expect(find.byType(MangaCard), findsWidgets);
    expectNoClippedCardText(tester);
  }

  Widget libraryGrid(List<MangaQuickViewDto> items) => Scaffold(
    body: LibraryGridView(
      grouped: {ReadingStatus.reading: items},
      isExpanded: const {ReadingStatus.reading: true},
      onToggleSection: (_) {},
      searchQuery: '',
      showDownloadedOnly: false,
      displayNameOf: (manga) => manga.title,
    ),
  );

  group('MangaCard — helpers de mise en page', () {
    test('le bloc texte est inchange a la taille de texte 1', () {
      expect(MangaCard.textBlockHeightFor(TextScaler.noScaling), 62);
      expect(
        MangaCard.textBlockHeightFor(
          TextScaler.noScaling,
          compactLibrary: true,
        ),
        MangaCard.compactTextBlockHeight,
      );
    });

    test('le bloc texte grandit avec la taille de texte', () {
      const scaler = TextScaler.linear(1.3);
      expect(MangaCard.textBlockHeightFor(scaler), 81);
      expect(
        HomeLayoutMetrics.of(320).cardHeightFor(scaler),
        HomeLayoutMetrics.of(320).coverHeight + 81,
      );
    });

    test('la cover suit le 3:4 de la colonne', () {
      expect(MangaCard.coverHeightFor(120), MangaCard.defaultCoverHeight);
      expect(
        MangaCard.gridCellWidth(288, columns: 3, spacing: 12),
        closeTo(88, 0.001),
      );
      expect(MangaCard.coverHeightFor(-4), 0);
    });
  });

  group('grilles a cellule fixe (320 dp, texte x1,3)', () {
    testWidgets('bibliotheque, vue cartes', (tester) async {
      useSmallPhone(tester);
      await pumpAndCheck(tester, libraryGrid(_mangas()));
    });

    testWidgets('bibliotheque, vue cartes avec progression', (tester) async {
      // Compteur long (« 1024 / 1100 ») : réduit pour tenir, sans déborder.
      useSmallPhone(tester);
      await pumpAndCheck(
        tester,
        libraryGrid(_mangas(read: 1024, total: 1100)),
      );
      expect(find.byType(LinearProgressIndicator), findsWidgets);
    });

    testWidgets('toutes les recommandations', (tester) async {
      useSmallPhone(tester);
      final recos = _MockRecommendationService();
      final cache = _MockOfflineCacheService();
      when(
        () => recos.getPersonalizedRecommendations(
          limit: any(named: 'limit'),
          offset: any(named: 'offset'),
          forceRefresh: any(named: 'forceRefresh'),
        ),
      ).thenAnswer((_) async => _mangas());
      when(() => cache.getCachedLibrary()).thenAnswer((_) async => _mangas());
      getIt
        ..registerSingleton<RecommendationService>(recos)
        ..registerSingleton<OfflineCacheService>(cache);

      await pumpAndCheck(tester, const PaginatedRecommendationsView());
    });

    testWidgets('bibliotheque d’un ami', (tester) async {
      useSmallPhone(tester);
      final friends = _MockFriendsService();
      when(
        () => friends.getFriendLibrary(any()),
      ).thenAnswer((_) async => _mangas());
      getIt.registerSingleton<FriendsService>(friends);

      await pumpAndCheck(
        tester,
        const FriendProfileView(friendUserId: 7, displayName: 'Ami'),
      );
    });
  });

  group('accueil et carrousels (320 dp, texte x1,3)', () {
    final metrics = HomeLayoutMetrics.of(320);

    testWidgets('carrousel d’une section', (tester) async {
      useSmallPhone(tester);
      final bloc = HomeSectionPageBloc(
        sectionId: 'year:2014',
        limit: 4,
        service: MockHomeSectionsService(),
      );
      addTearDown(bloc.close);

      await pumpAndCheck(
        tester,
        Scaffold(
          body: Align(
            alignment: Alignment.topLeft,
            child: HomeSectionCarousel(
              section: HomeSectionDto(
                id: 'year:2014',
                kind: HomeSectionKind.year,
                params: const HomeSectionParams(year: 2014),
                items: _mangas(type: 'Manhwa'),
              ),
              metrics: metrics,
              isOffline: true,
              bloc: bloc,
            ),
          ),
        ),
      );
    });

    testWidgets('grille « Tout voir »', (tester) async {
      useSmallPhone(tester);
      await pumpAndCheck(
        tester,
        Scaffold(
          body: CustomScrollView(
            slivers: [
              HomeSectionGrid(
                state: HomeSectionPageLoaded(
                  sectionId: 'year:2014',
                  kind: HomeSectionKind.year,
                  items: _mangas(type: 'Manga'),
                  page: 1,
                  total: 6,
                  hasMore: false,
                ),
                metrics: metrics,
                availableWidth: 320,
                onRetryLoadMore: () {},
              ),
            ],
          ),
        ),
      );
    });

    testWidgets('recommandations de l’accueil', (tester) async {
      useSmallPhone(tester);
      await pumpAndCheck(
        tester,
        Scaffold(
          body: SingleChildScrollView(
            child: HomeRecommendationsSection(
              state: HomePageLoaded(
                popularMangas: const [],
                newMangas: const [],
                trendingMangas: const [],
                recommendations: _mangas(),
              ),
              metrics: metrics,
              onDismissed: (_) {},
              onRestored: (_) {},
            ),
          ),
        ),
      );
    });

    testWidgets('squelette de l’accueil', (tester) async {
      useSmallPhone(tester);
      await tester.pumpWidget(
        app(
          Scaffold(
            body: SingleChildScrollView(
              child: HomeSectionsSkeleton(metrics: metrics),
            ),
          ),
        ),
      );
      await pumpFrames(tester);
      expect(tester.takeException(), isNull);
    });

    testWidgets('oeuvres d’un auteur', (tester) async {
      useSmallPhone(tester);
      await pumpAndCheck(
        tester,
        Scaffold(
          body: CustomScrollView(
            slivers: [
              AuthorWorksGrid(
                works: _mangas(type: 'Manga'),
                metrics: metrics,
                availableWidth: 320,
              ),
            ],
          ),
        ),
      );
    });

    testWidgets('titres similaires de la fiche', (tester) async {
      useSmallPhone(tester);
      await pumpAndCheck(
        tester,
        Scaffold(
          body: SingleChildScrollView(
            child: DetailRecommendationsSection(
              recommendations: [
                for (var i = 1; i <= 4; i++)
                  MangaRecommendationView(
                    muId: i,
                    title: '$_longTitle $i',
                    year: '2014',
                    rating: '8.4',
                  ),
              ],
            ),
          ),
        ),
      );
    });

    testWidgets('recommandations par genre', (tester) async {
      useSmallPhone(tester);
      final recos = _MockRecommendationService();
      when(
        () => recos.getRecommendationsByGenre(
          topGenres: any(named: 'topGenres'),
          perGenre: any(named: 'perGenre'),
        ),
      ).thenAnswer(
        (_) async => {
          'Psychological thriller': _mangas(),
          'Romance': _mangas(),
        },
      );
      when(
        () => recos.getSleeperHits(limit: any(named: 'limit')),
      ).thenAnswer((_) async => _mangas());
      getIt.registerSingleton<RecommendationService>(recos);

      await pumpAndCheck(tester, const RecommendationsByGenreView());
    });
  });
}
