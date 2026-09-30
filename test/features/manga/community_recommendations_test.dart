import 'dart:async';
import 'dart:convert';

import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart';
import 'package:mangatracker/core/network/http_service.dart';
import 'package:mangatracker/core/network/network_compat.dart';
import 'package:mangatracker/features/manga/bloc/community_recommendations_cubit.dart';
import 'package:mangatracker/features/manga/dto/community_recommendation.dto.dart';
import 'package:mangatracker/features/manga/services/community.service.dart';
import 'package:mocktail/mocktail.dart';

class MockHttpService extends Mock implements HttpService {}

class MockCommunityService extends Mock implements CommunityService {}

CommunityRecommendationDto reco(
  num muId, {
  int mu = 0,
  int app = 0,
  bool mine = false,
}) => CommunityRecommendationDto(
  muId: muId,
  title: 'Titre $muId',
  muVotes: mu,
  appVotes: app,
  totalVotes: mu + app,
  recommendedByMe: mine,
);

void main() {
  setUpAll(() {
    dotenv.testLoad(fileInput: 'MT_API_URL=https://api.test');
    registerFallbackValue(Uri());
  });

  group('CommunityService', () {
    late MockHttpService http;
    late CommunityService service;

    setUp(() {
      http = MockHttpService();
      service = CommunityService(httpService: http);
    });

    test('lit la liste fusionnée', () async {
      when(() => http.getWithAuthTokens(any())).thenAnswer(
        (_) async => Response(
          jsonEncode({
            'sourceMuId': 1,
            'items': [
              {
                'muId': 2,
                'title': 'Naruto',
                'year': 1999,
                'rating': 8.1,
                'muVotes': 72,
                'appVotes': 3,
                'totalVotes': 75,
                'recommendedByMe': true,
              },
            ],
          }),
          200,
        ),
      );
      final items = await service.getRecommendations(1);
      expect(items.single.totalVotes, 75);
      expect(items.single.recommendedByMe, isTrue);
      expect(items.single.yearLabel, '1999');
    });

    test('quota dépassé → throttled ; œuvre invalide → invalid', () async {
      when(
        () => http.putWithAuthTokens(
          any(),
          headers: any(named: 'headers'),
          body: any(named: 'body'),
        ),
      ).thenAnswer((_) async => Response('', HttpStatus.tooManyRequests));
      await expectLater(
        service.recommend(1, 2),
        throwsA(
          isA<CommunityException>().having(
            (e) => e.failure,
            'failure',
            CommunityFailure.throttled,
          ),
        ),
      );
      when(
        () => http.deleteWithAuthTokens(any()),
      ).thenAnswer((_) async => Response('', HttpStatus.badRequest));
      await expectLater(
        service.unrecommend(1, 1),
        throwsA(
          isA<CommunityException>().having(
            (e) => e.failure,
            'failure',
            CommunityFailure.invalid,
          ),
        ),
      );
    });

    test(
      "recommander n'envoie aucun titre : le serveur le tient de MangaUpdates",
      () async {
        Object? sentBody = 'non appelé';
        when(
          () => http.putWithAuthTokens(
            any(),
            headers: any(named: 'headers'),
            body: any(named: 'body'),
          ),
        ).thenAnswer((invocation) async {
          sentBody = invocation.namedArguments[#body];
          return Response(
            jsonEncode({
              'muId': 9,
              'title': 'Bleach',
              'appVotes': 1,
              'totalVotes': 1,
              'recommendedByMe': true,
            }),
            200,
          );
        });
        final item = await service.recommend(1, 9);
        expect(sentBody, isNull);
        expect(item.title, 'Bleach');
      },
    );
  });

  group('CommunityRecommendationsCubit', () {
    late MockCommunityService service;

    setUp(() => service = MockCommunityService());

    test('feuille fermée pendant le vote : le succès est quand même annoncé',
        () async {
      final pending = Completer<CommunityRecommendationDto>();
      when(() => service.getRecommendations(1)).thenAnswer((_) async => []);
      when(() => service.recommend(1, 9)).thenAnswer((_) => pending.future);
      final cubit = CommunityRecommendationsCubit(
        sourceMuId: 1,
        service: service,
      );
      await cubit.load();
      final vote = cubit.recommend(9);
      await cubit.close();
      pending.complete(reco(9, app: 1, mine: true));
      expect(await vote, CommunityVoteResult.added);
    });

    test('charge la liste', () async {
      when(
        () => service.getRecommendations(1),
      ).thenAnswer((_) async => [reco(2, mu: 72)]);
      final cubit = CommunityRecommendationsCubit(
        sourceMuId: 1,
        service: service,
      );
      addTearDown(cubit.close);
      await cubit.load();
      expect(cubit.state.loading, isFalse);
      expect(cubit.state.items.single.totalVotes, 72);
    });

    test('recommander incrémente et retrie ; retirer décrémente', () async {
      when(
        () => service.getRecommendations(1),
      ).thenAnswer((_) async => [reco(2, mu: 5), reco(3, mu: 5)]);
      when(
        () => service.recommend(1, 3),
      ).thenAnswer((_) async => reco(3, mu: 5, app: 1, mine: true));
      when(
        () => service.unrecommend(1, 3),
      ).thenAnswer((_) async => reco(3, mu: 5));
      final cubit = CommunityRecommendationsCubit(
        sourceMuId: 1,
        service: service,
      );
      addTearDown(cubit.close);
      await cubit.load();

      expect(
        await cubit.toggle(cubit.state.items.last),
        CommunityVoteResult.added,
      );
      expect(cubit.state.items.map((i) => i.muId), [3, 2]);
      expect(cubit.state.items.first.recommendedByMe, isTrue);

      expect(
        await cubit.toggle(cubit.state.items.first),
        CommunityVoteResult.removed,
      );
      expect(cubit.state.items.map((i) => i.totalVotes), [5, 5]);
    });

    test('une nouvelle œuvre choisie apparaît dans la liste', () async {
      when(() => service.getRecommendations(1)).thenAnswer((_) async => []);
      when(
        () => service.recommend(1, 9),
      ).thenAnswer((_) async => reco(9, app: 1, mine: true));
      final cubit = CommunityRecommendationsCubit(
        sourceMuId: 1,
        service: service,
      );
      addTearDown(cubit.close);
      await cubit.load();
      expect(
        await cubit.recommend(9),
        CommunityVoteResult.added,
      );
      expect(cubit.state.items.single.muId, 9);
    });

    test('quota dépassé : résultat throttled, liste inchangée', () async {
      when(
        () => service.getRecommendations(1),
      ).thenAnswer((_) async => [reco(2, mu: 5)]);
      when(() => service.recommend(1, 2)).thenThrow(
        const CommunityException(
          CommunityFailure.throttled,
          HttpStatus.tooManyRequests,
        ),
      );
      final cubit = CommunityRecommendationsCubit(
        sourceMuId: 1,
        service: service,
      );
      addTearDown(cubit.close);
      await cubit.load();
      expect(
        await cubit.toggle(cubit.state.items.single),
        CommunityVoteResult.throttled,
      );
      expect(cubit.state.items.single.totalVotes, 5);
      expect(cubit.state.pending, isEmpty);
    });

    test('hors ligne au chargement : erreur marquée hors ligne', () async {
      when(
        () => service.getRecommendations(1),
      ).thenThrow(const SocketException('offline'));
      final cubit = CommunityRecommendationsCubit(
        sourceMuId: 1,
        service: service,
      );
      addTearDown(cubit.close);
      await cubit.load();
      expect(cubit.state.failed, isTrue);
      expect(cubit.state.isOffline, isTrue);
    });
  });
}
