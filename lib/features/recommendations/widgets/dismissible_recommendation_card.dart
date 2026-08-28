import 'package:flutter/material.dart';
import 'package:mangatracker/features/manga/dto/manga_quick_view.dto.dart';
import 'package:mangatracker/features/manga/widgets/manga_card.dart';
import 'package:mangatracker/features/recommendations/widgets/dismiss_recommendation_flow.dart';
import 'package:mangatracker/l10n/app_localizations.dart';

/// Carte de recommandation avec geste de rejet « pas intéressé / déjà vu ».
///
/// Le geste est un **appui long**, délibérément non intrusif : une croix sur
/// chaque carte encombrerait les trois écrans de recommandations et
/// pousserait au rejet accidentel. L'appui long ne coûte rien visuellement,
/// n'entre pas en conflit avec l'appui simple (ouverture de la fiche) et
/// reste annonçable aux lecteurs d'écran via le hint `Semantics`.
///
/// Ce widget centralise aussi le mapping DTO → [MangaCard], jusque-là
/// dupliqué à l'identique dans les trois écrans (dont la règle « rating
/// N/A → null »).
class DismissibleRecommendationCard extends StatelessWidget {
  final MangaQuickViewDto manga;

  /// Appelé après un rejet confirmé par le serveur — l'écran retire alors
  /// le titre de sa liste.
  final ValueChanged<num> onDismissed;

  /// Appelé si l'utilisateur annule son rejet depuis le SnackBar. L'écran
  /// remet le titre dans sa liste (ou recharge, selon ce qu'il sait faire).
  final ValueChanged<num>? onRestored;

  const DismissibleRecommendationCard({
    super.key,
    required this.manga,
    required this.onDismissed,
    this.onRestored,
  });

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final rating = manga.rating;

    return Semantics(
      hint:
          l10n?.dismissRecommendationAccessibility ??
          'Appui long pour ne plus recommander ce titre',
      child: MangaCard(
        muId: manga.muId.toString(),
        mangaTitle: manga.title,
        mangaAuthor: manga.year.toString(),
        mediumImgPath: manga.mediumCoverUrl,
        rating: rating != 'N/A' && rating.isNotEmpty ? rating : null,
        onLongPress: () => _dismiss(context),
      ),
    );
  }

  Future<void> _dismiss(BuildContext context) async {
    final dismissed = await runDismissRecommendationFlow(
      context,
      muId: manga.muId,
      mangaTitle: manga.title,
      onRestored: () => onRestored?.call(manga.muId),
    );
    if (dismissed) onDismissed(manga.muId);
  }
}
