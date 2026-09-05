import 'package:flutter/material.dart';
import 'package:mangatracker/core/service_locator/service_locator.dart';
import 'package:mangatracker/core/theme/app_breakpoints.dart';
import 'package:mangatracker/core/theme/app_colors.dart';
import 'package:mangatracker/features/manga/dto/manga_quick_view.dto.dart';
import 'package:mangatracker/features/manga/services/recommendation.service.dart';
import 'package:mangatracker/features/recommendations/widgets/dismissible_recommendation_card.dart';
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
  late Future<List<MangaQuickViewDto>> _sleepersFuture;

  /// Titres ecartes pendant cette session d'affichage.
  ///
  /// Les listes viennent de `Future`s immuables passees en `MapEntry` aux
  /// sections : on ne peut pas en retirer un element. On filtre donc au
  /// rendu, ce qui couvre d'un coup les sections par genre ET la section
  /// « Pepites » sans dupliquer la logique.
  ///
  /// Vide a chaque rechargement : le serveur exclut deja les titres ecartes,
  /// le filtre local n'a plus rien a rattraper.
  final Set<num> _dismissedMuIds = <num>{};

  @override
  void initState() {
    super.initState();
    _load();
  }

  void _load() {
    _dismissedMuIds.clear();
    _byGenreFuture = getIt<RecommendationService>()
        .getRecommendationsByGenre(topGenres: 5, perGenre: 10);
    // Pépites : sorties récentes bien notées (Bayésien) mais peu visibles —
    // section « découverte » en tête de l'explorer par genre.
    _sleepersFuture = getIt<RecommendationService>().getSleeperHits();
  }

  Future<void> _refresh() async {
    setState(_load);
    await _byGenreFuture;
  }

  void _onDismissed(num muId) {
    if (!mounted) return;
    setState(() => _dismissedMuIds.add(muId));
  }

  /// Annulation depuis le SnackBar : le titre redevient recommandable, on le
  /// reaffiche a sa place d'origine (la liste chargee n'a pas bouge).
  void _onRestored(num muId) {
    if (!mounted) return;
    setState(() => _dismissedMuIds.remove(muId));
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
      // Responsive (audit 2026-06-12) : breakpoints locaux 1200/600 remplacés
      // par le wrapper unifié AppContentWidth (max 1100) + AppBreakpoints.
      body: LayoutBuilder(
        builder: (context, constraints) {
          final bp = AppBreakpoints.of(constraints.maxWidth);
          final hPad = bp.isWide
              ? 32.0
              : bp.isAtLeastTablet
                  ? 24.0
                  : 0.0;
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
                  // +1 : section « Pépites » en tête (masquée si vide).
                  itemCount: entries.length + 1,
                  itemBuilder: (context, index) {
                    if (index == 0) {
                      return _SleepersSection(
                        future: _sleepersFuture,
                        dismissedMuIds: _dismissedMuIds,
                        onDismissed: _onDismissed,
                        onRestored: _onRestored,
                      );
                    }
                    return _GenreSection(
                      entry: entries[index - 1],
                      dismissedMuIds: _dismissedMuIds,
                      onDismissed: _onDismissed,
                      onRestored: _onRestored,
                    );
                  },
                ),
              );
            },
          );
          return AppContentWidth(
            child: Padding(
              padding: EdgeInsets.symmetric(horizontal: hPad),
              child: Column(
                children: [toggle, Expanded(child: inner)],
              ),
            ),
          );
        },
      ),
    );
  }
}

/// Section « Pépites cachées » (icône diamant) — sleeper hits en tête de
/// l'explorer.
/// Rendue vide (SizedBox.shrink) tant que le fetch n'a pas abouti ou si
/// l'API ne renvoie rien : la page reste utilisable sans cette section.
class _SleepersSection extends StatelessWidget {
  final Future<List<MangaQuickViewDto>> future;
  final Set<num> dismissedMuIds;
  final ValueChanged<num> onDismissed;
  final ValueChanged<num> onRestored;

  const _SleepersSection({
    required this.future,
    required this.dismissedMuIds,
    required this.onDismissed,
    required this.onRestored,
  });

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return FutureBuilder<List<MangaQuickViewDto>>(
      future: future,
      builder: (context, snapshot) {
        final sleepers = snapshot.data ?? const <MangaQuickViewDto>[];
        if (sleepers.isEmpty) return const SizedBox.shrink();
        return _GenreSection(
          entry: MapEntry(
            l10n?.recommendationsSleepersTitle ?? 'Pépites cachées',
            sleepers,
          ),
          icon: Icons.diamond_outlined,
          dismissedMuIds: dismissedMuIds,
          onDismissed: onDismissed,
          onRestored: onRestored,
        );
      },
    );
  }
}

class _GenreSection extends StatelessWidget {
  final MapEntry<String, List<MangaQuickViewDto>> entry;
  final Set<num> dismissedMuIds;
  final ValueChanged<num> onDismissed;
  final ValueChanged<num> onRestored;

  /// Icône affichée devant le titre de section (ex: diamant pour les
  /// « Pépites cachées »). `null` pour les sections par genre classiques.
  final IconData? icon;

  const _GenreSection({
    required this.entry,
    required this.dismissedMuIds,
    required this.onDismissed,
    required this.onRestored,
    this.icon,
  });

  @override
  Widget build(BuildContext context) {
    final brightness = Theme.of(context).brightness;
    // Filtrage au rendu des titres ecartes : la liste source vient d'un
    // Future immuable et ne peut pas etre mutee. Une section qui se vide
    // entierement disparait plutot que d'afficher un genre sans titre.
    final mangas = entry.value
        .where((m) => !dismissedMuIds.contains(m.muId))
        .toList();
    if (mangas.isEmpty) return const SizedBox.shrink();
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
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                if (icon != null) ...[
                  Icon(
                    icon,
                    size: 14,
                    color: AppColors.dsText2(brightness),
                  ),
                  const SizedBox(width: 6),
                ],
                Text(
                  entry.key.toUpperCase(),
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
                    letterSpacing: 0.88,
                    color: AppColors.dsText2(brightness),
                  ),
                ),
              ],
            ),
          ),
          SizedBox(
            height: 220,
            child: ListView.builder(
              scrollDirection: Axis.horizontal,
              itemCount: mangas.length,
              itemBuilder: (context, index) {
                final manga = mangas[index];
                return Padding(
                  padding: const EdgeInsets.only(right: 12),
                  child: SizedBox(
                    width: 120,
                    child: DismissibleRecommendationCard(
                      manga: manga,
                      onDismissed: onDismissed,
                      onRestored: onRestored,
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
