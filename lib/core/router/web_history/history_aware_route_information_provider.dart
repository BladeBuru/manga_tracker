import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/scheduler.dart';
import 'package:flutter/widgets.dart';
import 'package:go_router/go_router.dart';
import 'package:mangatracker/core/platform/browser_bridge.dart' as browser;
import 'package:mangatracker/core/router/web_history/history_ledger.dart';
import 'package:mangatracker/core/router/web_history/imperative_completers.dart';

/// Accès au navigateur, injectable pour les tests.
class BrowserHistoryBridge {
  const BrowserHistoryBridge();
  int? serialCount() => browser.historySerialCount();
  void go(int delta) => browser.historyGo(delta);
}

/// Fournisseur d'URL du routeur qui garde l'historique du **navigateur**
/// cohérent avec la pile de l'application (web uniquement).
///
/// Délègue tout à `GoRouteInformationProvider`, sauf trois cas :
/// 1. **Retour dans l'app** (flèche de l'AppBar, `context.pop()`) : go_router
///    signalerait l'écran retrouvé comme une NOUVELLE entrée — l'écran quitté
///    restait « en avant », et le bouton retour du navigateur le rouvrait.
///    Si l'entrée précédente du navigateur porte déjà cet état, on fait un
///    vrai `history.go(-n)` à la place.
/// 2. **Restauration redirigée** (retour du navigateur vers une page devenue
///    interdite, déconnexion) : l'entrée est REMPLACÉE, jamais doublée — on
///    ne peut pas se retrouver piégé sur `/login`.
/// 3. **Retour / avance du navigateur** : go_router restaure la pile sans
///    terminer les `await context.push(...)` en cours ; ils sont terminés ou
///    re-branchés (cf. [reconcileImperativeCompleters]).
///
/// Limite : une navigation déclenchée pendant les quelques millisecondes où
/// le navigateur traite le retour est rejouée après lui.
class HistoryAwareRouteInformationProvider extends RouteInformationProvider
    with WidgetsBindingObserver {
  HistoryAwareRouteInformationProvider(
    this._router, {
    bool enabled = kIsWeb,
    BrowserHistoryBridge bridge = const BrowserHistoryBridge(),
  })  : _enabled = enabled,
        _bridge = bridge {
    current = this;
  }

  /// Instance active (une seule application).
  static HistoryAwareRouteInformationProvider? current;

  /// Attend qu'un retour arrière demandé au navigateur soit traité.
  static Future<void> settled() => current?._settled() ?? Future.value();

  final GoRouter _router;
  final bool _enabled;
  final BrowserHistoryBridge _bridge;
  final HistoryLedger _ledger = HistoryLedger();

  GoRouteInformationProvider get _inner => _router.routeInformationProvider;
  GoRouterDelegate get _delegate => _router.routerDelegate;

  int _listenerCount = 0;
  bool _reportedOnce = false;

  /// État porté par l'entrée courante du navigateur.
  Object? _engineState;
  String? _engineFp;

  /// Empreinte de l'état restauré (retour navigateur ou rafraîchissement du
  /// routeur) pas encore signalé ; `null` après un push / go.
  String? _restoredFp;
  RestoreKind? _restoreKind;
  RouteMatchList _lastConfig = RouteMatchList.empty;
  _PendingBack? _pendingBack;

  @override
  RouteInformation get value => _inner.value;

  @override
  void addListener(VoidCallback listener) {
    if (_listenerCount++ == 0) {
      // AVANT le fournisseur go_router : on voit chaque retour du
      // navigateur en premier (il s'enregistre à son premier écouteur).
      WidgetsBinding.instance.addObserver(this);
      _inner.addListener(_onInnerNotified);
      _delegate.addListener(_onDelegateChanged);
      _lastConfig = _delegate.currentConfiguration;
    }
    _inner.addListener(listener);
  }

  @override
  void removeListener(VoidCallback listener) {
    _inner.removeListener(listener);
    if (--_listenerCount == 0) {
      WidgetsBinding.instance.removeObserver(this);
      _inner.removeListener(_onInnerNotified);
      _delegate.removeListener(_onDelegateChanged);
    }
  }

  @override
  void routerReportsNewRouteInformation(
    RouteInformation routeInformation, {
    RouteInformationReportingType type = RouteInformationReportingType.none,
  }) {
    if (!_enabled) {
      _inner.routerReportsNewRouteInformation(routeInformation, type: type);
      return;
    }
    final pending = _pendingBack;
    if (pending != null) {
      pending.deferred = () =>
          routerReportsNewRouteInformation(routeInformation, type: type);
      return;
    }
    final fp = historyFingerprint(routeInformation.state);
    final serial = _bridge.serialCount();
    final restoredFp = _restoredFp;
    _restoredFp = null;
    if (serial != null && _engineFp != null) _ledger.record(serial, _engineFp!);

    var effective = type;
    if (type == RouteInformationReportingType.none &&
        restoredFp != null &&
        restoredFp != fp) {
      effective = RouteInformationReportingType.neglect;
    }
    if (effective == RouteInformationReportingType.none && serial != null) {
      final depth = popDepth(routeInformation.state, _engineState);
      final steps = depth == 0
          ? null
          : _ledger.stepsBackTo(serial, fp, maxSteps: depth);
      if (steps != null) {
        _goBack(steps, routeInformation, fp);
        return;
      }
    }
    _forward(routeInformation, effective, fp, serial);
  }

  void _forward(
    RouteInformation info,
    RouteInformationReportingType type,
    String fp,
    int? serial,
  ) {
    final replaces = type == RouteInformationReportingType.neglect ||
        (type == RouteInformationReportingType.none && !_reportedOnce);
    final unchanged = type == RouteInformationReportingType.none &&
        fp == _engineFp;
    _inner.routerReportsNewRouteInformation(info, type: type);
    _reportedOnce = true;
    if (serial != null && !unchanged) {
      if (!replaces) _ledger.truncateAfter(serial);
      _ledger.record(replaces ? serial : serial + 1, fp);
    }
    _engineState = info.state;
    _engineFp = fp;
  }

  void _goBack(int steps, RouteInformation info, String fp) {
    _pendingBack = _PendingBack(
      info,
      Timer(const Duration(milliseconds: 600), _onBackTimeout),
    );
    _engineState = info.state;
    _engineFp = fp;
    _bridge.go(-steps);
  }

  /// Le navigateur n'a pas signalé le retour : on resynchronise l'URL.
  void _onBackTimeout() {
    final pending = _pendingBack;
    if (pending == null) return;
    _pendingBack = null;
    pending.complete();
    _inner.routerReportsNewRouteInformation(pending.info);
    pending.deferred?.call();
  }

  @override
  Future<bool> didPushRouteInformation(RouteInformation routeInformation) {
    if (!_enabled) return SynchronousFuture<bool>(false);
    final serial = _bridge.serialCount();
    final fp = historyFingerprint(routeInformation.state);
    _engineState = routeInformation.state;
    _engineFp = fp;
    if (routeInformation.state == null) _reportedOnce = false;
    if (serial != null) _ledger.record(serial, fp);
    final pending = _pendingBack;
    _pendingBack = null;
    pending?.complete();
    final deferred = pending?.deferred;
    if (deferred != null) {
      // Une navigation a eu lieu pendant le retour : l'état restauré ne doit
      // pas l'écraser — on avale ce retour et on rejoue son signalement.
      scheduleMicrotask(deferred);
      return SynchronousFuture<bool>(true);
    }
    _markRestore(RestoreKind.browser);
    return SynchronousFuture<bool>(false);
  }

  void _onInnerNotified() {
    final state = _inner.value.state;
    if (state is RouteInformationState) {
      _restoredFp = null;
      return;
    }
    _restoredFp = historyFingerprint(state);
    _markRestore(_restoreKind ?? RestoreKind.refresh);
  }

  void _markRestore(RestoreKind kind) {
    _restoreKind = kind;
    SchedulerBinding.instance.addPostFrameCallback((_) => _restoreKind = null);
  }

  void _onDelegateChanged() {
    final next = _delegate.currentConfiguration;
    final kind = _restoreKind;
    if (_enabled && kind != null) {
      reconcileImperativeCompleters(_lastConfig, next, kind: kind);
    }
    _lastConfig = next;
  }

  Future<void> _settled() => _pendingBack?.done.future ?? Future.value();
}

class _PendingBack {
  _PendingBack(this.info, this.timer);

  final RouteInformation info;
  final Timer timer;
  final Completer<void> done = Completer<void>();
  VoidCallback? deferred;

  void complete() {
    timer.cancel();
    if (!done.isCompleted) done.complete();
  }
}
