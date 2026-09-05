import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:mangatracker/core/components/app_chip.dart';
import 'package:mangatracker/core/components/app_empty_state.dart';
import 'package:mangatracker/core/components/app_error_state.dart';
import 'package:mangatracker/core/components/offline_banner.dart';
import 'package:mangatracker/core/components/session_rejected_banner.dart';
import 'package:mangatracker/core/router/app_router.dart';
import 'package:mangatracker/core/service_locator/service_locator.dart';
import 'package:mangatracker/core/theme/app_breakpoints.dart';
import 'package:mangatracker/core/theme/app_spacing.dart';
import 'package:mangatracker/features/home/bloc/home_section_page_bloc.dart';
import 'package:mangatracker/features/home/bloc/home_section_page_event.dart';
import 'package:mangatracker/features/home/bloc/home_section_page_state.dart';
import 'package:mangatracker/features/home/dto/home_section.dto.dart';
import 'package:mangatracker/features/home/dto/home_section_kind.dart';
import 'package:mangatracker/features/home/helpers/home_layout_metrics.dart';
import 'package:mangatracker/features/home/helpers/home_section_l10n.dart';
import 'package:mangatracker/features/home/widgets/home_section_grid.dart';
import 'package:mangatracker/features/home/widgets/home_section_header.dart';
import 'package:mangatracker/l10n/app_localizations.dart';

/// Page « Tout voir » d'une section de l'accueil (`/home/section/:id`).
///
/// Grille paginee en scroll infini (`page` / `limit`), meme en-tete que sur
/// l'accueil (icone + titre traduit) avec le total de titres. Le titre est
/// connu immediatement via [extras] quand on vient de l'accueil ; sur un
/// acces direct (F5 web) il est deduit de la reponse de l'API.
class HomeSectionPage extends StatefulWidget {
  final String sectionId;
  final HomeSectionExtras? extras;

  /// Injectable pour les tests ; sinon une instance dediee est creee via
  /// GetIt (factory) et fermee avec la page.
  final HomeSectionPageBloc? bloc;

  const HomeSectionPage({
    super.key,
    required this.sectionId,
    this.extras,
    this.bloc,
  });

  @override
  State<HomeSectionPage> createState() => _HomeSectionPageState();
}

class _HomeSectionPageState extends State<HomeSectionPage> {
  static const double _loadThresholdPx = 600;

  late final HomeSectionPageBloc _bloc = widget.bloc ??
      getIt<HomeSectionPageBloc>(param1: widget.sectionId);

  @override
  void initState() {
    super.initState();
    _bloc.add(const LoadSectionPage());
  }

  @override
  void dispose() {
    if (widget.bloc == null) _bloc.close();
    super.dispose();
  }

  bool _onScroll(ScrollNotification notification) {
    if (notification.metrics.extentAfter < _loadThresholdPx) {
      _bloc.add(const LoadMoreSectionPage());
    }
    return false;
  }

  Future<void> _refresh() async {
    final next = _bloc.stream.first;
    _bloc.add(const RefreshSectionPage());
    await next.timeout(const Duration(seconds: 8), onTimeout: () => _bloc.state);
  }

