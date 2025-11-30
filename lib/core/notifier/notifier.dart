import 'package:flutter/material.dart';
import 'package:mangatracker/main.dart';
import '../theme/app_colors.dart';
import '../theme/app_radius.dart';
import 'dart:async';

enum NotifierType { success, error, warning, info }

class Notifier {
  // Cache pour grouper les notifications similaires
  final Map<String, _NotificationGroup> _notificationGroups = {};
  Timer? _groupTimer;
  
  void show({
    required String message,
    NotifierType type = NotifierType.info,
  }) {
    final context = navigatorKey.currentContext;
    if (context == null) return;

    // Créer une clé unique pour cette notification (type + message)
    final key = '${type.name}_$message';
    
    // Si une notification similaire existe déjà, incrémenter le compteur
    if (_notificationGroups.containsKey(key)) {
      final group = _notificationGroups[key]!;
      group.count++;
      group.lastUpdate = DateTime.now();
      
      // Mettre à jour le message avec le compteur
      _updateNotification(context, key, group, type);
      
      // Réinitialiser le timer
      _groupTimer?.cancel();
      _groupTimer = Timer(const Duration(seconds: 2), () {
        _notificationGroups.remove(key);
      });
      
      return;
    }
    
    // Créer un nouveau groupe
    final group = _NotificationGroup(
      message: message,
      count: 1,
      type: type,
      lastUpdate: DateTime.now(),
    );
    _notificationGroups[key] = group;
    
    // Afficher la notification
    _displayNotification(context, key, group, type);
    
    // Programmer la suppression du groupe après 2 secondes
    _groupTimer?.cancel();
    _groupTimer = Timer(const Duration(seconds: 2), () {
      _notificationGroups.remove(key);
    });
  }
  
  void _displayNotification(BuildContext context, String key, _NotificationGroup group, NotifierType type) {
    final color = switch (type) {
      NotifierType.success => AppColors.success,
      NotifierType.error => AppColors.error,
      NotifierType.warning => AppColors.warning,
      NotifierType.info => AppColors.info,
    };
    
    final displayMessage = group.count > 1
        ? '${group.message} (${group.count}x)'
        : group.message;

    final snackBar = SnackBar(
      behavior: SnackBarBehavior.floating,
      backgroundColor: Colors.transparent,
      elevation: 0,
      duration: const Duration(seconds: 2),
      content: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        decoration: BoxDecoration(
          color: color,
          borderRadius: AppRadius.circularJumbo,
        ),
        child: Row(
          children: [
            Expanded(
              child: Text(
                displayMessage,
                style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
                maxLines: 3,
                overflow: TextOverflow.ellipsis,
              ),
            ),
            IconButton(
              icon: const Icon(Icons.close, color: Colors.white, size: 20),
              onPressed: () {
                ScaffoldMessenger.of(context).hideCurrentSnackBar();
                _notificationGroups.remove(key);
              },
            ),
          ],
        ),
      ),
    );

    ScaffoldMessenger.of(context).showSnackBar(snackBar);
  }
  
  void _updateNotification(BuildContext context, String key, _NotificationGroup group, NotifierType type) {
    // Masquer la notification actuelle et en afficher une nouvelle avec le compteur mis à jour
    ScaffoldMessenger.of(context).hideCurrentSnackBar();
    
    // Attendre un peu avant d'afficher la nouvelle notification
    Future.delayed(const Duration(milliseconds: 100), () {
      if (_notificationGroups.containsKey(key)) {
        _displayNotification(context, key, group, type);
      }
    });
  }

  void success(String message) =>
      show(message: message, type: NotifierType.success);

  void error(String message) =>
      show(message: message, type: NotifierType.error);

  void info(String message) =>
      show(message: message, type: NotifierType.info);

  void warning(String message) =>
      show(message: message, type: NotifierType.warning);
}

/// Classe pour grouper les notifications similaires
class _NotificationGroup {
  final String message;
  int count;
  final NotifierType type;
  DateTime lastUpdate;

  _NotificationGroup({
    required this.message,
    required this.count,
    required this.type,
    required this.lastUpdate,
  });
}