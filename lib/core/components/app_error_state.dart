import 'package:flutter/material.dart';

/// État d'erreur générique du design system avec bouton Retry.
///
/// Utilise `colorScheme.error` pour l'icône, bouton tonal pour le retry
/// (less aggressive que filled). À utiliser pour TOUS les états d'erreur
/// (BLoC Error, fetch failure, etc.).
class AppErrorState extends StatelessWidget {
  final String message;
  final String? retryLabel;
  final VoidCallback? onRetry;

  const AppErrorState({
    super.key,
    required this.message,
    this.retryLabel,
    this.onRetry,
  });

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.error_outline, size: 48, color: scheme.error),
            const SizedBox(height: 12),
            Text(
              message,
              textAlign: TextAlign.center,
              style: textTheme.bodyMedium?.copyWith(color: scheme.onSurface),
            ),
            if (onRetry != null) ...[
              const SizedBox(height: 16),
              // Override `tonal` default (secondaryContainer = orange) →
              // primaryContainer (rouge tonal cohérent).
              FilledButton.tonal(
                onPressed: onRetry,
                style: FilledButton.styleFrom(
                  backgroundColor: scheme.primaryContainer,
                  foregroundColor: scheme.onPrimaryContainer,
                ),
                child: Text(retryLabel ?? 'Réessayer'),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
