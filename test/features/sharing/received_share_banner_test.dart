import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mangatracker/features/sharing/dto/share.dto.dart';
import 'package:mangatracker/features/sharing/widgets/received_share_banner.dart';

import '../home/views/home_test_harness.dart';

MangaShareDto _share(int id, int senderId, String sender, String muId,
        {String? message, int day = 1}) =>
    MangaShareDto(
      id: id,
      senderId: senderId,
      senderUsername: sender,
      mangaMuId: muId,
      mangaTitle: 'Titre',
      message: message,
      createdAt: DateTime(2026, 10, day),
    );

/// Bandeau « Recommandé par » de la fiche : un ami m'a envoyé ce titre.
void main() {
  test('résumé : expéditeurs distincts du plus récent au plus ancien, '
      'dernier message non vide', () {
    final summary = ReceivedSharesSummary.forManga([
      _share(1, 7, 'lea', '42', message: 'Tu vas adorer', day: 1),
      _share(2, 8, 'tom', '42', message: '  ', day: 3),
      _share(3, 7, 'lea', '42', day: 2),
      _share(4, 9, 'max', '99', message: 'autre titre', day: 4),
    ], 42)!;
    expect(summary.senders, ['tom', 'lea']);
    expect(summary.message, 'Tu vas adorer');
    expect(ReceivedSharesSummary.forManga([_share(1, 7, 'lea', '99')], 42),
        isNull);
  });

  testWidgets('affiche « Recommandé par » et le message', (tester) async {
    await tester.pumpWidget(frRouterHarness(
      home: Scaffold(
        body: ReceivedShareBanner(
          muId: 42,
          loadInbox: () async => [
            _share(1, 7, 'lea', '42', message: 'Tu vas adorer', day: 2),
            _share(2, 8, 'tom', '42', day: 1),
          ],
        ),
      ),
    ));
    await pumpFrames(tester);

    expect(find.text('Recommandé par lea et 1 autre ami'), findsOneWidget);
    expect(find.text('« Tu vas adorer »'), findsOneWidget);
  });

  testWidgets('invisible si personne ne l\'a recommandé ou en cas d\'échec',
      (tester) async {
    await tester.pumpWidget(frRouterHarness(
      home: Scaffold(
        body: Column(children: [
          ReceivedShareBanner(muId: 42, loadInbox: () async => const []),
          ReceivedShareBanner(
            muId: 42,
            loadInbox: () async => throw Exception('réseau'),
          ),
        ]),
      ),
    ));
    await pumpFrames(tester);
    expect(find.textContaining('Recommandé par'), findsNothing);
  });
}
