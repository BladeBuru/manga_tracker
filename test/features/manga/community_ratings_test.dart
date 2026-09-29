import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mangatracker/core/service_locator/service_locator.dart';
import 'package:mangatracker/core/services/cache_helper_service.dart';
import 'package:mangatracker/core/services/connectivity_service.dart';
import 'package:mangatracker/core/services/offline_cache_service.dart';
import 'package:mangatracker/features/library/services/chapter_report.service.dart';
import 'package:mangatracker/features/library/services/library.service.dart';
import 'package:mangatracker/features/manga/bloc/detail_bloc.dart';
import 'package:mangatracker/features/manga/bloc/detail_event.dart';
import 'package:mangatracker/features/manga/bloc/detail_state.dart';
import 'package:mangatracker/features/manga/dto/author.dto.dart';
import 'package:mangatracker/features/manga/dto/manga_detail.dto.dart';
import 'package:mangatracker/features/manga/dto/rating_summary.dto.dart';
import 'package:mangatracker/features/manga/services/community.service.dart';
import 'package:mangatracker/features/manga/services/manga.service.dart';
import 'package:mangatracker/features/manga/widgets/detail_info_card.dart';
import 'package:mangatracker/features/manga/widgets/detail_rating_breakdown.dart';
import 'package:mangatracker/l10n/app_localizations.dart';
import 'package:mocktail/mocktail.dart';

class MockMangaService extends Mock implements MangaService {}

class MockLibraryService extends Mock implements LibraryService {}

class MockChapterReportService extends Mock implements ChapterReportService {}

class MockCacheHelperService extends Mock implements CacheHelperService {}

class MockConnectivityService extends Mock implements ConnectivityService {}

class MockCommunityService extends Mock implements CommunityService {}

Widget frApp(Widget child) => MaterialApp(
  locale: const Locale('fr'),
  localizationsDelegates: const [
    AppLocalizations.delegate,
    GlobalMaterialLocalizations.delegate,
    GlobalWidgetsLocalizations.delegate,
    GlobalCupertinoLocalizations.delegate,
  ],
  supportedLocales: AppLocalizations.supportedLocales,
  home: Scaffold(body: SingleChildScrollView(child: child)),
);

