import 'package:flutter/material.dart';
// MODIFICATION 1 : Importer votre fichier main.dart pour accéder à la clé globale
import 'package:mangatracker/main.dart'; // Assurez-vous que le chemin d'import est correct
import '../theme/app_colors.dart';

enum NotifierType { success, error, warning, info }

class Notifier {
  // La méthode principale 'show' n'a plus besoin de 'BuildContext' en paramètre.
  // Elle va le chercher elle-même via la clé globale.
  void show({
    required String message,
    NotifierType type = NotifierType.info,
  }) {
    // MODIFICATION 2 : Obtenir le contexte actuel et valide depuis la GlobalKey.
    // C'est le cœur de la solution.
    final context = navigatorKey.currentContext;

    // Si le contexte n'existe pas (l'application n'est pas visible), on ne fait rien.
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
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: color,
          borderRadius: BorderRadius.circular(20),
        ),
        child: Text(
          message,
          style: const TextStyle(color: Colors.white),
          maxLines: 3,
          overflow: TextOverflow.ellipsis,
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