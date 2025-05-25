import 'package:dashbook/dashbook.dart';
import 'package:flutter/material.dart';
import '../../core/notifier/notifier.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_theme.dart';

void addNotifierServiceStory(Dashbook dashbook) {
  dashbook.storiesOf('Core/Notifier').add('All types', (_) {
    return MaterialApp(
      theme: AppTheme.light,
      home: Scaffold(
        appBar: AppBar(title: const Text('Notifier Test')),
        body: Builder(
          builder: (context) => Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                ElevatedButton(
                  onPressed: () => Notifier().success(context, 'Opération réussie !'),
                  style: ElevatedButton.styleFrom(backgroundColor: AppColors.success),
                  child: Text(
                    'Afficher Success',
                    style: TextStyle(color: AppColors.onPrimaryText),
                  ),
                ),
                const SizedBox(height: 16),
                ElevatedButton(
                  onPressed: () => Notifier().error(context, 'Une erreur est survenue'),
                  style: ElevatedButton.styleFrom(backgroundColor: AppColors.error),
                  child: Text(
                    'Afficher Error',
                    style: TextStyle(color: AppColors.onPrimaryText),
                  ),
                ),
                const SizedBox(height: 16),
                ElevatedButton(
                  onPressed: () => Notifier().warning(context, 'Attention requise'),
                  style: ElevatedButton.styleFrom(backgroundColor: AppColors.warning),
                  child: Text(
                    'Afficher Warning',
                    style: TextStyle(color: AppColors.onPrimaryText),
                  ),
                ),
                const SizedBox(height: 16),
                ElevatedButton(
                  onPressed: () => Notifier().info(context, 'Information utile'),
                  style: ElevatedButton.styleFrom(backgroundColor: AppColors.info),
                  child: Text(
                    'Afficher Info',
                    style: TextStyle(color: AppColors.onPrimaryText),
                  ),
                ),

              ],
            ),
          ),
        ),
      ),
    );
  });
}