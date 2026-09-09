import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:mangatracker/core/services/cache_helper_service.dart';
import 'package:mangatracker/features/home/helpers/homepage_data_loader.dart';
import 'package:mangatracker/features/manga/dto/manga_quick_view.dto.dart';
import 'package:mangatracker/features/manga/services/manga.service.dart';
import 'package:mangatracker/features/manga/services/recommendation.service.dart';
import 'package:mangatracker/features/profile/services/user.service.dart';
import 'package:mangatracker/features/recommendations/recommendations_paging.dart';
import 'package:mocktail/mocktail.dart';

class MockRecommendationService extends Mock implements RecommendationService {}

class MockMangaService extends Mock implements MangaService {}

class MockUserService extends Mock implements UserService {}

class MockCacheHelperService extends Mock implements CacheHelperService {}

/// Invariant du chantier « ordre des recommandations » :
///
/// > ce que l'utilisateur voit sur l'accueil est le **debut** de ce qu'il
/// > voit en depliant « Voir tout ».
///
/// Le serveur ne le garantit pas : `limit` fait partie de sa cle de cache,
/// donc deux tailles de page produisent deux classements calcules
/// independamment (et non deterministes). La parade cote application est de
/// ne demander qu'**une seule** page canonique et d'en deriver les deux
/// ecrans. Ces tests verrouillent cette logique — aucun n'appelle le reseau.
void main() {
  List<MangaQuickViewDto> canonicalPage(int count) => List.generate(
        count,
        (i) => MangaQuickViewDto(
          muId: i + 1,
          title: 'Titre ${i + 1}',
          year: '2020',
          rating: '7',
        ),
      );

  group('page canonique — l\'accueil est un prefixe de « Voir tout »', () {
    test('l\'apercu de l\'accueil est le prefixe strict de la page canonique',
        () {
      final page = canonicalPage(kRecommendationsPageSize);
      final preview = homeRecommendationsPreview(page);

      expect(preview, hasLength(kHomeRecommendationsPreview));
      expect(
        preview,
        equals(page.take(kHomeRecommendationsPreview).toList()),
        reason: 'un re-tri ou un filtre casserait l\'invariant',
      );
      for (var i = 0; i < preview.length; i++) {
        expect(preview[i].muId, page[i].muId,
            reason: 'position $i : meme titre, meme rang');
      }
    });

    test('la propriete tient pour toutes les tailles de page rencontrees', () {
      for (final size in const [0, 1, 5, 9, 10, 11, 37, 50]) {
        final page = canonicalPage(size);
        final preview = homeRecommendationsPreview(page);

        expect(preview.length,
            size < kHomeRecommendationsPreview ? size : kHomeRecommendationsPreview);
        for (var i = 0; i < preview.length; i++) {
          expect(preview[i].muId, page[i].muId,
              reason: 'taille $size, position $i');
        }
      }
    });

    test('une page plus courte que l\'apercu est servie telle quelle', () {
      final page = canonicalPage(4);
      expect(homeRecommendationsPreview(page).map((m) => m.muId),
          page.map((m) => m.muId));
    });

    test('l\'apercu ne peut pas depasser la page canonique', () {
      expect(kHomeRecommendationsPreview, lessThanOrEqualTo(kRecommendationsPageSize));
      expect(kHomeRecommendationsPreview, greaterThan(0));
    });
  });

  group('l\'accueil demande la page canonique, pas une page plus courte', () {
    late MockRecommendationService recommendationService;
    late HomePageDataLoader loader;

    setUp(() {
      recommendationService = MockRecommendationService();
      loader = HomePageDataLoader(
        mangaService: MockMangaService(),
        recommendationService: recommendationService,
        userService: MockUserService(),
        cacheHelper: MockCacheHelperService(),
      );
    });

    test('loadRecommendations demande kRecommendationsPageSize elements',
        () async {
      when(() => recommendationService.getPersonalizedRecommendations(
            limit: any(named: 'limit'),
            offset: any(named: 'offset'),
            forceRefresh: any(named: 'forceRefresh'),
          )).thenAnswer((_) async => canonicalPage(kRecommendationsPageSize));

      final result = await loader.loadRecommendations();

      expect(result, hasLength(kRecommendationsPageSize));
      final captured = verify(
        () => recommendationService.getPersonalizedRecommendations(
          limit: captureAny(named: 'limit'),
          offset: any(named: 'offset'),
          forceRefresh: any(named: 'forceRefresh'),
        ),
      ).captured;
      expect(captured.single, kRecommendationsPageSize,
          reason: 'demander 10 ici declencherait un second classement serveur');
    });

    test('une erreur reseau laisse l\'accueil sans recommandations, sans lever',
        () async {
      when(() => recommendationService.getPersonalizedRecommendations(
            limit: any(named: 'limit'),
            offset: any(named: 'offset'),
            forceRefresh: any(named: 'forceRefresh'),
          )).thenThrow(Exception('reseau coupe'));

      expect(await loader.loadRecommendations(), isEmpty);
    });
  });

  group('fil de detente — les deux ecrans partagent la meme constante', () {
    String source(String path) {
      final file = File(path);
      expect(file.existsSync(), isTrue, reason: 'Fichier introuvable : $path');
      return file.readAsStringSync();
    }

    test('la page « Tout voir » n\'a plus de taille de page en dur', () {
      final code =
          source('lib/features/recommendations/views/paginated_recommendations_view.dart');
      expect(code, contains('kRecommendationsPageSize'));
      expect(
        code,
        isNot(contains('_pageSize = 50')),
        reason: 'une taille en dur peut redevenir differente de celle de l\'accueil',
      );
    });

    test('l\'accueil demande la constante partagee', () {
      final code = source('lib/features/home/helpers/homepage_data_loader.dart');
      expect(code, contains('kRecommendationsPageSize'));
      expect(
        code,
        isNot(contains('limit: 10')),
        reason: 'c\'est exactement la divergence que ce chantier corrige',
      );
    });

    test('le carrousel de l\'accueil tronque, il ne re-selectionne pas', () {
      final code =
          source('lib/features/home/widgets/home_recommendations_section.dart');
      expect(code, contains('homeRecommendationsPreview'));
      expect(code, isNot(contains('.take(10)')));
    });
  });
}
