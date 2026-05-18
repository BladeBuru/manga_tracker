import 'package:flutter/material.dart';
import 'package:mangatracker/features/library/bloc/library_bloc.dart';
import 'package:mangatracker/features/library/bloc/library_event.dart';
import 'package:mangatracker/features/library/bloc/library_state.dart';
import 'package:mangatracker/l10n/app_localizations.dart';

/// État d'erreur de la bibliothèque (extrait de `library_bloc_view.dart`
/// pour respecter la limite des 400 lignes).
class LibraryErrorState extends StatelessWidget {
  final LibraryError error;
  final LibraryBloc bloc;

  const LibraryErrorState({
    super.key,
    required this.error,
    required this.bloc,
  });

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final scheme = Theme.of(context).colorScheme;
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            error.isOffline ? Icons.cloud_off : Icons.error,
            size: 64,
            color: scheme.error,
          ),
          const SizedBox(height: 16),
          Text(
            error.isOffline
                ? (l10n?.offlineModeNoCache ??
                    'Mode hors ligne - Aucune donnée en cache')
                : '${l10n?.error ?? "Erreur"}: ${error.message}',
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 16),
          ElevatedButton(
            onPressed: () => bloc.add(const LoadLibrary()),
            child: Text(l10n?.retry ?? 'Réessayer'),
          ),
        ],
      ),
    );
  }
}
