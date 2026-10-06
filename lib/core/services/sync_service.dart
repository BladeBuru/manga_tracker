import 'dart:async';

import 'package:flutter/widgets.dart';
import 'package:mangatracker/core/network/failure_classifier.dart';
import 'package:mangatracker/core/service_locator/service_locator.dart';
import 'package:mangatracker/core/services/offline_queue_policy.dart';
import 'package:mangatracker/features/library/services/offline_replay.service.dart';
import 'connectivity_service.dart';
import 'offline_cache_service.dart';

/// Envoie au serveur les modifications faites hors ligne.
///
/// Avant, la file n'était rejouée que sur un passage « pas de réseau →
/// réseau » : une file née d'un serveur injoignable alors que le téléphone
/// restait connecté n'était **jamais** rejouée, et grossissait (112 actions
/// observées). Elle est désormais rejouée :
/// - au démarrage, au retour au premier plan, à la reconnexion ;
/// - toutes les [_retryInterval] tant qu'il reste quelque chose ;
/// - à la demande ([syncNow], bouton « Synchroniser »).
///
/// Chaque action est rejouée telle quelle ([OfflineReplayService]) : retirée
/// si appliquée ou refusée pour de bon, gardée (tentative +1) si le serveur
/// ou le réseau manque, et tout s'arrête si la session est refusée.
class SyncService {
  static const Duration _retryInterval = Duration(minutes: 2);
  static const Duration _actionTimeout = Duration(seconds: 20);
  static const Duration _startupDelay = Duration(seconds: 8);

  final ConnectivityService? _connectivityOverride;
  final OfflineCacheService? _cacheOverride;
  final OfflineReplayService _replay;
  final DateTime Function() _now;

  SyncService({
    ConnectivityService? connectivity,
    OfflineCacheService? cache,
    OfflineReplayService? replay,
    DateTime Function()? now,
  }) : _connectivityOverride = connectivity,
       _cacheOverride = cache,
       _replay = replay ?? OfflineReplayService(),
       _now = now ?? DateTime.now;

  late final ConnectivityService _connectivityService =
      _connectivityOverride ?? getIt<ConnectivityService>();
  late final OfflineCacheService _cacheService =
      _cacheOverride ?? getIt<OfflineCacheService>();

  StreamSubscription<bool>? _connectivitySubscription;
  AppLifecycleListener? _lifecycle;
  Timer? _retryTimer;
  Future<void>? _running;

  final StreamController<void> _synced = StreamController<void>.broadcast();

  /// Émis quand une synchronisation a modifié la file : les écrans
  /// rechargent leurs données et leur compteur « en attente ».
  Stream<void> get synced => _synced.stream;

  Future<void> initialize() async {
    // Files accumulées par les versions précédentes : doublons fusionnés.
    await _cacheService.updateOfflineQueue(OfflineQueuePolicy.normalize);

    _connectivitySubscription = _connectivityService.connectivityStream.listen(
      (isConnected) {
        if (isConnected) unawaited(syncNow());
      },
    );
    _lifecycle = AppLifecycleListener(onResume: () => unawaited(syncNow()));
    // Laisse le démarrage (rafraîchissement de session) se faire d'abord.
    _retryTimer = Timer(_startupDelay, () => unawaited(syncNow()));
  }

  /// Rejoue la file maintenant. Un seul passage à la fois : un appel pendant
  /// un passage en cours attend sa fin.
  Future<void> syncNow() => _running ??= _run().whenComplete(() {
    _running = null;
  });

  /// Conservé pour compatibilité : même effet que [syncNow].
  Future<void> forceSync() => syncNow();

  Future<void> _run() async {
    _retryTimer?.cancel();
    final queue = await _cacheService.getOfflineQueue();
    if (queue.isEmpty) return;
    debugPrint('🔄 Synchronisation de ${queue.length} action(s) en attente…');

    final removed = <String>{};
    final failed = <String, Map<String, dynamic>>{};
    for (final entry in queue) {
      final id = OfflineQueuePolicy.idOf(entry);
      if (id == null) continue;
      if (OfflineQueuePolicy.isExpired(entry, _now())) {
        removed.add(id);
        continue;
      }
      final decision = await _replayOne(entry);
      switch (decision) {
        case ReplayDecision.done:
        case ReplayDecision.drop:
          removed.add(id);
        case ReplayDecision.retryLater:
          failed[id] = OfflineQueuePolicy.withFailedAttempt(entry);
        case ReplayDecision.stopNeedsLogin:
          // Inutile d'insister : tout attend la reconnexion.
          break;
      }
      if (decision == ReplayDecision.stopNeedsLogin) break;
    }

    // Retrait par identifiant : ce qui a été ajouté pendant le passage est
    // conservé (avant, la file entière était réécrite et le perdait).
    await _cacheService.updateOfflineQueue(
      (current) => [
        for (final entry in current)
          if (!removed.contains(OfflineQueuePolicy.idOf(entry)))
            failed[OfflineQueuePolicy.idOf(entry)] ?? entry,
      ],
    );
    if (removed.isNotEmpty || failed.isNotEmpty) _synced.add(null);

    final remaining = await _cacheService.getOfflineQueue();
    if (remaining.isNotEmpty) {
      _retryTimer = Timer(_retryInterval, () => unawaited(syncNow()));
    }
  }

  Future<ReplayDecision> _replayOne(Map<String, dynamic> entry) async {
    final OfflineAction action;
    try {
      action = OfflineAction.fromJson(entry);
    } catch (_) {
      return ReplayDecision.drop;
    }
    try {
      return await _replay.replay(action).timeout(_actionTimeout);
    } catch (e) {
      final mode = classifyFailure(e);
      if (requiresReauthPrompt(mode)) return ReplayDecision.stopNeedsLogin;
      return ReplayDecision.retryLater;
    }
  }

  Future<bool> hasPendingActions() async =>
      (await _cacheService.getOfflineQueue()).isNotEmpty;

  Future<int> getPendingActionsCount() async =>
      (await _cacheService.getOfflineQueue()).length;

  Future<List<OfflineAction>> getPendingActions() async {
    final queue = await _cacheService.getOfflineQueue();
    return [
      for (final entry in queue)
        if (_tryParse(entry) case final action?) action,
    ];
  }

  static OfflineAction? _tryParse(Map<String, dynamic> entry) {
    try {
      return OfflineAction.fromJson(entry);
    } catch (_) {
      return null;
    }
  }

  void dispose() {
    _connectivitySubscription?.cancel();
    _lifecycle?.dispose();
    _retryTimer?.cancel();
    _synced.close();
  }
}
