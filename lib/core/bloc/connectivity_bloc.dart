import 'dart:async';
import 'package:bloc/bloc.dart';
import 'package:mangatracker/core/service_locator/service_locator.dart';
import 'package:mangatracker/core/services/connectivity_service.dart';
import 'connectivity_event.dart';
import 'connectivity_state.dart';

/// BLoC pour la gestion de la connectivité
class ConnectivityBloc extends Bloc<ConnectivityEvent, ConnectivityState> {
  final ConnectivityService _connectivityService = getIt<ConnectivityService>();
  
  StreamSubscription<bool>? _connectivitySubscription;

  ConnectivityBloc() : super(const ConnectivityInitial()) {
    on<CheckConnectivity>(_onCheckConnectivity);
    on<ConnectivityChanged>(_onConnectivityChanged);
    
    _initializeConnectivityListener();
  }

  @override
  Future<void> close() {
    _connectivitySubscription?.cancel();
    return super.close();
  }

  /// Initialise l'écoute de la connectivité
  void _initializeConnectivityListener() {
    _connectivitySubscription = _connectivityService.connectivityStream.listen(
      (isConnected) {
        add(ConnectivityChanged(isConnected));
      },
    );
  }

  /// Vérifie la connectivité
  Future<void> _onCheckConnectivity(CheckConnectivity event, Emitter<ConnectivityState> emit) async {
    try {
      final isConnected = await _connectivityService.checkConnectivity();
      emit(ConnectivityChecked(
        isConnected: isConnected,
        isOffline: !isConnected,
      ));
    } catch (e) {
      emit(const ConnectivityChecked(
        isConnected: false,
        isOffline: true,
      ));
    }
  }

  /// Gère le changement de connectivité
  void _onConnectivityChanged(ConnectivityChanged event, Emitter<ConnectivityState> emit) {
    emit(ConnectivityChecked(
      isConnected: event.isConnected,
      isOffline: !event.isConnected,
    ));
  }
}
