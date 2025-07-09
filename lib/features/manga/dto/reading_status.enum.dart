// Dans votre fichier d'enum

import 'package:flutter/material.dart';
// On importe vos couleurs pour pouvoir les utiliser
import 'package:mangatracker/core/theme/app_colors.dart';

enum ReadingStatus {
  reading,
  readLater,
  caughtUp,
  completed,
}

extension ReadingStatusExtension on ReadingStatus {
  String get value => toString().split('.').last;

  String get label {
    switch (this) {
      case ReadingStatus.reading:
        return 'En cours';
      case ReadingStatus.readLater:
        return 'À lire plus tard';
      case ReadingStatus.caughtUp:
        return 'À jour';
      case ReadingStatus.completed:
        return 'Terminé';
    }
  }

  /// Retourne la couleur sémantique associée au statut
  Color get color {
    switch (this) {
      case ReadingStatus.reading:
        return AppColors.success; // Vert
      case ReadingStatus.readLater:
        return AppColors.info; // Bleu
      case ReadingStatus.caughtUp:
        return AppColors.accent; // Orange/Ambre
      case ReadingStatus.completed:
        return const Color(0xFF673AB7); // Un violet pour "complété"
    }
  }

  /// Retourne l'icône associée au statut
  IconData get icon {
    switch (this) {
      case ReadingStatus.reading:
        return Icons.play_arrow_rounded;
      case ReadingStatus.readLater:
        return Icons.bookmark_rounded;
      case ReadingStatus.caughtUp:
        return Icons.task_alt_rounded;
      case ReadingStatus.completed:
        return Icons.check_circle_rounded;
    }
  }

  /// Crée une enum à partir du texte reçu de l'API
  static ReadingStatus? fromValue(String? value) {
    if (value == null) return null;
    try {
      return ReadingStatus.values.firstWhere((e) => e.value == value);
    } catch (e) {
      return null;
    }
  }
}