import 'package:flutter/material.dart';
import 'package:mangatracker/core/service_locator/service_locator.dart';
import 'package:mangatracker/core/theme/app_colors.dart';
import 'package:mangatracker/features/manga/dto/manga_quick_view.dto.dart';
import 'package:mangatracker/features/manga/services/recommendation.service.dart';
import 'package:mangatracker/features/manga/widgets/manga_card.dart';
import 'package:mangatracker/features/recommendations/widgets/recommendations_segmented_toggle.dart';
import 'package:mangatracker/l10n/app_localizations.dart';

/// Page « Recommandations par genre ».
///
/// Appelle `/recommendations/by-genre` (via [RecommendationService]) qui
/// renvoie une `Map<String, List<MangaQuickViewDto>>` (top genres de la
/// bibliothèque utilisateur). Chaque genre devient une section avec son
/// carrousel horizontal de [MangaCard].
///
/// Accessible via `context.push('/recommendations/by-genre')` depuis le
/// bouton « Voir plus par genre » sur la home.
class RecommendationsByGenreView extends StatefulWidget {
  const RecommendationsByGenreView({super.key});

  @override
  State<RecommendationsByGenreView> createState() =>
      _RecommendationsByGenreViewState();
}

class _RecommendationsByGenreViewState
    extends State<RecommendationsByGenreView> {
  late Future<Map<String, List<MangaQuickViewDto>>> _byGenreFuture;

  @override
  void initState() {
    super.initState();
    _byGenreFuture = getIt<RecommendationService>()
        .getRecommendationsByGenre(topGenres: 5, perGenre: 10);
  }

  Future<void> _refresh() async {
    setState(() {
      _byGenreFuture = getIt<RecommendationService>()
          .getRecommendationsByGenre(topGenres: 5, perGenre: 10);
    });
    await _byGenreFuture;
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return Scaffold(
      appBar: AppBar(
        title: Text(
          l10n?.recommendationsByGenreTitle ?? 'Recommandations par genre',
        ),
      ),
      body: LayoutBuilder(
        builder: (context, constraints) {
          final isDesktop = constraints.maxWidth >= 1200;
          final isTablet = constraints.maxWidth >= 600;
          // **Fix 2026-05-19** : segmented toggle V1 en tête de page (au lieu
          // d'un IconButton dans l'AppBar) pour switcher entre Tout / Par genre.
          const toggle = RecommendationsSegmentedToggle(
            current: RecommendationsMode.byGenre,
          );
          final inner = FutureBuilder<Map<String, List<MangaQuickViewDto>>>(
            future: _byGenreFuture,
            builder: (context, snapshot) {
              if (snapshot.connectionState != ConnectionState.done) {
                return const Center(child: CircularProgressIndicator());
              }
              final data = snapshot.data ?? const {};
              final entries =
                  data.entries.where((e) => e.value.isNotEmpty).toList();
              if (entries.isEmpty) {
                return RefreshIndicator(
                  onRefresh: _refresh,
                  child: ListView(
                    children: [
                      const SizedBox(height: 80),
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 32),
                        child: Text(
                          l10n?.recommendationsByGenreEmpty ??
                              'Pas encore de recommandations. Ajoutez des mangas à votre bibliothèque pour en obtenir.',
                          textAlign: TextAlign.center,
                          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                                color: Theme.of(context)
                                    .colorScheme
                                    .onSurface
                                    .withValues(alpha: 0.6),
                              ),
                        ),
                      ),
                    ],
                  ),
                );
              }
              return RefreshIndicator(
                onRefresh: _refresh,
                child: ListView.builder(
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  itemCount: entries.length,
                  itemBuilder: (context, index) =>
                      _GenreSection(entry: entries[index]),
                ),
              );
            },
          );
          if (isDesktop) {
            return Center(
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 1100),
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 32),
                  child: Column(
                    children: [toggle, Expanded(child: inner)],
                  ),
                ),
              ),
            );
          }
          if (isTablet) {
            return Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24),
              child: Column(
                children: [toggle, Expanded(child: inner)],
              ),
            );
          }
          return Column(
            children: [toggle, Expanded(child: inner)],
          );
        },
      ),
    );
  }
}

class _GenreSection extends StatelessWidget {
  final MapEntry<String, List<MangaQuickViewDto>> entry;
  const _GenreSection({required this.entry});

  @override
  Widget build(BuildContext context) {
    final brightness = Theme.of(context).brightness;
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 4, 20, 18),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // **Fix 2026-05-19** : label uppercase tracké V1 (au lieu d'un
          // titleMedium nu) pour rester cohérent avec ProfileEditSection +
          // les autres labels de section de l'app.
          Padding(
            padding: const EdgeInsets.only(left: 4, bottom: 10),
            child: Text(
              entry.key.toUpperCase(),
              style: TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w700,
                letterSpacing: 0.88,
                color: AppColors.dsText2(brightness),
              ),
            ),
          ),
          SizedBox(
            height: 220,
            child: ListView.builder(
              scrollDirection: Axis.horizontal,
              itemCount: entry.value.length,
              itemBuilder: (context, index) {
                final manga = entry.value[index];
                return Padding(
                  padding: const EdgeInsets.only(right: 12),
                  child: SizedBox(
                    width: 120,
                    child: MangaCard(
                      muId: manga.muId.toString(),
                      mangaTitle: manga.title,
                      mangaAuthor: manga.year.toString(),
                      mediumImgPath: manga.mediumCoverUrl,
                      rating: manga.rating != 'N/A' && manga.rating.isNotEmpty
                          ? manga.rating
                          : null,
                    ),
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
