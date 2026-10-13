import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mangatracker/core/network/api_exception.dart';
import 'package:mangatracker/features/comments/bloc/comments_bloc.dart';
import 'package:mangatracker/features/comments/dto/comment.dto.dart';
import 'package:mangatracker/features/comments/services/comments.service.dart';
import 'package:mangatracker/features/comments/widgets/comments_section.dart';
import 'package:mocktail/mocktail.dart';

import '../home/views/home_test_harness.dart';

class _Service extends Mock implements CommentsService {}

CommentDto _comment(int id, int authorId, String author) => CommentDto(
      id: id,
      content: 'Commentaire $id',
      authorId: authorId,
      authorUsername: author,
      isDeleted: false,
      replyCount: 0,
      createdAt: DateTime.now(),
      updatedAt: DateTime.now(),
    );

/// « Supprimer » sur MES commentaires seulement (un autre répondait 403) ;
/// « Signaler » sur ceux des autres, avec confirmation.
void main() {
  late _Service service;

  setUpAll(() => registerFallbackValue(CommentSort.recent));

  setUp(() {
    service = _Service();
    when(() => service.listForManga(1, sort: any(named: 'sort'))).thenAnswer(
      (_) async => CommentsPage(
        items: [_comment(10, 7, 'moi'), _comment(11, 8, 'lea')],
        page: 1,
        hasMore: false,
      ),
    );
  });

  Widget section({Future<int?> Function()? me}) => frRouterHarness(
        home: Scaffold(
          body: SingleChildScrollView(
            child: CommentsSection(
              muId: 1,
              createBloc: () => CommentsBloc(
                1,
                service: service,
                currentUserId: me ?? () async => 7,
              ),
            ),
          ),
        ),
      );

  Future<void> openMenuOf(WidgetTester tester, int index) async {
    await tester.tap(find.byIcon(Icons.more_vert).at(index));
    await pumpFrames(tester);
  }

  testWidgets('mon commentaire : Supprimer, pas Signaler', (tester) async {
    await tester.pumpWidget(section());
    await pumpFrames(tester);
    await openMenuOf(tester, 0);
    expect(find.text('Supprimer'), findsOneWidget);
    expect(find.text('Signaler'), findsNothing);
  });

  testWidgets('commentaire d\'un autre : Signaler (confirmé), jamais '
      'Supprimer', (tester) async {
    when(() => service.report(11, reason: any(named: 'reason')))
        .thenAnswer((_) async {});
    await tester.pumpWidget(section());
    await pumpFrames(tester);
    await openMenuOf(tester, 1);
    expect(find.text('Supprimer'), findsNothing);

    await tester.tap(find.text('Signaler'));
    await pumpFrames(tester);
    expect(find.text('Signaler ce commentaire ?'), findsOneWidget);
    verifyNever(() => service.report(any(), reason: any(named: 'reason')));

    await tester.tap(find.widgetWithText(FilledButton, 'Signaler'));
    await pumpFrames(tester);
    verify(() => service.report(11, reason: any(named: 'reason'))).called(1);
    expect(find.text('Merci, le commentaire a été signalé.'), findsOneWidget);
  });

  testWidgets('utilisateur inconnu : personne ne peut « Supprimer »',
      (tester) async {
    await tester.pumpWidget(section(me: () async => null));
    await pumpFrames(tester);
    await openMenuOf(tester, 0);
    expect(find.text('Supprimer'), findsNothing);
    expect(find.text('Signaler'), findsOneWidget);
  });

  testWidgets('échec d\'une action : message lisible, jamais le corps brut',
      (tester) async {
    when(() => service.report(11, reason: any(named: 'reason'))).thenThrow(
      const ApiException(429),
    );
    await tester.pumpWidget(section());
    await pumpFrames(tester);
    await openMenuOf(tester, 1);
    await tester.tap(find.text('Signaler'));
    await pumpFrames(tester);
    await tester.tap(find.widgetWithText(FilledButton, 'Signaler'));
    await pumpFrames(tester);
    expect(find.text('Trop de tentatives, réessayez dans un instant'),
        findsOneWidget);
  });
}
