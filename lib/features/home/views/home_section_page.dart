import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
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
import 'package:mangatracker/features/home/widgets/home_section_page_body.dart';
import 'package:mangatracker/features/home/widgets/home_section_page_header.dart';
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

  /// Pull-to-refresh borne : l'indicateur ne reste jamais bloque.
  Future<void> _refresh() async {
    final next = _bloc.stream.first;
    _bloc.add(const RefreshSectionPage());
    await next.timeout(const Duration(seconds: 8), onTimeout: () => _bloc.state);
  }

  /// Nature de la section : etat charge > extras de navigation > inconnue.
  HomeSectionKind? _kind(HomeSectionPageState state) =>
      state is HomeSectionPageLoaded && state.kind != null
          ? state.kind
          : widget.extras?.kind;

  String _title(AppLocalizations l10n, HomeSectionPageState state) {
    final params = state is HomeSectionPageLoaded && state.kind != null
        ? state.params
        : widget.extras?.params ?? HomeSectionParams.none;
    return HomeSectionL10n.title(
      l10n,
      kind: _kind(state),
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
        return Scaffold(
          appBar: AppBar(title: Text(title)),
          body: LayoutBuilder(
            builder: (context, constraints) {
              final metrics = HomeLayoutMetrics.of(constraints.maxWidth);
              final hPad = metrics.horizontalPadding;
              return RefreshIndicator(
                onRefresh: _refresh,
                child: NotificationListener<ScrollNotification>(
                  onNotification: _onScroll,
                  child: AppContentWidth(
                    child: CustomScrollView(
                      slivers: [
                        SliverPadding(
                          padding: EdgeInsets.fromLTRB(
                              hPad, AppSpacing.m, hPad, AppSpacing.s),
                          sliver: SliverToBoxAdapter(
                            child: HomeSectionPageHeader(
                              title: title,
                              kind: _kind(state),
                              state: state,
                            ),
                          ),
                        ),
                        HomeSectionPageBody(
                          state: state,
                          metrics: metrics,
                          availableWidth: constraints.maxWidth,
                          onRetry: () => _bloc.add(const LoadSectionPage()),
                          onRetryLoadMore: () =>
                              _bloc.add(const LoadMoreSectionPage()),
                          onBack: () => context.pop(),
                        ),
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
}
