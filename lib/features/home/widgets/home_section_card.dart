import 'package:flutter/material.dart';
import 'package:mangatracker/features/home/helpers/home_section_l10n.dart';
import 'package:mangatracker/features/manga/dto/manga_quick_view.dto.dart';
import 'package:mangatracker/features/manga/widgets/manga_card.dart';
import 'package:mangatracker/l10n/app_localizations.dart';

/// Carte d'un titre du catalogue de l'accueil.
///
/// Un seul endroit ou est decide ce qu'une section montre : la pastille de
/// type (haut gauche), l'indicateur « deja dans ma bibliotheque » (haut
/// droit) et le filtrage des notes vides. Le carrousel de l'accueil et la
/// grille « Tout voir » l'utilisent tous les deux, donc ils ne peuvent plus
/// diverger.
class HomeSectionCard extends StatelessWidget {
  final MangaQuickViewDto manga;
  final double coverHeight;

  /// Le titre est deja dans la bibliotheque de l'utilisateur (index local,
  /// zero appel reseau).
  final bool inLibrary;

  const HomeSectionCard({
    super.key,
    required this.manga,
    required this.coverHeight,
    this.inLibrary = false,
  });

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final rating = manga.rating;
    final type = manga.type;
    return MangaCard(
      muId: manga.muId.toString(),
      mangaTitle: manga.title,
      mangaAuthor: manga.year,
      mediumImgPath: manga.mediumCoverUrl,
      rating: rating != 'N/A' && rating.isNotEmpty ? rating : null,
      coverHeight: coverHeight,
      badgeLabel: type == null ? null : HomeSectionL10n.mangaType(l10n, type),
      inLibrary: inLibrary,
    );
  }
}
