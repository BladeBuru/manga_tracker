import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:mangatracker/core/service_locator/service_locator.dart';
import 'package:mangatracker/core/theme/app_breakpoints.dart';
import 'package:mangatracker/core/theme/app_spacing.dart';
import 'package:mangatracker/features/home/bloc/home_sections_bloc.dart';
import 'package:mangatracker/features/home/bloc/home_sections_event.dart';
import 'package:mangatracker/features/home/bloc/home_sections_state.dart';
import 'package:mangatracker/features/home/bloc/homepage_bloc.dart';
import 'package:mangatracker/features/home/bloc/homepage_event.dart';
import 'package:mangatracker/features/home/bloc/homepage_state.dart';
import 'package:mangatracker/features/home/helpers/home_layout_metrics.dart';
import 'package:mangatracker/features/home/widgets/home_header_block.dart';
import 'package:mangatracker/features/home/widgets/home_recommendations_section.dart';
import 'package:mangatracker/features/home/widgets/home_sections_sliver.dart';

/// Accueil « catalogue » (2026-09-05) : salutation + bandeaux, section
/// « Recommandes pour vous » (`HomePageBloc`), puis les sections editoriales
/// du serveur (`HomeSectionsBloc`) en carrousels, façon catalogue.
///
/// Deux BLoCs, deux responsabilites : l'utilisateur et ses recommandations
/// d'un cote, le catalogue de l'autre. Les deux sont injectables pour les
/// tests, sinon resolus depuis GetIt (lazy singletons partages avec le shell).
class HomePageBlocView extends StatefulWidget {
  final HomePageBloc? homePageBloc;
  final HomeSectionsBloc? sectionsBloc;

  const HomePageBlocView({super.key, this.homePageBloc, this.sectionsBloc});

  @override
  State<HomePageBlocView> createState() => _HomePageBlocViewState();
}

class _HomePageBlocViewState extends State<HomePageBlocView> {
  late final HomePageBloc _homePageBloc =
      widget.homePageBloc ?? getIt<HomePageBloc>();
  late final HomeSectionsBloc _sectionsBloc =
      widget.sectionsBloc ?? getIt<HomeSectionsBloc>();

  @override
  void initState() {
    super.initState();
    _homePageBloc.add(const LoadHomePage());
    _sectionsBloc.add(const LoadHomeSections());
  }

  /// Pull-to-refresh : les deux BLoCs repartent au reseau ; l'indicateur
  /// attend la premiere reponse du catalogue (borne pour ne jamais rester
  /// bloque si le chargement etait deja en vol).
  Future<void> _refresh() async {
    _homePageBloc.add(const RefreshHomePage());
    final next = _sectionsBloc.stream.first;
    _sectionsBloc.add(const RefreshHomeSections());
    await next.timeout(const Duration(seconds: 8), onTimeout: () => _sectionsBloc.state);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: BlocBuilder<HomeSectionsBloc, HomeSectionsState>(
        bloc: _sectionsBloc,
        builder: (context, sectionsState) {
          return BlocBuilder<HomePageBloc, HomePageState>(
            bloc: _homePageBloc,
            builder: (context, homeState) => LayoutBuilder(
              builder: (context, constraints) => _buildBody(
                context,
                metrics: HomeLayoutMetrics.of(constraints.maxWidth),
                sectionsState: sectionsState,
                homeState: homeState,
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildBody(
    BuildContext context, {
    required HomeLayoutMetrics metrics,
    required HomeSectionsState sectionsState,
    required HomePageState homeState,
  }) {
    final user = homeState is HomePageLoaded ? homeState.user : null;
    final homeOffline = switch (homeState) {
      HomePageLoaded(:final isOffline) => isOffline,
      HomePageError(:final isOffline) => isOffline,
      HomePageActionInProgress(:final isOffline) => isOffline,
      _ => false,
    };
    final homeReauth = switch (homeState) {
      HomePageLoaded(:final requiresReauth) => requiresReauth,
      HomePageError(:final requiresReauth) => requiresReauth,
      HomePageActionInProgress(:final requiresReauth) => requiresReauth,
      _ => false,
    };
    final hPad = metrics.horizontalPadding;

    return RefreshIndicator(
      onRefresh: _refresh,
      child: AppContentWidth(
        child: CustomScrollView(
          slivers: [
            SliverPadding(
              padding: EdgeInsets.fromLTRB(hPad, AppSpacing.jumbo - AppSpacing.s,
                  hPad, AppSpacing.l),
              sliver: SliverToBoxAdapter(
                child: HomeHeaderBlock(
                  username: user?.username,
                  emailVerified: user?.emailVerified ?? true,
                  // Le catalogue est la source principale : son verdict prime,
                  // celui des recommandations complete.
                  isOffline: sectionsState.isOffline || homeOffline,
                  requiresReauth: sectionsState.requiresReauth || homeReauth,
                  pendingActions:
                      homeState is HomePageLoaded ? homeState.pendingActions : 0,
                  onReconnect: () => context.push('/login'),
                ),
              ),
            ),
            SliverToBoxAdapter(
              child: HomeRecommendationsSection(
                state: homeState,
                metrics: metrics,
                onDismissed: (muId) =>
                    _homePageBloc.add(DismissRecommendation(muId)),
                // Annulation depuis le SnackBar : le rejet a ete supprime cote
                // serveur ET le cache invalide → on recharge pour que le titre
                // retrouve sa place de score.
                onRestored: (_) => _homePageBloc.add(const LoadHomePage()),
              ),
            ),
            HomeSectionsSliver(
              state: sectionsState,
              metrics: metrics,
              onRetry: () => _sectionsBloc.add(const LoadHomeSections()),
            ),
            const SliverPadding(padding: EdgeInsets.only(bottom: AppSpacing.l)),
          ],
        ),
      ),
    );
  }
}
