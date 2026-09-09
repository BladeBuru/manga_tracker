import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:mangatracker/core/components/library_owned_ids_builder.dart';
import 'package:mangatracker/features/home/bloc/home_section_page_bloc.dart';
import 'package:mangatracker/features/home/bloc/home_section_page_event.dart';
import 'package:mangatracker/features/home/bloc/home_section_page_state.dart';
import 'package:mangatracker/features/home/dto/home_section.dto.dart';
import 'package:mangatracker/features/home/helpers/home_layout_metrics.dart';
import 'package:mangatracker/features/home/services/home_sections.service.dart';
import 'package:mangatracker/features/home/widgets/home_section_carousel_footer.dart';
import 'package:mangatracker/features/home/widgets/home_section_card.dart';
import 'package:mangatracker/features/manga/dto/manga_quick_view.dto.dart';

/// Carrousel horizontal d'une section de l'accueil, **pagine a la volee**.
///
/// L'apercu renvoye par `/mangas/home/sections` sert de page 1 ; en
/// approchant de la fin du defilement, la page suivante est demandee au
/// meme BLoC que la page « Tout voir » ([HomeSectionPageBloc]) — append,
/// deduplication par `muId` et garde hors ligne ne sont ecrits qu'une fois.
/// « Tout voir » reste disponible : le defilement le complete, il ne le
/// remplace pas.
class HomeSectionCarousel extends StatefulWidget {
  final HomeSectionDto section;
  final HomeLayoutMetrics metrics;

  /// L'accueil est servi depuis le cache : aucune requete n'est tentee.
  final bool isOffline;

  /// Injectable pour les tests ; sinon une instance dediee est creee et
  /// fermee avec le carrousel.
  final HomeSectionPageBloc? bloc;

  const HomeSectionCarousel({
    super.key,
    required this.section,
    required this.metrics,
    this.isOffline = false,
    this.bloc,
  });

  @override
  State<HomeSectionCarousel> createState() => _HomeSectionCarouselState();
}

class _HomeSectionCarouselState extends State<HomeSectionCarousel> {
  /// Distance restante (px) sous laquelle la page suivante est demandee.
  static const double _loadThresholdPx = 320;

  /// Le BLoC n'est PAS pris dans GetIt : la factory enregistree la-bas sert
  /// la page « Tout voir » (limite 40). Le carrousel doit paginer a la taille
  /// de l'apercu, et la registration existante n'est pas touchee.
  late final HomeSectionPageBloc _bloc = widget.bloc ??
      HomeSectionPageBloc(
        sectionId: widget.section.id,
        limit: HomeSectionsService.defaultLimit,
      );

  @override
  void initState() {
    super.initState();
    _seed();
  }

  @override
  void didUpdateWidget(covariant HomeSectionCarousel oldWidget) {
    super.didUpdateWidget(oldWidget);
    // Nouvel apercu (cache -> reseau, pull-to-refresh) : on repart de lui.
    // Comparaison par identite de liste : les pages ajoutees localement
    // vivent dans le BLoC, jamais dans `widget.section`, donc elles ne
    // peuvent pas declencher une re-amorce en boucle.
    final changed = !identical(oldWidget.section.items, widget.section.items) ||
        oldWidget.isOffline != widget.isOffline;
    if (changed) _seed();
  }

  void _seed() {
    _bloc.add(SeedSectionPage(
      kind: widget.section.kind,
      params: widget.section.params,
      items: widget.section.items,
      isOffline: widget.isOffline,
    ));
  }

  @override
  void dispose() {
    if (widget.bloc == null) _bloc.close();
    super.dispose();
  }

  bool _onScroll(ScrollNotification notification) {
    if (notification.metrics.axis != Axis.horizontal) return false;
    if (notification.metrics.extentAfter < _loadThresholdPx) {
      _bloc.add(const LoadMoreSectionPage());
    }
    return false;
  }

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<HomeSectionPageBloc, HomeSectionPageState>(
      bloc: _bloc,
      builder: (context, state) {
        final loaded = state is HomeSectionPageLoaded ? state : null;
        // Avant que l'amorce ne soit traitee, on affiche deja l'apercu.
        final items = loaded?.items ?? widget.section.items;
        return SizedBox(
          height: widget.metrics.cardHeight,
          child: NotificationListener<ScrollNotification>(
            onNotification: _onScroll,
            child: LibraryOwnedIdsBuilder(
              builder: (context, ownedMuIds) => _CarouselList(
                items: items,
                metrics: widget.metrics,
                ownedMuIds: ownedMuIds,
                footer: HomeSectionCarouselFooter.of(loaded),
                onRetry: () => _bloc.add(const LoadMoreSectionPage()),
              ),
            ),
          ),
        );
      },
    );
  }
}

/// Rendu pur du carrousel : cartes puis, le cas echeant, la tuile de pied
/// (chargement en cours ou reessai).
class _CarouselList extends StatelessWidget {
  final List<MangaQuickViewDto> items;
  final HomeLayoutMetrics metrics;
  final Set<int> ownedMuIds;
  final CarouselFooterKind? footer;
  final VoidCallback onRetry;

  const _CarouselList({
    required this.items,
    required this.metrics,
    required this.ownedMuIds,
    required this.footer,
    required this.onRetry,
  });

  @override
  Widget build(BuildContext context) {
    final count = items.length + (footer == null ? 0 : 1);
    return ListView.builder(
      scrollDirection: Axis.horizontal,
      itemCount: count,
      padding: EdgeInsets.symmetric(horizontal: metrics.horizontalPadding),
      itemBuilder: (context, index) {
        final isLast = index == count - 1;
        final gap = isLast ? 0.0 : HomeLayoutMetrics.cardGap;
        if (footer != null && index == items.length) {
          return HomeSectionCarouselFooter(
            kind: footer!,
            height: metrics.coverHeight,
            onRetry: onRetry,
          );
        }
        final manga = items[index];
        return Padding(
          padding: EdgeInsets.only(right: gap),
          child: SizedBox(
            width: metrics.cardWidth,
            child: HomeSectionCard(
              key: ValueKey('home-card-${manga.muId}'),
              manga: manga,
              coverHeight: metrics.coverHeight,
              inLibrary: ownedMuIds.contains(manga.muId.toInt()),
            ),
          ),
        );
      },
    );
  }
}
