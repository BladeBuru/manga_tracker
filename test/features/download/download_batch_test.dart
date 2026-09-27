import 'package:flutter_test/flutter_test.dart';
import 'package:mangatracker/features/download/services/download_batch.dart';

void main() {
  group('DownloadBatch', () {
    test('les chapitres sont traités dans l\'ordre', () {
      expect(DownloadBatch({12, 10, 11}).chapters, [10, 11, 12]);
    });

    test('un échec au milieu n\'arrête pas la série et reste compté', () {
      final batch = DownloadBatch([10, 11, 12]);
      batch.recordSuccess(10);
      batch.recordFailure(11);
      batch.recordSuccess(12);
      expect(batch.done, [10, 12]);
      expect(batch.failed, [11]);
      expect(batch.fraction, 1);
      expect(batch.cancelled, isFalse);
    });

    test('avancement partiel', () {
      final batch = DownloadBatch([1, 2, 3, 4])..recordSuccess(1);
      expect(batch.fraction, 0.25);
    });

    test('annulation', () {
      final batch = DownloadBatch([1, 2])..cancel();
      expect(batch.cancelled, isTrue);
    });
  });

  group('DownloadBatch.outcomeOf', () {
    test('le lecteur se ferme lui-même sur un succès', () {
      expect(DownloadBatch.outcomeOf(popResult: true, reported: true),
          ReaderDownloadOutcome.success);
    });

    test('le lecteur se ferme lui-même sur un échec', () {
      expect(DownloadBatch.outcomeOf(popResult: false, reported: false),
          ReaderDownloadOutcome.failure);
    });

    test('l\'utilisateur quitte le lecteur → annulation (plus d\'attente de '
        '5 minutes ni de chapitre suivant ouvert d\'office)', () {
      expect(DownloadBatch.outcomeOf(popResult: null, reported: null),
          ReaderDownloadOutcome.cancelled);
    });

    test('rappel reçu mais fermeture sans valeur → le rappel fait foi', () {
      expect(DownloadBatch.outcomeOf(popResult: null, reported: true),
          ReaderDownloadOutcome.success);
    });
  });
}
