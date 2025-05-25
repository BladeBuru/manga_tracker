import 'package:flutter/material.dart';
import '../theme/app_colors.dart';

enum NotifierType { success, error, warning, info }

class Notifier {
  void show({
    required BuildContext context,
    required String message,
    NotifierType type = NotifierType.info,
  }) {
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

  void success(BuildContext context, String message) =>
      show(context: context, message: message, type: NotifierType.success);

  void error(BuildContext context, String message) =>
      show(context: context, message: message, type: NotifierType.error);

  void info(BuildContext context, String message) =>
      show(context: context, message: message, type: NotifierType.info);

  void warning(BuildContext context, String message) =>
      show(context: context, message: message, type: NotifierType.warning);
}
