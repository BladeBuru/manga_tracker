import 'package:flutter/material.dart';
import 'package:mangatracker/features/library/services/chapter_progress_result.dart';
import 'package:mangatracker/l10n/app_localizations.dart';

/// Message à afficher pour l'issue d'un enregistrement de progression
/// (lecture partagée, fiche du manga). Une raison par issue : avant, tout
/// refus devenait « Erreur lors de la sauvegarde de la progression » — ou
/// rien du tout.
String chapterProgressMessage(
  AppLocalizations l10n,
  ChapterProgressResult result,
  int readChapters,
) {
  return switch (result) {
    ChapterProgressSaved() => l10n.chapterProgressSavedAt(readChapters),
    ChapterProgressAboveTotalReported() =>
      l10n.chapterProgressSavedReported(readChapters),
    ChapterProgressAboveTotalRefused() =>
      l10n.chapterProgressAboveTotal(readChapters),
    ChapterProgressThrottled() => l10n.chapterProgressThrottled,
    ChapterProgressOfflineQueued() => l10n.chapterProgressQueued(readChapters),
    ChapterProgressSessionRejected() => l10n.chapterProgressSessionRejected,
    ChapterProgressNotInLibrary() => l10n.chapterProgressNotInLibrary,
    ChapterProgressFailure(statusCode: final int code) =>
      l10n.chapterProgressFailedCode(code),
    ChapterProgressFailure() => l10n.chapterProgressFailed,
  };
}

/// Bandeau du bas pour [result]. Les échecs sont sur fond d'erreur ;
/// [onRetry] (« Réessayer ») n'est proposé que si un nouvel essai a une
/// chance d'aboutir, [onReconnect] (« Se reconnecter ») sur une session
/// refusée.
SnackBar chapterProgressSnackBar(
  BuildContext context,
  ChapterProgressResult result,
  int readChapters, {
  VoidCallback? onRetry,
  VoidCallback? onReconnect,
}) {
  final l10n = AppLocalizations.of(context)!;
  final scheme = Theme.of(context).colorScheme;
  final failed = !result.isSuccess;
  SnackBarAction? action;
  if (failed && result.isRetryable && onRetry != null) {
    action = SnackBarAction(
      label: l10n.retry,
      textColor: scheme.onError,
      onPressed: onRetry,
    );
  } else if (result is ChapterProgressSessionRejected && onReconnect != null) {
    action = SnackBarAction(
      label: l10n.sessionRejectedAction,
      textColor: scheme.onError,
      onPressed: onReconnect,
    );
  }
  return SnackBar(
    content: Text(
      chapterProgressMessage(l10n, result, readChapters),
      style: failed ? TextStyle(color: scheme.onError) : null,
    ),
    backgroundColor: failed ? scheme.error : null,
    duration: Duration(seconds: failed ? 6 : 3),
    action: action,
  );
}
