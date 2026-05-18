import 'package:flutter/material.dart';
import 'package:mangatracker/core/theme/app_colors.dart';
import 'package:mangatracker/core/theme/app_spacing.dart';
import 'package:mangatracker/features/manga/dto/manga_recommendation_view.dto.dart';
import 'package:mangatracker/features/manga/widgets/manga_card.dart';
import 'package:mangatracker/l10n/app_localizations.dart';

// ╔═══════════════════════════════════════════════════════════════════════╗
// ║  V1 « Refined Classic » — Section "Mangas similaires" (recos).        ║
// ║  Label uppercase tracké 11px, liste horizontale de MangaCard,         ║
// ║  gap 12, padding 16. Pas de bordures rouges agressives.               ║
// ╚═══════════════════════════════════════════════════════════════════════╝

/// Section "Mangas similaires" affichée inline dans la fiche détail.
///
/// - Si [isLoading] est `true` → squelette horizontal (3 cards grises).
/// - Si [recommendations] est `null` ou vide → empty state minimaliste.
/// - Sinon → ListView horizontale de [MangaCard].
class DetailRecommendationsSection extends StatelessWidget {
  final List<MangaRecommendationView>? recommendations;
  final bool isLoading;

  const DetailRecommendationsSection({
    super.key,
    required this.recommendations,
    this.isLoading = false,
  });

  @override
  Widget build(BuildContext context) {
    final brightness = Theme.of(context).brightness;
    final l10n = AppLocalizations.of(context)!;

    final hasItems = !isLoading &&
        recommendations != null &&
        recommendations!.isNotEmpty;
    final isEmpty = !isLoading &&
        (recommendations == null || recommendations!.isEmpty);

    return Padding(
      padding: const EdgeInsets.fromLTRB(
        AppSpacing.m,
        AppSpacing.s,
        AppSpacing.m,
        AppSpacing.m,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.only(left: 4, bottom: 10),
            child: Text(
              l10n.recommendedMangas.toUpperCase(),
              style: TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w600,
                letterSpacing: 0.88,
                color: AppColors.dsText2(brightness),
              ),
            ),
          ),
          if (isLoading)
            const _RecommendationsSkeleton()
          else if (isEmpty)
            _EmptyState(message: l10n.noRecommendationsAvailable)
          else if (hasItems)
            SizedBox(
              height: 220,
              child: ListView.separated(
                scrollDirection: Axis.horizontal,
                itemCount: recommendations!.length,
                separatorBuilder: (_, __) => const SizedBox(width: 12),
                itemBuilder: (context, index) {
                  final manga = recommendations![index];
                  return SizedBox(
                    width: 120,
                    child: MangaCard(
                      muId: manga.muId.toString(),
                      mangaTitle: manga.title,
                      mangaAuthor: manga.year,
                      mediumImgPath: manga.mediumCoverUrl,
                      rating: manga.rating,
                    ),
                  );
                },
              ),
            ),
        ],
      ),
    );
  }
}

class _EmptyState extends StatelessWidget {
  final String message;
  const _EmptyState({required this.message});

  @override
  Widget build(BuildContext context) {
    final brightness = Theme.of(context).brightness;
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(
        horizontal: 16,
        vertical: 18,
      ),
      decoration: BoxDecoration(
        color: brightness == Brightness.dark
            ? AppColors.dsSurfaceDark
            : Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: AppColors.dsHairline(brightness),
          width: 1,
        ),
      ),
      child: Text(
        message,
        textAlign: TextAlign.center,
        style: TextStyle(
          fontSize: 13,
          color: AppColors.dsText2(brightness),
        ),
      ),
    );
  }
}

class _RecommendationsSkeleton extends StatelessWidget {
  const _RecommendationsSkeleton();

  @override
  Widget build(BuildContext context) {
    final brightness = Theme.of(context).brightness;
    return SizedBox(
      height: 220,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        itemCount: 4,
        separatorBuilder: (_, __) => const SizedBox(width: 12),
        itemBuilder: (_, __) {
          return Container(
            width: 120,
            decoration: BoxDecoration(
              color: AppColors.dsBgInset(brightness),
              borderRadius: BorderRadius.circular(12),
            ),
          );
        },
      ),
    );
  }
}
