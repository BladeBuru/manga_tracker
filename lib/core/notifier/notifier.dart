import 'package:flutter/material.dart';
import 'package:mangatracker/main.dart';
import '../theme/app_colors.dart';

enum NotifierType { success, error, warning, info }

class Notifier {
  void show({
    required String message,
    NotifierType type = NotifierType.info,
  }) {
    final context = navigatorKey.currentContext;
    if (context == null) return;

    final color = switch (type) {
      NotifierType.success => AppColors.success,
      NotifierType.error => AppColors.error,
      NotifierType.warning => AppColors.warning,
      NotifierType.info => AppColors.info,
    };


    final snackBar = SnackBar(
      behavior: SnackBarBehavior.floating,
      backgroundColor: Colors.transparent,
      elevation: 0,

      content: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8), // Padding ajusté
        decoration: BoxDecoration(
          color: color,
          borderRadius: BorderRadius.circular(20),
        ),
        child: Row(
          children: [
            // Expanded permet au texte de prendre toute la place disponible
            Expanded(
              child: Text(
                message,
                style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
                maxLines: 3,
                overflow: TextOverflow.ellipsis,
              ),
            ),
            IconButton(
              icon: const Icon(Icons.close, color: Colors.white, size: 20),
              onPressed: () {
                ScaffoldMessenger.of(context).hideCurrentSnackBar();
              },
            ),
          ],
        ),
      ),
    );


    ScaffoldMessenger.of(context).showSnackBar(snackBar);
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