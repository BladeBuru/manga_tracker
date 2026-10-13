import 'package:flutter_test/flutter_test.dart';
import 'package:mangatracker/features/library/services/chapter_progress.service.dart';
import 'package:mangatracker/features/library/services/chapter_progress_result.dart';
import 'package:mangatracker/features/sharing/bloc/reading_groups_bloc.dart';
import 'package:mangatracker/features/sharing/dto/reading_group.dto.dart';
import 'package:mangatracker/features/sharing/services/reading_groups.service.dart';
import 'package:mocktail/mocktail.dart';

class MockReadingGroupsService extends Mock implements ReadingGroupsService {}

class MockChapterProgressService extends Mock
    implements ChapterProgressService {}

ReadingGroupDto groupWith({required int mine, int friend = 124}) =>
    ReadingGroupDto(
      id: 7,
      ownerId: 1,
      mangaMuId: '151',
      mangaTitle: 'Solo Leveling',
      createdAt: DateTime(2026),
      members: [
        ReadingGroupMemberDto(
          userId: 1,
          username: 'moi',
          readChapters: mine,
          joinedAt: DateTime(2026),
        ),
        ReadingGroupMemberDto(
          userId: 2,
          username: 'lea',
          readChapters: friend,
          joinedAt: DateTime(2026),
        ),
      ],
    );

int? myChapters(ReadingGroupDetailState state) =>
    (state as ReadingGroupDetailLoaded).group.members.first.readChapters;

void main() {
  late MockReadingGroupsService service;
  late MockChapterProgressService progress;

  setUp(() {
    service = MockReadingGroupsService();
    progress = MockChapterProgressService();
  });

  ReadingGroupDetailBloc build({
    Duration pollInterval = const Duration(seconds: 30),
  }) {
    final bloc = ReadingGroupDetailBloc(
      7,
      service: service,
      progressService: progress,
      pollInterval: pollInterval,
    );
    addTearDown(bloc.close);
    return bloc;
  }

  Future<ReadingGroupDetailBloc> loaded({
    Duration pollInterval = const Duration(seconds: 30),
  }) async {
    final bloc = build(pollInterval: pollInterval);
    bloc.add(const LoadGroupDetail());
    await bloc.stream.firstWhere((s) => s is ReadingGroupDetailLoaded);
    return bloc;
  }

  void stubSave(ChapterProgressResult result) {
    when(() => progress.save(
          any(),
          any(),
          autoReportIfAboveTotal: any(named: 'autoReportIfAboveTotal'),
          addToLibraryIfMissing: any(named: 'addToLibraryIfMissing'),
          origin: any(named: 'origin'),
        )).thenAnswer((_) async => result);
  }

  test('« Ma progression » enregistrée → groupe relu tout de suite', () async {
    var fetches = 0;
    when(() => service.getGroup(7)).thenAnswer(
      (_) async => groupWith(mine: fetches++ == 0 ? 105 : 124),
    );
    stubSave(const ChapterProgressSaved());
    final bloc = await loaded();

    bloc.add(const UpdateMyGroupProgress(124));
    final saving = await bloc.stream.firstWhere(
      (s) => s is ReadingGroupDetailLoaded && s.isSavingProgress,
    );
    expect(myChapters(saving), 105);
    final outcome = await bloc.stream
        .firstWhere((s) => s is ReadingGroupProgressUpdated)
        as ReadingGroupProgressUpdated;

    expect(outcome.result, const ChapterProgressSaved());
    expect(outcome.readChapters, 124);
    expect(myChapters(outcome), 124,
        reason: 'avant : l\'ancienne valeur restait affichée');
    expect(outcome.isSavingProgress, isFalse);
    // Geste explicite : rattrapage du total et ajout à la bibliothèque.
    verify(() => progress.save(
          151,
          124,
          autoReportIfAboveTotal: true,
          addToLibraryIfMissing: true,
          origin: bloc,
        )).called(1);
    verify(() => service.getGroup(7)).called(2);
  });

  test('refus → la page reste affichée avec la raison typée', () async {
    when(() => service.getGroup(7))
        .thenAnswer((_) async => groupWith(mine: 105));
    stubSave(const ChapterProgressThrottled());
    final bloc = await loaded();

    bloc.add(const UpdateMyGroupProgress(124));
    final outcome = await bloc.stream
        .firstWhere((s) => s is ReadingGroupProgressUpdated)
        as ReadingGroupProgressUpdated;

    expect(outcome.result, const ChapterProgressThrottled());
    expect(myChapters(outcome), 105);
    verify(() => service.getGroup(7)).called(1);
  });

  test('deux refus identiques produisent deux issues distinctes', () async {
    when(() => service.getGroup(7))
        .thenAnswer((_) async => groupWith(mine: 105));
    stubSave(const ChapterProgressThrottled());
    final bloc = await loaded();
    final outcomes = <ReadingGroupProgressUpdated>[];
    final sub = bloc.stream
        .where((s) => s is ReadingGroupProgressUpdated)
        .cast<ReadingGroupProgressUpdated>()
        .listen(outcomes.add);

    bloc.add(const UpdateMyGroupProgress(124));
    await bloc.stream.firstWhere((s) => s is ReadingGroupProgressUpdated);
    bloc.add(const UpdateMyGroupProgress(124));
    await bloc.stream.firstWhere((s) => s is ReadingGroupProgressUpdated);
    await sub.cancel();

    expect(outcomes, hasLength(2));
    expect(outcomes.first.attempt, isNot(outcomes.last.attempt));
  });

  test('page recouverte → plus de rafraîchissement ; de retour → relue',
      () async {
    when(() => service.getGroup(7))
        .thenAnswer((_) async => groupWith(mine: 105));
    final bloc = await loaded(pollInterval: const Duration(milliseconds: 20));
    await Future<void>.delayed(const Duration(milliseconds: 70));
    final whileVisible = verify(() => service.getGroup(7)).callCount;
    expect(whileVisible, greaterThan(1), reason: 'la minuterie tourne');

    bloc.add(const GroupDetailVisibilityChanged(false));
    await Future<void>.delayed(const Duration(milliseconds: 100));
    verifyNever(() => service.getGroup(7));

    bloc.add(const GroupDetailVisibilityChanged(true));
    await Future<void>.delayed(const Duration(milliseconds: 5));
    verify(() => service.getGroup(7)).called(greaterThanOrEqualTo(1));
  });
}
