import 'package:equatable/equatable.dart';

/// États pour ConnectivityBloc
abstract class ConnectivityState extends Equatable {
  const ConnectivityState();

  @override
  List<Object?> get props => [];
}

/// État initial
class ConnectivityInitial extends ConnectivityState {
  const ConnectivityInitial();
}

/// Connectivité vérifiée
class ConnectivityChecked extends ConnectivityState {
  final bool isConnected;
  final bool isOffline;
  
  const ConnectivityChecked({
    required this.isConnected,
    required this.isOffline,
  });
  
  @override
  List<Object> get props => [isConnected, isOffline];
}
