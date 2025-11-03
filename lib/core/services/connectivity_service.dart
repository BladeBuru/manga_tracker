import 'dart:async';
import 'package:connectivity_plus/connectivity_plus.dart';

/// Service de gestion de la connectivité réseau
/// Permet de détecter l'état de connexion et d'écouter les changements
class ConnectivityService {
  final Connectivity _connectivity = Connectivity();
  final StreamController<bool> _connectivityController = StreamController<bool>.broadcast();
  
  /// Stream des changements de connectivité
  Stream<bool> get connectivityStream => _connectivityController.stream;
  
  /// État actuel de la connectivité
  bool _isConnected = true;
  bool get isConnected => _isConnected;
  
  /// Initialise le service et commence l'écoute
  Future<void> initialize() async {
    try {
      // Vérifier l'état initial
      await _checkConnectivity();
      
      // Écouter les changements de connectivité
      _connectivity.onConnectivityChanged.listen(_onConnectivityChanged);
    } catch (e) {
      print('⚠️ Erreur lors de l\'initialisation du ConnectivityService: $e');
      // En cas d'erreur, supposer que l'appareil est connecté
      _isConnected = true;
      _connectivityController.add(true);
    }
  }
  
  /// Vérifie l'état actuel de la connectivité
  Future<bool> checkConnectivity() async {
    try {
      final result = await _connectivity.checkConnectivity();
      final isConnected = result != ConnectivityResult.none;
      
      if (_isConnected != isConnected) {
        _isConnected = isConnected;
        _connectivityController.add(isConnected);
      }
      
      return isConnected;
    } catch (e) {
      print('⚠️ Erreur lors de la vérification de connectivité: $e');
      // En cas d'erreur, supposer que l'appareil est connecté
      return true;
    }
  }
  
  /// Gère les changements de connectivité
  void _onConnectivityChanged(ConnectivityResult result) {
    final isConnected = result != ConnectivityResult.none;
    
    if (_isConnected != isConnected) {
      _isConnected = isConnected;
      _connectivityController.add(isConnected);
    }
  }
  
  /// Vérifie la connectivité et met à jour l'état
  Future<void> _checkConnectivity() async {
    await checkConnectivity();
  }
  
  /// Libère les ressources
  void dispose() {
    _connectivityController.close();
  }
}
