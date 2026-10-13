import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:mangatracker/core/network/failure_classifier.dart';
import 'package:mangatracker/core/service_locator/service_locator.dart';
import 'package:mangatracker/core/services/offline_cache_service.dart';
import 'package:mangatracker/core/services/sync_service.dart';

/// Mise en file d'attente des écritures de la bibliothèque — règle commune à
/// `LibraryService` et `ChapterProgressService` (extraite de
/// `LibraryService` pour ne pas la dupliquer).
///
/// Dépendances résolues **à l'appel** : injectables en test.
class OfflineWriteQueue {
  final OfflineCacheService? _cacheOverride;

  /// Délai avant la relance de la synchronisation après une mise en file.
  final Duration syncDelay;

  OfflineWriteQueue({
    OfflineCacheService? cache,
    this.syncDelay = const Duration(seconds: 30),
  }) : _cacheOverride = cache;

  OfflineCacheService get _cache =>
      _cacheOverride ?? getIt<OfflineCacheService>();

  /// Met [action] en file et programme une synchronisation proche.
  Future<void> enqueue(OfflineAction action) async {
    await _cache.queueOfflineAction(action);
    unawaited(_syncSoon());
  }

  /// Met une mutation en file d'attente hors ligne — **sauf** si le serveur a
  /// explicitement rejeté la session.
  ///
  /// Frontière de sécurité (cf. `failure_classifier.dart`) : la LECTURE est
  /// assouplie, l'ÉCRITURE ne l'est pas. Une mutation tentée avec une session
  /// morte est **refusée** et l'exception remonte au BLoC, qui affichera
  /// l'invitation à se reconnecter. La mettre en file serait un faux succès :
  /// `SyncService` la rejouerait indéfiniment sans jamais pouvoir aboutir.
  ///
  /// Seule une panne de **réseau** (ou une session non vérifiable faute de
  /// réseau) met en file : une autre erreur (bug, réponse illisible) ne
  /// réussirait pas mieux plus tard. Et une mise en file est un succès
  /// différé (`true`) : renvoyer `false` poussait les écrans à réessayer, et
  /// chaque essai ajoutait une copie à la file.
  Future<bool> queueUnlessRejected(OfflineAction action, Object error) async {
    final mode = classifyFailure(error);
    if (requiresReauthPrompt(mode)) throw error;
    if (!isQueueable(mode)) {
      debugPrint('⚠️ OfflineWriteQueue: ${action.type} non appliqué ($error)');
      return false;
    }
    await enqueue(action);
    return true;
  }

  /// Échecs qui justifient une mise en file : réseau absent, ou session non
  /// vérifiable faute de réseau (`sessionExpired` n'arrive plus que hors
  /// ligne — en ligne sans session, c'est un refus).
  static bool isQueueable(FailureMode mode) =>
      mode == FailureMode.network || mode == FailureMode.sessionExpired;

  /// La file sera rejouée par `SyncService` (reconnexion, retour au premier
  /// plan, minuterie) ; ce rappel couvre le cas où le réseau revient vite.
  Future<void> _syncSoon() async {
    if (!getIt.isRegistered<SyncService>()) return;
    try {
      final sync = await getIt.getAsync<SyncService>();
      await Future<void>.delayed(syncDelay);
      await sync.syncNow();
    } catch (_) {}
  }
}

/// Le serveur répond « déjà dans la bibliothèque » à un ajout : 409 (API
/// actuelle) ou, avant elle, 400 « Manga already saved ». C'est l'état voulu,
/// donc un succès — en ligne comme au rejeu de la file.
///
/// Le corps vient du serveur (JSON NestJS), pas d'un `toString()` d'exception
/// minifié par dart2js : la comparaison de texte y est fiable.
bool isAlreadyInLibraryResponse(int statusCode, String body) {
  if (statusCode == 409) return true;
  return statusCode == 400 && body.toLowerCase().contains('already saved');
}
