/// Stub web pour `ChapterCheckBackgroundService`.
///
/// Pas de background tasks possibles côté navigateur (Web Workers ≠ task
/// scheduler persistant). Les méthodes sont des no-ops — elles loggent
/// et retournent silencieusement.
library;

import 'package:flutter/foundation.dart';

class ChapterCheckBackgroundService {
  Future<void> initialize() async {
    debugPrint('ℹ️ ChapterCheckBackgroundService: no-op sur web');
  }

  Future<void> startPeriodicCheck({int intervalHours = 6}) async {
    // No-op sur web
  }

  Future<void> cancelPeriodicCheck() async {
    // No-op sur web
  }

  Future<void> checkAllMangas() async {
    // No-op sur web
  }
}
