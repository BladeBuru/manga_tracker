import 'dart:async';

import 'package:flutter_test/flutter_test.dart';
import 'package:mangatracker/features/reader/services/chapter_detection_queue.dart';

/// Traitement factice : chaque détection reste « en cours » jusqu'à ce que le
/// test la libère, pour reproduire les rappels qui arrivent pendant un
/// traitement (dialogue de saut, requêtes réseau…).
class _Recorder {
  final applied = <String>[];
  final _gates = <Completer<void>>[];
  bool hold = false;

  Future<void> apply(ChapterDetection d) async {
    applied.add('$d');
    if (!hold) return;
    final gate = Completer<void>();
    _gates.add(gate);
    await gate.future;
  }

  void releaseAll() {
    while (_gates.isNotEmpty) {
      _gates.removeAt(0).complete();
    }
  }
}

Future<void> _settle() => Future<void>.delayed(Duration.zero);

void main() {
  final u1 = Uri.parse('https://aniverse.fr/read/chainsaw-man/aaaa');
  final u2 = Uri.parse('https://aniverse.fr/read/chainsaw-man/bbbb');
  final u3 = Uri.parse('https://aniverse.fr/read/chainsaw-man/cccc');

  late _Recorder recorder;
  late ChapterDetectionQueue queue;

  setUp(() {
    recorder = _Recorder();
    queue = ChapterDetectionQueue(recorder.apply);
  });

  test('une navigation signalée trois fois : un seul traitement', () async {
    await Future.wait([
      queue.add(ChapterDetection.url(u1)),
      queue.add(ChapterDetection.url(u1)),
      queue.add(ChapterDetection.url(u1)),
    ]);
    expect(recorder.applied, ['url($u1)']);
  });

  test('pendant un traitement : en attente, le plus récent gagne', () async {
    recorder.hold = true;
    unawaited(queue.add(ChapterDetection.url(u1)));
    await _settle();
    unawaited(queue.add(ChapterDetection.url(u2)));
    final last = queue.add(ChapterDetection.url(u3));
    expect(queue.isProcessing, isTrue);
    recorder.hold = false;
    recorder.releaseAll();
    await last;
    expect(recorder.applied, ['url($u1)', 'url($u3)']);
  });

  test('un signal de page n\'évince jamais une URL en attente', () async {
    recorder.hold = true;
    unawaited(queue.add(ChapterDetection.url(u1)));
    await _settle();
    unawaited(queue.add(ChapterDetection.page(u2, 2)));
    final done = queue.add(ChapterDetection.url(u2));
    recorder.hold = false;
    recorder.releaseAll();
    await done;
    expect(recorder.applied,
        ['url($u1)', 'url($u2)', 'page($u2, 2)'],
        reason: "l'URL passe d'abord : elle fait foi si elle a un numéro");
  });

  test('pushState : URL déjà traitée (sans numéro), puis le titre change',
      () async {
    await queue.add(ChapterDetection.url(u2));
    // Relevé trop tôt : la page affiche encore le chapitre 1.
    await queue.add(ChapterDetection.page(u2, 1));
    // Titre à jour (onTitleChanged), puis relectures programmées.
    await queue.add(ChapterDetection.page(u2, 2));
    await queue.add(ChapterDetection.page(u2, 2));
    await queue.add(ChapterDetection.page(u2, 2));
    expect(recorder.applied,
        ['url($u2)', 'page($u2, 1)', 'page($u2, 2)']);
  });

  test('retour sur une page déjà vue : traitée de nouveau', () async {
    await queue.add(ChapterDetection.page(u1, 1));
    await queue.add(ChapterDetection.page(u2, 2));
    await queue.add(ChapterDetection.page(u1, 1));
    expect(recorder.applied, hasLength(3));
  });

  test('add() se termine une fois la détection appliquée', () async {
    recorder.hold = true;
    unawaited(queue.add(ChapterDetection.url(u1)));
    await _settle();
    var done = false;
    unawaited(queue.add(ChapterDetection.page(u1, 1)).then((_) => done = true));
    await _settle();
    expect(done, isFalse, reason: 'encore en attente');
    recorder.hold = false;
    recorder.releaseAll();
    await _settle();
    await _settle();
    expect(done, isTrue);
    expect(recorder.applied.last, 'page($u1, 1)');
  });

  test('un doublon arrivé pendant son propre traitement attend sa fin',
      () async {
    recorder.hold = true;
    unawaited(queue.add(ChapterDetection.page(u1, 1)));
    await _settle();
    var done = false;
    unawaited(queue.add(ChapterDetection.page(u1, 1)).then((_) => done = true));
    await _settle();
    expect(done, isFalse);
    recorder.releaseAll();
    await _settle();
    await _settle();
    expect(done, isTrue);
    expect(recorder.applied, ['page($u1, 1)']);
  });

  test('une détection en échec ne bloque pas les suivantes', () async {
    final errors = <Object>[];
    final failing = ChapterDetectionQueue(
      (d) async {
        if (d.uri == u1) throw StateError('boom');
        recorder.applied.add('$d');
      },
      onError: errors.add,
    );
    await failing.add(ChapterDetection.url(u1));
    await failing.add(ChapterDetection.url(u2));
    expect(errors, hasLength(1));
    expect(recorder.applied, ['url($u2)']);
  });
}
