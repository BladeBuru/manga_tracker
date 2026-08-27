import 'package:equatable/equatable.dart';
import 'package:mangatracker/features/library/services/chapter_report.service.dart';
import 'package:mangatracker/features/manga/dto/reading_status.enum.dart';

/// Événements pour DetailBloc
abstract class DetailEvent extends Equatable {
  const DetailEvent();

  @override
  List<Object?> get props => [];
}

/// Charger les détails d'un manga
class LoadMangaDetail extends DetailEvent {
  final int muId;
  
  const LoadMangaDetail(this.muId);
  
  @override
  List<Object> get props => [muId];
}

/// Rafraîchir les détails
class RefreshMangaDetail extends DetailEvent {
  const RefreshMangaDetail();
}

/// Ajouter le manga à la bibliothèque
class AddToLibrary extends DetailEvent {
  final int muId;
  const AddToLibrary(this.muId);

  @override
  List<Object?> get props => [muId];
}

/// Supprimer le manga de la bibliothèque
class RemoveFromLibrary extends DetailEvent {
  final int muId;
  const RemoveFromLibrary(this.muId);

  @override
  List<Object?> get props => [muId];
}

/// Mettre à jour le statut de lecture
class UpdateReadingStatus extends DetailEvent {
  final ReadingStatus status;
  
  const UpdateReadingStatus(this.status);
  
  @override
  List<Object> get props => [status];
}

/// Sauvegarder la progression de lecture
class SaveChapterProgress extends DetailEvent {
  final int muId;
  final int readChapters;
  
  const SaveChapterProgress(this.muId, this.readChapters);
  
  @override
  List<Object> get props => [muId, readChapters];
}

/// Mettre à jour le lien personnalisé
class UpdateCustomLink extends DetailEvent {
  final String customLink;
  
  const UpdateCustomLink(this.customLink);
  
  @override
  List<Object> get props => [customLink];
}

/// Supprimer le lien personnalisé
class DeleteCustomLink extends DetailEvent {
  const DeleteCustomLink();
}

/// Signaler que le manga possède plus de chapitres que le total connu
/// (chantier A). Succès → le BLoC ré-émet l'état avec le total effectif
/// renvoyé par l'API ; échec → état inchangé.
class ReportMoreChapters extends DetailEvent {
  final int muId;
  final int reportedTotal;

  /// Callback UI optionnel — pattern « callbacks » autorisé par les rules BLoC
  /// pour informer le dialog sans navigation dans le BLoC. `null` = succès ;
  /// une [ChapterReportFailure] = échec typé (le dialog mappe vers un message
  /// l10n adapté). Exclu des props (les fonctions ne sont pas comparables par
  /// valeur).
  final void Function(ChapterReportFailure? failure)? onResult;

  const ReportMoreChapters(this.muId, this.reportedTotal, {this.onResult});

  @override
  List<Object?> get props => [muId, reportedTotal];
}

/// Mettre à jour la note personnelle de l'utilisateur (0-10).
/// `rating = 0` supprime la note.
class UpdateUserRating extends DetailEvent {
  final int muId;
  final int rating;

  const UpdateUserRating(this.muId, this.rating);

  @override
  List<Object?> get props => [muId, rating];
}
