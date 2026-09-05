import 'package:mangatracker/features/manga/dto/reading_status.enum.dart';

/// Règle produit, **pure** (aucune I/O, aucun GetIt) :
///
/// > « Si on détecte un nouveau chapitre sur un manga que j'ai marqué
/// > "à jour", c'est qu'on n'est plus à jour : on est "en cours". »
///
/// Exemple : lu jusqu'au 39, statut « à jour » ; le 40 est détecté → « en
/// cours ». Séparée du service pour être testable en isolation.
class ReadingStatusAutoUpdateRule {
  const ReadingStatusAutoUpdateRule._();

  /// Vrai si l'entrée doit passer « en cours ».
  ///
  /// Conditions cumulatives :
  /// - [status] est « à jour » (`caughtUp`) — `reading` reste `reading`,
  ///   `readLater` et `completed` ne bougent jamais ;
  /// - au moins un chapitre de [newChapters] dépasse [readChapters]. Un
  ///   chapitre détecté déjà couvert par la progression (drapeau périmé)
  ///   ne compte pas.
  static bool shouldFlipToReading({
    required ReadingStatus? status,
    required num? readChapters,
    required Iterable<int> newChapters,
  }) {
    if (status != ReadingStatus.caughtUp) return false;
    final read = readChapters ?? 0;
    return newChapters.any((chapter) => chapter > read);
  }
}
