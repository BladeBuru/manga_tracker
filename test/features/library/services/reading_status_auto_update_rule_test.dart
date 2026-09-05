import 'package:flutter_test/flutter_test.dart';
import 'package:mangatracker/features/library/services/reading_status_auto_update_rule.dart';
import 'package:mangatracker/features/manga/dto/reading_status.enum.dart';

/// Règle produit, pure : « à jour » + nouveau chapitre au-delà du lu → « en
/// cours ». Exemple d'origine : lu jusqu'au 39, le 40 sort.
void main() {
  bool decide({
    required ReadingStatus? status,
    num? read = 39,
    Iterable<int> newChapters = const [40],
  }) =>
      ReadingStatusAutoUpdateRule.shouldFlipToReading(
        status: status,
        readChapters: read,
        newChapters: newChapters,
      );

  group('ReadingStatusAutoUpdateRule.shouldFlipToReading', () {
    test('« à jour » + chapitre 40 détecté au-delà du 39 lu → « en cours »',
        () {
      expect(decide(status: ReadingStatus.caughtUp), isTrue);
    });

    test('« en cours » reste « en cours » (rien à basculer)', () {
      expect(decide(status: ReadingStatus.reading), isFalse);
    });

    test('« à lire plus tard » ne bouge pas', () {
      // L'app ne connaît ni « abandonné » ni « en pause » : readLater et
      // completed sont les deux statuts qui doivent rester intouchés.
      expect(decide(status: ReadingStatus.readLater), isFalse);
    });

    test('« terminé » ne bouge pas', () {
      expect(decide(status: ReadingStatus.completed), isFalse);
    });

    test('« à jour » sans nouveau chapitre ne bouge pas', () {
      expect(
        decide(status: ReadingStatus.caughtUp, newChapters: const []),
        isFalse,
      );
    });

    test('« à jour » avec un chapitre détecté déjà lu (drapeau périmé) ne bouge pas',
        () {
      expect(
        decide(status: ReadingStatus.caughtUp, read: 40, newChapters: const [40]),
        isFalse,
      );
      expect(
        decide(status: ReadingStatus.caughtUp, read: 45, newChapters: const [40, 41]),
        isFalse,
      );
    });

    test('un seul chapitre au-delà du lu suffit, même parmi des périmés', () {
      expect(
        decide(status: ReadingStatus.caughtUp, read: 40, newChapters: const [38, 41]),
        isTrue,
      );
    });

    test('progression inconnue (null) est traitée comme 0', () {
      expect(
        decide(status: ReadingStatus.caughtUp, read: null, newChapters: const [1]),
        isTrue,
      );
    });

    test('statut inconnu (null) ne bouge pas', () {
      expect(decide(status: null), isFalse);
    });
  });
}
