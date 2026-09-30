import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart';
import 'package:mangatracker/core/network/http_service.dart';
import 'package:mangatracker/core/service_locator/service_locator.dart';
import 'package:mangatracker/features/manga/widgets/community_recommendations_sheet.dart';
import 'package:mangatracker/l10n/app_localizations.dart';
import 'package:mocktail/mocktail.dart';

class MockHttpService extends Mock implements HttpService {}

Map<String, dynamic> _item({required bool mine}) => {
  'muId': 2,
  'title': 'Naruto',
  'muVotes': 72,
  'appVotes': mine ? 1 : 0,
  'totalVotes': mine ? 73 : 72,
  'recommendedByMe': mine,
};

void main() {
  setUpAll(() {
    dotenv.testLoad(fileInput: 'MT_API_URL=https://api.example.test');
    registerFallbackValue(Uri());
  });

  tearDown(() => getIt.reset());

  testWidgets(
    'le message de vote s\'affiche au-dessus de la feuille, pas dessous',
    (tester) async {
      final http = MockHttpService();
      getIt.registerSingleton<HttpService>(http);
      when(() => http.getWithAuthTokens(any())).thenAnswer(
        (_) async => Response(
          jsonEncode({
            'sourceMuId': 1,
            'items': [_item(mine: false)],
          }),
          200,
        ),
      );
      when(
        () => http.putWithAuthTokens(
          any(),
          headers: any(named: 'headers'),
          body: any(named: 'body'),
        ),
      ).thenAnswer((_) async => Response(jsonEncode(_item(mine: true)), 200));

      await tester.pumpWidget(
        MaterialApp(
          locale: const Locale('fr'),
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          home: Scaffold(
            body: Builder(
              builder:
                  (context) => TextButton(
                    onPressed:
                        () => showCommunityRecommendationsSheet(
                          context,
                          muId: 1,
                        ),
                    child: const Text('open'),
                  ),
            ),
          ),
        ),
      );
      await tester.tap(find.text('open'));
      // Pas de pumpAndSettle : la couverture (chargement réseau) anime.
      for (var i = 0; i < 10; i++) {
        await tester.pump(const Duration(milliseconds: 100));
      }

      await tester.tap(find.byTooltip('Je recommande aussi'));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 750));

      expect(
        find
            .text('Merci ! Votre recommandation est enregistrée')
            .hitTestable(),
        findsOneWidget,
      );
    },
  );
}
