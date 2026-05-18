import 'package:flutter/material.dart';
import 'package:mangatracker/core/service_locator/service_locator.dart';
import 'package:mangatracker/features/manga/dto/manga_quick_view.dto.dart';
import 'package:mangatracker/features/manga/services/recommendation.service.dart';
import 'package:mangatracker/features/manga/widgets/manga_card.dart';
import 'package:mangatracker/features/recommendations/widgets/recommendations_segmented_toggle.dart';
import 'package:mangatracker/l10n/app_localizations.dart';

/// Page paginée des recommandations personnalisées.
///
/// Appelle `GET /recommendations?limit&offset` au fil du scroll : dès que
/// l'utilisateur approche du bas (< 500 px), la page suivante est chargée.
/// Stop quand l'API renvoie une page incomplète (`length < pageSize`).
///
/// Distincte de [RecommendationsByGenreView] (carrousels segmentés) :
/// ici on présente un flux unique trié par score décroissant. Pour la
/// navigation par genre, action « Par genre » dans l'AppBar.
class PaginatedRecommendationsView extends StatefulWidget {
  const PaginatedRecommendationsView({super.key});

  @override
  State<PaginatedRecommendationsView> createState() =>
      _PaginatedRecommendationsViewState();
}

class _PaginatedRecommendationsViewState
    extends State<PaginatedRecommendationsView> {
  static const int _pageSize = 50;
  static const double _loadThresholdPx = 500.0;

  final List<MangaQuickViewDto> _items = [];
  int _offset = 0;
  bool _loading = false;
  bool _hasMore = true;

  @override
  void initState() {
    super.initState();
    _loadMore();
  }

  Future<void> _loadMore() async {
    if (_loading || !_hasMore) return;
    setState(() => _loading = true);
    final page = await getIt<RecommendationService>()
        .getPersonalizedRecommendations(limit: _pageSize, offset: _offset);
    if (!mounted) return;
    setState(() {
      _items.addAll(page);
      _offset += page.length;
      _hasMore = page.length == _pageSize;
      _loading = false;
    });
  }

  Future<void> _refresh() async {
    setState(() {
      _items.clear();
      _offset = 0;
      _hasMore = true;
    });
    await _loadMore();
  }

  bool _onScrollNotification(ScrollNotification n) {
    if (n.metrics.extentAfter < _loadThresholdPx && !_loading && _hasMore) {
      _loadMore();
    }
    return false;
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return Scaffold(
      appBar: AppBar(
        title: Text(
          l10n?.recommendationsAllTitle ?? 'Toutes les recommandations',
        ),
        // **Fix 2026-05-19** : `IconButton(category_outlined)` retiré.
        // Le toggle "Tout / Par genre" est maintenant un segmented control
        // V1 sous l'AppBar (cf. `_buildBody`).
      ),
      body: LayoutBuilder(
        builder: (context, constraints) {
          final w = constraints.maxWidth;
          // **Fix 2026-05-19** : 3 cols sur mobile (au lieu de 2) → cards
          // plus compactes, alignées sur la grille library V1 et le mockup
          // design source (3 cols repeat).
          final cols = w >= 1200
              ? 6
              : w >= 800
                  ? 5
                  : w >= 600
                      ? 4
                      : 3;
          return Column(
            children: [
              const RecommendationsSegmentedToggle(
                current: RecommendationsMode.all,
              ),
              Expanded(
                child: RefreshIndicator(
                  onRefresh: _refresh,
                  child: NotificationListener<ScrollNotification>(
                    onNotification: _onScrollNotification,
                    child: _buildBody(cols, l10n),
                  ),
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  Widget _buildBody(int cols, AppLocalizations? l10n) {
    if (_items.isEmpty && _loading) {
      return const Center(child: CircularProgressIndicator());
    }
    if (_items.isEmpty) {
      return ListView(
        children: [
          const SizedBox(height: 80),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 32),
            child: Text(
              l10n?.recommendationsAllEmpty ??
                  'Pas encore de recommandations pour vous.',
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
      );
    }
    return GridView.builder(
      padding: const EdgeInsets.all(12),
      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: cols,
        crossAxisSpacing: 10,
        mainAxisSpacing: 14,
        // 3 cols mobile : aspectRatio 0.62 = card équilibrée (cover ~0.7 +
        // titre 2 lignes + meta row). Avant 0.55 sur 2 cols → cards trop
        // hautes / larges au scroll.
        childAspectRatio: 0.62,
      ),
      itemCount: _items.length + (_hasMore ? 1 : 0),
      itemBuilder: (context, index) {
        if (index >= _items.length) {
          return const Padding(
            padding: EdgeInsets.symmetric(vertical: 24),
            child: Center(child: CircularProgressIndicator()),
          );
        }
        final manga = _items[index];
        return MangaCard(
          muId: manga.muId.toString(),
          mangaTitle: manga.title,
          mangaAuthor: manga.year.toString(),
          mediumImgPath: manga.mediumCoverUrl,
          rating: manga.rating != 'N/A' && manga.rating.isNotEmpty
              ? manga.rating
              : null,
        );
      },
    );
  }
}
