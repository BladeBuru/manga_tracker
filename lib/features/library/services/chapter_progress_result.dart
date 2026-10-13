import 'package:equatable/equatable.dart';
import 'package:mangatracker/features/library/services/chapter_report.service.dart';

/// Issue typée d'un enregistrement de progression (`PUT /library/chapter`).
///
/// Remplace, pour les écrans qui doivent EXPLIQUER un refus, le booléen de
/// `LibraryService.saveChapterProgress` : « false » ne disait jamais pourquoi
/// (total dépassé, limite de requêtes, session, titre absent…), et l'écran se
/// contentait d'un message générique — ou de rien du tout. **Pure** : ni
/// Flutter, ni GetIt, ni réseau (testée seule).
sealed class ChapterProgressResult extends Equatable {
  const ChapterProgressResult();

  /// La progression est enregistrée, ou le sera au retour du réseau.
  bool get isSuccess =>
      isAppliedOnServer || this is ChapterProgressOfflineQueued;

  /// Le serveur porte déjà la nouvelle valeur (les autres membres d'un groupe
  /// la voient dès maintenant).
  bool get isAppliedOnServer =>
      this is ChapterProgressSaved || this is ChapterProgressAboveTotalReported;

  /// Réessayer plus tard a une chance d'aboutir (limite de requêtes, panne
  /// serveur, erreur inattendue). Faux pour un refus définitif.
  bool get isRetryable =>
      this is ChapterProgressThrottled || this is ChapterProgressFailure;

  @override
  List<Object?> get props => const [];

  /// Résultat d'une réponse HTTP du PUT, hors rattrapage du 406 (que seul le
  /// service sait enchaîner : signalement puis nouvel essai).
  static ChapterProgressResult fromStatusCode(int statusCode) {
    if (statusCode >= 200 && statusCode < 300) {
      return const ChapterProgressSaved();
    }
    return switch (statusCode) {
      406 => const ChapterProgressAboveTotalRefused(),
      429 => const ChapterProgressThrottled(),
      401 || 403 => const ChapterProgressSessionRejected(),
      404 => const ChapterProgressNotInLibrary(),
      _ => ChapterProgressFailure(
        statusCode: statusCode,
        message: 'HTTP $statusCode',
      ),
    };
  }

  /// Résultat d'un signalement de chapitres refusé (rattrapage du 406).
  static ChapterProgressResult fromReportFailure(ChapterReportException e) {
    return switch (e.failure) {
      // Bornes du signalement (> total actuel, ≤ officiel + 200) : la valeur
      // reste au-delà de ce que le serveur acceptera.
      ChapterReportFailure.invalidTotal =>
        const ChapterProgressAboveTotalRefused(),
      ChapterReportFailure.notInLibrary => const ChapterProgressNotInLibrary(),
      ChapterReportFailure.throttled => const ChapterProgressThrottled(),
      ChapterReportFailure.unknown =>
        e.statusCode == 401 || e.statusCode == 403
            ? const ChapterProgressSessionRejected()
            : ChapterProgressFailure(
              statusCode: e.statusCode,
              message: 'report-chapters HTTP ${e.statusCode}',
            ),
    };
  }
}

/// Enregistré tel quel (2xx).
final class ChapterProgressSaved extends ChapterProgressResult {
  const ChapterProgressSaved();
}

/// Le chapitre dépassait le total connu : le nouveau total a été signalé à la
/// communauté, puis la progression enregistrée.
final class ChapterProgressAboveTotalReported extends ChapterProgressResult {
  const ChapterProgressAboveTotalReported();
}

/// Le chapitre dépasse le total connu du titre et n'a pas pu être rattrapé
/// (rattrapage non demandé, ou signalement hors bornes).
final class ChapterProgressAboveTotalRefused extends ChapterProgressResult {
  const ChapterProgressAboveTotalRefused();
}

/// Limite de requêtes du serveur (429).
final class ChapterProgressThrottled extends ChapterProgressResult {
  const ChapterProgressThrottled();
}

/// Pas de réseau : la modification est en file d'attente et partira seule.
final class ChapterProgressOfflineQueued extends ChapterProgressResult {
  const ChapterProgressOfflineQueued();
}

/// Session refusée par le serveur (401/403) : rien n'est mis en file, elle ne
/// pourrait jamais se synchroniser (cf. `failure_classifier.dart`).
final class ChapterProgressSessionRejected extends ChapterProgressResult {
  const ChapterProgressSessionRejected();
}

/// Le titre n'est pas dans la bibliothèque de l'utilisateur (404).
final class ChapterProgressNotInLibrary extends ChapterProgressResult {
  const ChapterProgressNotInLibrary();
}

/// Tout autre échec : code HTTP inattendu (5xx…) ou erreur imprévue.
/// [message] sert au journal, pas à l'écran.
final class ChapterProgressFailure extends ChapterProgressResult {
  final int? statusCode;
  final String message;

  const ChapterProgressFailure({this.statusCode, required this.message});

  @override
  List<Object?> get props => [statusCode, message];
}

/// Progression modifiée sur le serveur — diffusée pour que les écrans déjà
/// ouverts (bibliothèque, fiche du manga) se remettent à jour.
class ChapterProgressChange extends Equatable {
  final int muId;
  final int readChapters;

  /// Qui a demandé l'enregistrement : un écran ignore ses propres
  /// modifications (il les a déjà affichées).
  final Object? origin;

  const ChapterProgressChange({
    required this.muId,
    required this.readChapters,
    this.origin,
  });

  @override
  List<Object?> get props => [muId, readChapters, origin];
}
