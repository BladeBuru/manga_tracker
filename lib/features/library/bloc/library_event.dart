import 'dart:async';

import 'package:equatable/equatable.dart';
import 'package:mangatracker/features/manga/dto/reading_status.enum.dart';

/// Événements pour LibraryBloc
abstract class LibraryEvent extends Equatable {
  const LibraryEvent();

  @override
  List<Object?> get props => [];
}

/// Charger la bibliothèque
class LoadLibrary extends LibraryEvent {
  const LoadLibrary();
}

/// Ajouter un manga à la bibliothèque
class AddMangaToLibrary extends LibraryEvent {
  final int muId;
  
  const AddMangaToLibrary(this.muId);
  
  @override
  List<Object> get props => [muId];
}

/// Supprimer un manga de la bibliothèque
class RemoveMangaFromLibrary extends LibraryEvent {
  final int muId;
  
  const RemoveMangaFromLibrary(this.muId);
  
  @override
  List<Object> get props => [muId];
}

/// Mettre à jour le statut de lecture d'un manga
class UpdateMangaStatus extends LibraryEvent {
  final int muId;
  final ReadingStatus status;
  
  const UpdateMangaStatus(this.muId, this.status);
  
  @override
  List<Object> get props => [muId, status];
}

/// Sauvegarder la progression de lecture
class SaveChapterProgress extends LibraryEvent {
  final int muId;
  final int readChapters;
  
  const SaveChapterProgress(this.muId, this.readChapters);
  
  @override
  List<Object> get props => [muId, readChapters];
}

/// Mettre à jour le lien personnalisé
class UpdateCustomLink extends LibraryEvent {
  final int muId;
  final String customLink;
  
  const UpdateCustomLink(this.muId, this.customLink);
  
  @override
  List<Object> get props => [muId, customLink];
}

/// Supprimer le lien personnalisé
class DeleteCustomLink extends LibraryEvent {
  final int muId;
  
  const DeleteCustomLink(this.muId);
  
  @override
  List<Object> get props => [muId];
}

/// Rafraîchir la bibliothèque.
///
/// [completer] (facultatif) est complété quand le rechargement est
/// réellement terminé — succès, repli sur le cache ou erreur — pour que
/// « tirer pour rafraîchir » s'arrête avec les données, hors ligne compris.
class RefreshLibrary extends LibraryEvent {
  final Completer<void>? completer;

  const RefreshLibrary({this.completer});
}
