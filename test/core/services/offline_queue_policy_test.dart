import 'package:flutter_test/flutter_test.dart';
import 'package:mangatracker/core/services/offline_queue_policy.dart';

Map<String, dynamic> _action(String type, int muId, [Map<String, dynamic>? x]) =>
    {
      'type': type,
      'muId': muId,
      'timestamp': DateTime(2026, 10, 1).toIso8601String(),
      ...?x,
    };

List<String> _types(List<Map<String, dynamic>> q) =>
    [for (final e in q) '${e['type']}:${e['muId']}'];

void main() {
  group('fusion des doublons', () {
    test('une seule progression par titre : la plus récente gagne', () {
      var q = <Map<String, dynamic>>[];
      for (var chapter = 1; chapter <= 50; chapter++) {
        q = OfflineQueuePolicy.enqueue(
          q,
          _action('saveChapterProgress', 7, {'readChapters': chapter}),
        );
      }
      expect(q, hasLength(1));
      expect(q.single['readChapters'], 50);
    });

    test('statut et lien : idem, et l\'action remplacée passe en fin de file',
        () {
      var q = <Map<String, dynamic>>[];
      q = OfflineQueuePolicy.enqueue(q, _action('updateCustomLink', 1, {'customLink': 'a'}));
      q = OfflineQueuePolicy.enqueue(q, _action('updateMangaStatus', 1, {'status': 'reading'}));
      q = OfflineQueuePolicy.enqueue(q, _action('deleteCustomLink', 1));
      q = OfflineQueuePolicy.enqueue(q, _action('updateStatus', 1, {'status': 'completed'}));
      expect(_types(q), ['deleteCustomLink:1', 'updateStatus:1']);
    });

    test('les titres différents ne se mélangent pas', () {
      var q = <Map<String, dynamic>>[];
      q = OfflineQueuePolicy.enqueue(q, _action('saveChapterProgress', 1, {'readChapters': 3}));
      q = OfflineQueuePolicy.enqueue(q, _action('saveChapterProgress', 2, {'readChapters': 4}));
      expect(q, hasLength(2));
    });

    test('ajouter puis retirer un titre jamais envoyé : il n\'y a rien à faire',
        () {
      var q = <Map<String, dynamic>>[];
      q = OfflineQueuePolicy.enqueue(q, _action('addManga', 5));
      q = OfflineQueuePolicy.enqueue(q, _action('saveChapterProgress', 5, {'readChapters': 2}));
      q = OfflineQueuePolicy.enqueue(q, _action('removeManga', 5));
      expect(q, isEmpty);
    });

    test('retirer un titre déjà au serveur efface ses autres modifications',
        () {
      var q = <Map<String, dynamic>>[];
      q = OfflineQueuePolicy.enqueue(q, _action('saveChapterProgress', 5, {'readChapters': 2}));
      q = OfflineQueuePolicy.enqueue(q, _action('updateCustomLink', 5, {'customLink': 'x'}));
      q = OfflineQueuePolicy.enqueue(q, _action('removeManga', 5));
      expect(_types(q), ['removeManga:5']);
    });

    test('une file héritée de 112 actions est remise en ordre', () {
      final legacy = <Map<String, dynamic>>[
        for (var i = 0; i < 56; i++) ...[
          _action('saveChapterProgress', 9, {'readChapters': i}),
          _action('updateCustomLink', 9, {'customLink': 'https://site/ch-$i'}),
        ],
      ];
      final q = OfflineQueuePolicy.normalize(legacy);
      expect(q, hasLength(2));
      expect(q.every((e) => OfflineQueuePolicy.idOf(e) != null), isTrue);
    });
  });

  group('abandon', () {
    final now = DateTime(2026, 10, 6);

    test('trop d\'échecs, trop vieille ou illisible', () {
      expect(
        OfflineQueuePolicy.isExpired(
          {..._action('addManga', 1), 'attempts': OfflineQueuePolicy.maxAttempts},
          now,
        ),
        isTrue,
      );
      expect(
        OfflineQueuePolicy.isExpired(
          {..._action('addManga', 1), 'timestamp': '2026-08-01T00:00:00'},
          now,
        ),
        isTrue,
      );
      expect(OfflineQueuePolicy.isExpired({'type': 'addManga'}, now), isTrue);
      expect(OfflineQueuePolicy.isExpired(_action('addManga', 1), now), isFalse);
    });

    test('chaque échec compte une tentative', () {
      final once = OfflineQueuePolicy.withFailedAttempt(_action('addManga', 1));
      final twice = OfflineQueuePolicy.withFailedAttempt(once);
      expect(twice['attempts'], 2);
    });
  });

  test('réponse du serveur → suite donnée', () {
    expect(OfflineQueuePolicy.decide(200), ReplayDecision.done);
    expect(OfflineQueuePolicy.decide(201), ReplayDecision.done);
    expect(OfflineQueuePolicy.decide(401), ReplayDecision.stopNeedsLogin);
    expect(OfflineQueuePolicy.decide(403), ReplayDecision.stopNeedsLogin);
    expect(OfflineQueuePolicy.decide(429), ReplayDecision.retryLater);
    expect(OfflineQueuePolicy.decide(503), ReplayDecision.retryLater);
    for (final permanent in [400, 404, 406, 409, 422]) {
      expect(OfflineQueuePolicy.decide(permanent), ReplayDecision.drop);
    }
  });
}
