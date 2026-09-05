import 'package:equatable/equatable.dart';

/// Evenements du [HomeSectionPageBloc] (page « Tout voir » d'une section).
abstract class HomeSectionPageEvent extends Equatable {
  const HomeSectionPageEvent();

  @override
  List<Object?> get props => [];
}

/// Premiere page.
class LoadSectionPage extends HomeSectionPageEvent {
  const LoadSectionPage();
}

/// Page suivante (scroll infini). Ignore s'il n'y a plus rien a charger,
/// si un chargement est deja en cours, ou hors ligne.
class LoadMoreSectionPage extends HomeSectionPageEvent {
  const LoadMoreSectionPage();
}

/// Pull-to-refresh : repart de la premiere page.
class RefreshSectionPage extends HomeSectionPageEvent {
  const RefreshSectionPage();
}
