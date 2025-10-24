import 'package:equatable/equatable.dart';

/// Événements pour ConnectivityBloc
abstract class ConnectivityEvent extends Equatable {
  const ConnectivityEvent();

  @override
  List<Object?> get props => [];
}

/// Vérifier la connectivité
class CheckConnectivity extends ConnectivityEvent {
  const CheckConnectivity();
}

/// Connectivité changée
class ConnectivityChanged extends ConnectivityEvent {
  final bool isConnected;
  
  const ConnectivityChanged(this.isConnected);
  
  @override
  List<Object> get props => [isConnected];
}
