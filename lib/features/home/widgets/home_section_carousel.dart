import 'package:flutter/material.dart';
import 'package:mangatracker/features/home/helpers/home_layout_metrics.dart';
import 'package:mangatracker/features/home/helpers/home_section_l10n.dart';
import 'package:mangatracker/features/manga/dto/manga_quick_view.dto.dart';
import 'package:mangatracker/features/manga/widgets/manga_card.dart';
import 'package:mangatracker/l10n/app_localizations.dart';

/// Carrousel horizontal de cartes manga d'une section de l'accueil.
///
/// Reutilise [MangaCard] (cover via le proxy `/mangas/:muId/cover`, titre,
/// note, navigation vers `/manga/:muId`) en y ajoutant la pastille de type
/// quand l'item en porte un. Les cartes debutent au meme retrait que
/// l'en-tete et defilent jusqu'au bord de l'ecran (facon catalogue).
class HomeSectionCarousel extends StatelessWidget {
  final List<MangaQuickViewDto> items;
  final HomeLayoutMetrics metrics;

  const HomeSectionCarousel({
    super.key,
    required this.items,
    required this.metrics,
  });

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return SizedBox(
      height: metrics.cardHeight,
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        itemCount: items.length,
        padding: EdgeInsets.symmetric(horizontal: metrics.horizontalPadding),
        itemBuilder: (context, index) {
          final manga = items[index];
          final rating = manga.rating;
          final type = manga.type;
          return Padding(
            padding: EdgeInsets.only(
              right: index == items.length - 1 ? 0 : HomeLayoutMetrics.cardGap,
            ),
            child: SizedBox(
              width: metrics.cardWidth,
              child: MangaCard(
                key: ValueKey('home-card-${manga.muId}'),
                muId: manga.muId.toString(),
                mangaTitle: manga.title,
                mangaAuthor: manga.year,
                mediumImgPath: manga.mediumCoverUrl,
                rating: rating != 'N/A' && rating.isNotEmpty ? rating : null,
                coverHeight: metrics.coverHeight,
                badgeLabel:
                    type == null ? null : HomeSectionL10n.mangaType(l10n, type),
              ),
            ),
          );
        },
      ),
    );
  }
}
