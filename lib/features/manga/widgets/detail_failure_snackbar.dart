import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:mangatracker/features/library/widgets/chapter_progress_feedback.dart';
import 'package:mangatracker/features/manga/bloc/detail_bloc.dart';
import 'package:mangatracker/features/manga/bloc/detail_event.dart';
import 'package:mangatracker/features/manga/bloc/detail_state.dart';
import 'package:mangatracker/l10n/app_localizations.dart';

/// Affiche l'échec d'une action de la fiche ([DetailActionFailed]) sans
/// quitter la page : la raison exacte, et « Réessayer » relance l'action
/// (avant : écran d'erreur dont le bouton rechargeait la fiche).
void showDetailFailureSnackBar(
  BuildContext context,
  DetailActionFailed state, {
  required VoidCallback onReconnect,
}) {
  final bloc = context.read<DetailBloc>();
  final muId = state.mangaDetail.muId.toInt();
  final messenger = ScaffoldMessenger.of(context)..hideCurrentSnackBar();
  void retry(DetailEvent event) {
    if (!bloc.isClosed) bloc.add(event);
  }

  switch (state.notice) {
    case ProgressSaveFailed(:final readChapters, :final reason):
      messenger.showSnackBar(
        chapterProgressSnackBar(
          context,
          reason,
          readChapters,
          onRetry: () => retry(SaveChapterProgress(muId, readChapters)),
          onReconnect: onReconnect,
        ),
      );
    case RatingSaveFailed(:final rating, :final offline):
      final l10n = AppLocalizations.of(context)!;
      final scheme = Theme.of(context).colorScheme;
      messenger.showSnackBar(
        SnackBar(
          content: Text(
            offline ? l10n.ratingSaveOffline : l10n.ratingSaveFailed,
            style: TextStyle(color: scheme.onError),
          ),
          backgroundColor: scheme.error,
          action: offline
              ? null
              : SnackBarAction(
                  label: l10n.retry,
                  textColor: scheme.onError,
                  onPressed: () => retry(UpdateUserRating(muId, rating)),
                ),
        ),
      );
  }
}
