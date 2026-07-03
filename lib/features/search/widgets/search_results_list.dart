import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:mangatracker/core/components/app_empty_state.dart';
import 'package:mangatracker/core/components/offline_banner.dart';
import 'package:mangatracker/core/theme/app_spacing.dart';
import 'package:mangatracker/features/manga/widgets/manga_row.dart';
import 'package:mangatracker/features/search/bloc/search_bloc.dart';
import 'package:mangatracker/l10n/app_localizations.dart';

/// Liste des résultats de recherche avec scroll infini.
///
/// Déclenche [SearchNextPageRequested] quand l'utilisateur approche du bas
/// de la liste (seuil 400 px). Le footer affiche un spinner pendant le
/// chargement, ou un bouton « Réessayer » si la page suivante a échoué.
class SearchResultsList extends StatefulWidget {
  final SearchLoaded state;

  const SearchResultsList({super.key, required this.state});

  @override
  State<SearchResultsList> createState() => _SearchResultsListState();
}

class _SearchResultsListState extends State<SearchResultsList> {
  final ScrollController _scrollController = ScrollController();

  static const double _loadMoreThreshold = 400;

  @override
  void initState() {
    super.initState();
    _scrollController.addListener(_onScroll);
  }

  @override
  void dispose() {
    _scrollController
      ..removeListener(_onScroll)
      ..dispose();
    super.dispose();
  }

  void _onScroll() {
    if (!_scrollController.hasClients) return;
    final state = widget.state;
    // Évite le spam d'events en approche du bas : le handler du bloc garde
    // aussi, mais des events déjà en file seraient traités après coup.
    if (state.isLoadingMore || !state.hasMore || state.loadMoreFailed) return;
    final position = _scrollController.position;
    if (position.pixels >= position.maxScrollExtent - _loadMoreThreshold) {
      context.read<SearchBloc>().add(const SearchNextPageRequested());
    }
  }

  /// Si la page 1 tient entièrement à l'écran (grand viewport → pas de
  /// scroll possible, maxScrollExtent == 0), le listener ne se déclenchera
  /// jamais : charger la page suivante jusqu'à ce que la liste scrolle.
  void _autoFillViewport() {
    if (!mounted || !_scrollController.hasClients) return;
    final state = widget.state;
    if (state.hasMore &&
        !state.isLoadingMore &&
        !state.loadMoreFailed &&
        _scrollController.position.maxScrollExtent == 0) {
      context.read<SearchBloc>().add(const SearchNextPageRequested());
    }
  }

  @override
  Widget build(BuildContext context) {
    final state = widget.state;
    final l10n = AppLocalizations.of(context);

    if (state.results.isEmpty) {
      return AppEmptyState(
        icon: Icons.search_off,
        title: l10n?.searchNoResults ?? 'Aucun résultat trouvé',
      );
    }

    WidgetsBinding.instance.addPostFrameCallback((_) => _autoFillViewport());

    // Footer visible seulement pendant un vrai chargement (ou après un
    // échec) — un spinner permanent dès que hasMore serait mensonger.
    final showFooter = state.isLoadingMore || state.loadMoreFailed;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (state.isOffline)
          const Padding(
            padding: EdgeInsets.symmetric(horizontal: AppSpacing.m),
            child: OfflineBanner(),
          ),
        Padding(
          padding: const EdgeInsets.fromLTRB(
            AppSpacing.m,
            0,
            AppSpacing.m,
            AppSpacing.s,
          ),
          child: Text(
            l10n?.searchResultsCount(state.totalHits) ??
                '${state.totalHits} résultats',
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: Theme.of(context).colorScheme.onSurfaceVariant,
                ),
          ),
        ),
        Expanded(
          child: ListView.builder(
            controller: _scrollController,
            padding: EdgeInsets.zero,
            itemCount: state.results.length + (showFooter ? 1 : 0),
            itemBuilder: (context, index) {
              if (index >= state.results.length) {
                return _LoadMoreFooter(loadMoreFailed: state.loadMoreFailed);
              }
              final manga = state.results[index];
              return MangaRow(
                mangaName: manga.title,
                muId: manga.muId.toString(),
                mangaAuthor: manga.year,
                mediumImgPath: manga.mediumCoverUrl,
                lastChapter: manga.totalChapters,
                readChapter: manga.readChapters,
                rating: manga.rating,
                searchQuery: state.query,
                associatedTitles: manga.associated,
              );
            },
          ),
        ),
      ],
    );
  }
}

/// Footer de la liste : spinner de chargement, ou message + « Réessayer »
/// si le chargement de la page suivante a échoué.
class _LoadMoreFooter extends StatelessWidget {
  final bool loadMoreFailed;

  const _LoadMoreFooter({required this.loadMoreFailed});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    if (loadMoreFailed) {
      return Padding(
        padding: const EdgeInsets.symmetric(vertical: AppSpacing.m),
        child: Column(
          children: [
            Text(
              l10n?.searchLoadMoreFailed ?? 'Impossible de charger la suite',
              style: Theme.of(context).textTheme.bodySmall,
            ),
            TextButton(
              onPressed: () => context
                  .read<SearchBloc>()
                  .add(const SearchNextPageRequested()),
              child: Text(l10n?.retry ?? 'Réessayer'),
            ),
          ],
        ),
      );
    }
    return const Padding(
      padding: EdgeInsets.symmetric(vertical: AppSpacing.m),
      child: Center(
        child: SizedBox(
          width: 24,
          height: 24,
          child: CircularProgressIndicator(strokeWidth: 2),
        ),
      ),
    );
  }
}
