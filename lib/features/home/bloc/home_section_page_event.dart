import 'package:equatable/equatable.dart';
import 'package:mangatracker/features/home/dto/home_section.dto.dart';
import 'package:mangatracker/features/home/dto/home_section_kind.dart';
import 'package:mangatracker/features/manga/dto/manga_quick_view.dto.dart';

/// Evenements du [HomeSectionPageBloc] (page « Tout voir » d'une section et
/// carrousel de l'accueil, qui partagent le meme BLoC de pagination).
abstract class HomeSectionPageEvent extends Equatable {
  const HomeSectionPageEvent();

  @override
  List<Object?> get props => [];
}

/// Premiere page.
class LoadSectionPage extends HomeSectionPageEvent {
  const LoadSectionPage();
}

/// Amorce la pagination avec des items **deja connus** (l'apercu de la
/// section renvoye par `GET /mangas/home/sections`), sans requete.
///
/// C'est ce qui permet au carrousel de l'accueil de reutiliser la pagination
/// de la page « Tout voir » : il ne recharge pas ce qu'il affiche deja, il
/// declare sa page 1 puis enchaine sur [LoadMoreSectionPage].
class SeedSectionPage extends HomeSectionPageEvent {
  final HomeSectionKind? kind;
  final HomeSectionParams params;
  final List<MangaQuickViewDto> items;

  /// L'apercu vient du cache faute de reseau : la pagination reste inerte.
  final bool isOffline;

  const SeedSectionPage({
    required this.kind,
    this.params = HomeSectionParams.none,
    required this.items,
    this.isOffline = false,
  });

  @override
  List<Object?> get props => [kind, params, items, isOffline];
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
