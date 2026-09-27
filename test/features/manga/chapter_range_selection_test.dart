import 'package:flutter_test/flutter_test.dart';
import 'package:mangatracker/features/manga/utils/chapter_range_selection.dart';

void main() {
  group('range', () {
    test('de 125 à 145 inclus', () {
      final r = ChapterRangeSelection.range(125, 145);
      expect(r.length, 21);
      expect(r.first, 125);
      expect(r.last, 145);
    });

    test('dans les deux sens', () {
      expect(ChapterRangeSelection.range(12, 10), {10, 11, 12});
    });

    test('sans les chapitres déjà téléchargés', () {
      expect(ChapterRangeSelection.range(1, 5, excluded: {2, 4}), {1, 3, 5});
    });
  });

  group('pendingInterval (bouton « intervalle »)', () {
    test('125 puis 145 cochés → proposer 125 → 145', () {
      expect(
        ChapterRangeSelection.pendingInterval(
          anchors: [125, 145],
          selected: {125, 145},
        ),
        (from: 125, to: 145),
      );
    });

    test('intervalle déjà complet → pas de bouton', () {
      expect(
        ChapterRangeSelection.pendingInterval(
          anchors: [10, 12],
          selected: {10, 11, 12},
        ),
        isNull,
      );
    });

    test('trous uniquement faits de chapitres déjà téléchargés → pas de bouton',
        () {
      expect(
        ChapterRangeSelection.pendingInterval(
          anchors: [10, 12],
          selected: {10, 12},
          excluded: {11},
        ),
        isNull,
      );
    });

    test('un seul chapitre coché, ou ancre décochée depuis → pas de bouton', () {
      expect(
        ChapterRangeSelection.pendingInterval(anchors: [7], selected: {7}),
        isNull,
      );
      expect(
        ChapterRangeSelection.pendingInterval(
            anchors: [7, 20], selected: {20}),
        isNull,
      );
    });
  });

  test('pushAnchor garde les deux derniers, sans doublon', () {
    var anchors = <int>[];
    anchors = ChapterRangeSelection.pushAnchor(anchors, 5);
    anchors = ChapterRangeSelection.pushAnchor(anchors, 9);
    anchors = ChapterRangeSelection.pushAnchor(anchors, 12);
    expect(anchors, [9, 12]);
    expect(ChapterRangeSelection.pushAnchor(anchors, 9), [12, 9]);
  });

  test('chapterAt : ligne sous le doigt, bornée à la liste', () {
    int at(double dy, double offset) => ChapterRangeSelection.chapterAt(
        dy: dy, scrollOffset: offset, itemExtent: 56, itemCount: 200);
    expect(at(10, 0), 1);
    expect(at(60, 0), 2);
    expect(at(10, 56 * 124), 125);
    expect(at(-30, 0), 1);
    expect(at(10, 56 * 500), 200);
  });

  test('firstUnread : ouvre sur le premier chapitre non lu', () {
    expect(ChapterRangeSelection.firstUnread(readChapters: 200, total: 400), 201);
    expect(ChapterRangeSelection.firstUnread(readChapters: null, total: 50), 1);
    expect(ChapterRangeSelection.firstUnread(readChapters: 50, total: 50), 50);
  });
}
