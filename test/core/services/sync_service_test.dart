import 'package:flutter_test/flutter_test.dart';
import 'package:mangatracker/core/network/network_compat.dart';
import 'package:mangatracker/core/services/connectivity_service.dart';
import 'package:mangatracker/core/services/offline_cache_service.dart';
import 'package:mangatracker/core/services/offline_queue_policy.dart';
import 'package:mangatracker/core/services/sync_service.dart';
import 'package:mangatracker/features/auth/exceptions/invalid_credentials.exception.dart';
import 'package:mangatracker/features/library/services/offline_replay.service.dart';
import 'package:mocktail/mocktail.dart';

class _Connectivity extends Mock implements ConnectivityService {}

class _Replay extends Mock implements OfflineReplayService {}

/// File en mémoire : même contrat que le stockage réel (verrou compris).
class _MemoryCache extends Fake implements OfflineCacheService {
  List<Map<String, dynamic>> queue = [];
  void Function()? duringReplay;

  @override
  Future<List<Map<String, dynamic>>> getOfflineQueue() async =>
      [for (final e in queue) Map<String, dynamic>.of(e)];

  @override
  Future<void> updateOfflineQueue(
    List<Map<String, dynamic>> Function(List<Map<String, dynamic>>) change,
  ) async {
    queue = change(await getOfflineQueue());
  }

  @override
  Future<void> queueOfflineAction(OfflineAction action) =>
      updateOfflineQueue((q) => OfflineQueuePolicy.enqueue(q, action.toJson()));
}

class _FakeAction extends Fake implements OfflineAction {}

void main() {
  late _MemoryCache cache;
  late _Replay replay;
  late SyncService sync;

  setUpAll(() => registerFallbackValue(_FakeAction()));

  setUp(() async {
    cache = _MemoryCache();
    replay = _Replay();
    sync = SyncService(
      connectivity: _Connectivity(),
      cache: cache,
      replay: replay,
      now: () => DateTime.now(),
    );
    await cache.queueOfflineAction(OfflineAction.addManga(1));
    await cache.queueOfflineAction(OfflineAction.saveChapterProgress(2, 10));
    await cache.queueOfflineAction(OfflineAction.updateCustomLink(3, 'https://x'));
  });

  test('appliquées ou refusées pour de bon : retirées de la file', () async {
    when(() => replay.replay(any())).thenAnswer((inv) async {
      final a = inv.positionalArguments.first as OfflineAction;
      return a.muId == 2 ? ReplayDecision.drop : ReplayDecision.done;
    });
    await sync.syncNow();
    expect(cache.queue, isEmpty);
  });

  test('serveur ou réseau indisponible : gardées, une tentative de plus',
      () async {
    when(() => replay.replay(any()))
        .thenThrow(const SocketException('réseau'));
    await sync.syncNow();
    expect(cache.queue, hasLength(3));
    expect(cache.queue.every((e) => e['attempts'] == 1), isTrue);
  });

  test('session refusée : on s\'arrête, rien n\'est perdu ni compté', () async {
    when(() => replay.replay(any()))
        .thenThrow(InvalidCredentialsException('403'));
    await sync.syncNow();
    expect(cache.queue, hasLength(3));
    expect(cache.queue.any((e) => e['attempts'] != null), isFalse);
    verify(() => replay.replay(any())).called(1);
  });

  test('ce qui arrive pendant la synchronisation est conservé', () async {
    when(() => replay.replay(any())).thenAnswer((_) async {
      await cache.queueOfflineAction(OfflineAction.addManga(99));
      return ReplayDecision.done;
    });
    await sync.syncNow();
    expect(cache.queue.map((e) => e['muId']), [99]);
  });

  test('deux demandes simultanées ne rejouent qu\'une fois', () async {
    when(() => replay.replay(any()))
        .thenAnswer((_) async => ReplayDecision.done);
    await Future.wait([sync.syncNow(), sync.syncNow()]);
    verify(() => replay.replay(any())).called(3);
  });
}