  /// Titre : etat charge > extras de navigation > identifiant brut.
  String _title(AppLocalizations l10n, HomeSectionPageState state) {
    HomeSectionKind? kind = widget.extras?.kind;
    HomeSectionParams params = widget.extras?.params ?? HomeSectionParams.none;
    if (state is HomeSectionPageLoaded && state.kind != null) {
      kind = state.kind;
      params = state.params;
    }
    return HomeSectionL10n.title(
      l10n,
      kind: kind,
      params: params,
      fallback: widget.sectionId,
    );
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return BlocBuilder<HomeSectionPageBloc, HomeSectionPageState>(
      bloc: _bloc,
      builder: (context, state) {
        final title = _title(l10n, state);
        final kind = state is HomeSectionPageLoaded && state.kind != null
            ? state.kind
            : widget.extras?.kind;
        return Scaffold(
          appBar: AppBar(title: Text(title)),
          body: LayoutBuilder(
            builder: (context, constraints) {
              final metrics = HomeLayoutMetrics.of(constraints.maxWidth);
              return RefreshIndicator(
                onRefresh: _refresh,
                child: NotificationListener<ScrollNotification>(
                  onNotification: _onScroll,
                  child: AppContentWidth(
                    child: CustomScrollView(
                      slivers: [
                        SliverPadding(
                          padding: EdgeInsets.fromLTRB(
                            metrics.horizontalPadding,
                            AppSpacing.m,
                            metrics.horizontalPadding,
                            AppSpacing.s,
                          ),
                          sliver: SliverToBoxAdapter(
                            child: _PageHeader(
                              title: title,
                              kind: kind,
                              state: state,
                            ),
                          ),
                        ),
                        _body(context, l10n, state, metrics, constraints.maxWidth),
                        const SliverPadding(
                          padding: EdgeInsets.only(bottom: AppSpacing.l),
                        ),
                      ],
                    ),
                  ),
                ),
              );
            },
          ),
        );
      },
    );
  }

  Widget _body(
    BuildContext context,
    AppLocalizations l10n,
    HomeSectionPageState state,
    HomeLayoutMetrics metrics,
    double width,
  ) {
    if (state is HomeSectionPageError) {
      return SliverFillRemaining(
        hasScrollBody: false,
        child: state.notFound
            ? AppEmptyState(
                icon: Icons.search_off_outlined,
                title: l10n.homeSectionNotFound,
                actionLabel: l10n.back,
                onAction: () => context.pop(),
              )
            : AppErrorState(
                message: l10n.homeSectionLoadError,
                retryLabel: l10n.retry,
                onRetry: () => _bloc.add(const LoadSectionPage()),
              ),
      );
    }
    if (state is HomeSectionPageLoaded) {
      if (state.items.isEmpty) {
        return SliverFillRemaining(
          hasScrollBody: false,
          child: AppEmptyState(
            icon: Icons.auto_stories_outlined,
            title: l10n.homeSectionEmpty,
          ),
        );
      }
      return HomeSectionGrid(
        state: state,
        metrics: metrics,
        availableWidth: width,
        onRetryLoadMore: () => _bloc.add(const LoadMoreSectionPage()),
      );
    }
    return HomeSectionGridSkeleton(metrics: metrics, availableWidth: width);
  }
}

/// En-tete de page : meme composant que sur l'accueil, avec le total de
/// titres a droite, puis les bandeaux d'etat (hors ligne / session rejetee).
class _PageHeader extends StatelessWidget {
  final String title;
  final HomeSectionKind? kind;
  final HomeSectionPageState state;

  const _PageHeader({
    required this.title,
    required this.kind,
    required this.state,
  });

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final loaded = state is HomeSectionPageLoaded
        ? state as HomeSectionPageLoaded
        : null;
    final total = loaded == null
        ? 0
        : (loaded.total > 0 ? loaded.total : loaded.items.length);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        HomeSectionHeader(
          icon: HomeSectionL10n.icon(kind),
          tileColor: HomeSectionL10n.tileColor(kind),
          title: title,
          trailing: total > 0
              ? AppChip.primary(label: l10n.homeSectionTitlesCount(total))
              : null,
        ),
        if (state.requiresReauth)
          Padding(
            padding: const EdgeInsets.only(top: AppSpacing.s + AppSpacing.xs),
            child: SessionRejectedBanner(
              onReconnect: () => context.push('/login'),
            ),
          )
        else if (state.isOffline)
          const Padding(
            padding: EdgeInsets.only(top: AppSpacing.s + AppSpacing.xs),
            child: OfflineBanner(),
          ),
      ],
    );
  }
}