void main() {
  group('MangaDetailDto — note globale', () {
    test(
      'lit les votes MangaUpdates et le total, et affiche la note globale',
      () {
        final dto = MangaDetailDto.fromJson({
          'muId': 1,
          'title': 'One Piece',
          'year': '1997',
          'rating': 8.9,
          'totalChapters': 1100,
          'aggregated_rating': 8.91,
          'mu_rating_votes': 5000,
          'total_rating_votes': 5012,
        });
        expect(dto.displayRating, '8.91');
        expect(dto.muRatingVotes, 5000);
        expect(dto.totalRatingVotes, 5012);
        expect(dto.muRating, 8.9);
        // Le cache hors ligne conserve les votes.
        final back = MangaDetailDto.fromJson(dto.toJson());
        expect(back.totalRatingVotes, 5012);
        expect(back.muRatingVotes, 5000);
      },
    );

    test('sans note globale, repli sur la note MangaUpdates', () {
      final dto = MangaDetailDto.fromJson({
        'muId': 1,
        'title': 't',
        'year': '2000',
        'rating': 7.5,
      });
      expect(dto.displayRating, '7.5');
      expect(dto.totalRatingVotes, 0);
      expect(dto.copyWith(aggregatedRating: 8.0).displayRating, '8');
    });
  });

  group('DetailBloc — note globale après un vote', () {
    late MockMangaService mangaService;
    late MockLibraryService libraryService;
    late MockCacheHelperService cacheHelper;
    late MockConnectivityService connectivity;
    late MockCommunityService community;
    late StreamController<bool> connectivityController;

    setUp(() {
      mangaService = MockMangaService();
      libraryService = MockLibraryService();
      cacheHelper = MockCacheHelperService();
      connectivity = MockConnectivityService();
      community = MockCommunityService();
      connectivityController = StreamController<bool>.broadcast();
      when(
        () => connectivity.connectivityStream,
      ).thenAnswer((_) => connectivityController.stream);
      when(() => connectivity.isConnected).thenReturn(true);
      when(
        () => libraryService.getLibraryEntry(any()),
      ).thenAnswer((_) async => null);
      when(
        () => cacheHelper.getOfflineQueue(),
      ).thenAnswer((_) async => <OfflineAction>[]);
      when(
        () => cacheHelper.getCachedMangaDetail(any()),
      ).thenAnswer((_) async => null);
      when(
        () => cacheHelper.loadMangaDetail(
          muId: any(named: 'muId'),
          networkCall: any(named: 'networkCall'),
        ),
      ).thenAnswer((invocation) async {
        final call =
            invocation.namedArguments[#networkCall]
                as Future<MangaDetailDto> Function();
        return call();
      });
      when(() => mangaService.getMangaDetail(any())).thenAnswer(
        (_) async => const MangaDetailDto(
          muId: 42,
          title: 'Naruto',
          year: '1999',
          rating: '8.0',
          totalChapters: 700,
          inLibrary: true,
          aggregatedRating: 8.0,
          muRatingVotes: 3,
          totalRatingVotes: 3,
        ),
      );
      getIt.registerSingleton<MangaService>(mangaService);
      getIt.registerSingleton<LibraryService>(libraryService);
      getIt.registerSingleton<ChapterReportService>(MockChapterReportService());
      getIt.registerSingleton<CacheHelperService>(cacheHelper);
      getIt.registerSingleton<ConnectivityService>(connectivity);
    });

    tearDown(() async {
      await connectivityController.close();
      await getIt.reset();
    });

    test(
      'le vote est pris en compte dans la note globale et le total',
      () async {
        when(
          () => libraryService.updateRating(42, 4),
        ).thenAnswer((_) async => true);
        when(() => community.getRatingSummary(42)).thenAnswer(
          (_) async => const RatingSummaryDto(
            muRating: 8,
            muRatingVotes: 3,
            communityRating: 4,
            communityRatingCount: 1,
            aggregatedRating: 7,
            totalRatingVotes: 4,
          ),
        );
        final bloc = DetailBloc(communityService: community);
        addTearDown(bloc.close);
        bloc.add(const LoadMangaDetail(42));
        await bloc.stream.firstWhere((s) => s is DetailLoaded);

        bloc.add(const UpdateUserRating(42, 4));
        final state = await bloc.stream.firstWhere(
          (s) => s is DetailLoaded && s.mangaDetail.totalRatingVotes == 4,
        );

        final detail = (state as DetailLoaded).mangaDetail;
        expect(detail.userRating, 4);
        expect(detail.displayRating, '7');
        expect(detail.communityRatingCount, 1);
      },
    );

    test('vote refusé : note rétablie, synthèse non demandée', () async {
      when(
        () => libraryService.updateRating(42, 4),
      ).thenAnswer((_) async => false);
      final bloc = DetailBloc(communityService: community);
      addTearDown(bloc.close);
      bloc.add(const LoadMangaDetail(42));
      await bloc.stream.firstWhere((s) => s is DetailLoaded);

      bloc.add(const UpdateUserRating(42, 4));
      await Future<void>.delayed(const Duration(milliseconds: 50));

      expect((bloc.state as DetailLoaded).mangaDetail.userRating, 0);
      verifyNever(() => community.getRatingSummary(any()));
    });
  });

  group('Affichage', () {
    testWidgets(
      'la carte d\'infos montre la note globale et le total des votes',
      (tester) async {
        AuthorDto? opened;
        await tester.pumpWidget(
          frApp(
            DetailInfoCard(
              totalChapters: 700,
              rating: '8.61',
              ratingVotes: 5012,
              isCompleted: true,
              year: '1999',
              authors: const [
                AuthorDto(
                  name: 'KISHIMOTO Masashi',
                  authorId: 77,
                  type: 'Author',
                ),
                AuthorDto(name: 'Inconnu', authorId: 0, type: 'Author'),
              ],
              artists: const [],
              onPersonTap: (a) => opened = a,
            ),
          ),
        );

        expect(find.text('8.61'), findsOneWidget);
        expect(find.text('5012 votes'), findsOneWidget);

        await tester.tap(find.textContaining('KISHIMOTO'));
        expect(opened?.authorId, 77);

        opened = null;
        await tester.tap(find.textContaining('Inconnu'), warnIfMissed: false);
        expect(opened, isNull, reason: 'sans fiche MangaUpdates, pas de lien');
      },
    );

    testWidgets(
      'le détail de la note montre chaque source et la note globale',
      (tester) async {
        await tester.pumpWidget(
          frApp(
            const DetailRatingBreakdown(
              muRating: 8,
              muRatingVotes: 3,
              appRating: 4,
              appRatingCount: 1,
              globalRating: 7,
              totalRatingVotes: 4,
            ),
          ),
        );

        expect(find.textContaining('MangaUpdates'), findsWidgets);
        expect(find.textContaining('Manga Tracker'), findsWidgets);
        expect(find.textContaining('Note globale'), findsOneWidget);
        expect(find.text('7'), findsOneWidget);
      },
    );
  });
}
