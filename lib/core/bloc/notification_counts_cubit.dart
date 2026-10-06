import 'dart:async';

import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:mangatracker/core/service_locator/service_locator.dart';
import 'package:mangatracker/core/services/notification_counts_service.dart';

/// Pastilles « à traiter » de l'interface : onglet « Mon compte » (total) et
/// lignes du profil (par source). Source unique : [NotificationCountsService].
///
/// Existe dès le premier rendu : le badge de l'onglet n'attend plus qu'un
/// autre geste reconstruise la barre pour apparaître.
class NotificationCountsCubit extends Cubit<NotificationCounts> {
  NotificationCountsService? _service;
  StreamSubscription<NotificationCounts>? _subscription;

  NotificationCountsCubit({NotificationCountsService? service})
    : super(service?.lastCounts ?? NotificationCounts.zero) {
    if (service != null) {
      _attach(service);
    } else {
      unawaited(_attachWhenReady());
    }
  }

  Future<void> _attachWhenReady() async {
    try {
      final service = await getIt.getAsync<NotificationCountsService>();
      if (!isClosed) _attach(service);
    } catch (_) {
      // Service absent (tests, démarrage interrompu) : pastilles à zéro.
    }
  }

  void _attach(NotificationCountsService service) {
    _service = service;
    _subscription = service.countsStream.listen((counts) {
      if (!isClosed) emit(counts);
    });
    if (!isClosed) emit(service.lastCounts);
    unawaited(service.start());
  }

  /// Retour au premier plan, onglet « Mon compte », action sur une demande.
  Future<void> refresh() async => _service?.refresh();

  @override
  Future<void> close() async {
    await _subscription?.cancel();
    _service?.stop();
    return super.close();
  }
}
