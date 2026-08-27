import 'dart:math' as math;

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:mangatracker/core/components/offline_banner.dart';
import 'package:mangatracker/core/service_locator/service_locator.dart';
import 'package:mangatracker/features/home/bloc/homepage_bloc.dart';
import 'package:mangatracker/features/home/bloc/homepage_event.dart';
import 'package:mangatracker/features/home/bloc/homepage_state.dart';
import 'package:mangatracker/features/manga/dto/manga_quick_view.dto.dart';
import 'package:mangatracker/features/manga/widgets/manga_card.dart';
import 'package:mangatracker/features/manga/widgets/manga_row.dart';
import '../../../core/components/filter_button.dart';
import '../../../core/components/verify_email_banner.dart';
import '../../../core/components/welcome_header.dart';
import 'package:mangatracker/l10n/app_localizations.dart';
import 'package:mangatracker/core/theme/app_radius.dart';

/// Vue réactive de la page d'accueil utilisant BLoC.
class HomePageBlocView extends StatefulWidget {
  const HomePageBlocView({super.key});

  @override
  State<HomePageBlocView> createState() => _HomePageBlocViewState();
}

class _HomePageBlocViewState extends State<HomePageBlocView> {
  final HomePageBloc _homePageBloc = getIt<HomePageBloc>();
  int indexButtonBar = 0;

  @override
  void initState() {
    super.initState();
    debugPrint('🏠 HomePageBlocView initialisée');
    _homePageBloc.add(const LoadHomePage());
  }

  void _redirectToLoginPage() {
    context.push('/login');
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: BlocConsumer<HomePageBloc, HomePageState>(
        bloc: _homePageBloc,
        listener: (context, state) {
          if (state is HomePageError) {
            if (state.message.contains('InvalidCredentials') ||
                state.message.contains('Expired session')) {
              _redirectToLoginPage();
            }
          }
        },
        builder: (context, state) {
          return LayoutBuilder(
            builder: (context, constraints) {
              final outerHorizontalPadding = constraints.maxWidth >= 1200
                  ? math.max(0.0, (constraints.maxWidth - 1100) / 2)
                  : 0.0;
              final innerHorizontalPadding = constraints.maxWidth >= 1200
                  ? 32.0
                  : (constraints.maxWidth >= 600 ? 25.0 : 25.0);
              return RefreshIndicator(
                onRefresh: () async {
                  _homePageBloc.add(const RefreshHomePage());
                  await Future.delayed(const Duration(milliseconds: 500));
                },
                child: Padding(
                  padding: EdgeInsets.symmetric(horizontal: outerHorizontalPadding),
                  child: CustomScrollView(
                    slivers: [
                      SliverPadding(
                        padding: EdgeInsets.fromLTRB(
                          innerHorizontalPadding,
                          40,
                          innerHorizontalPadding,
                          0,
                        ),
                        sliver: SliverList(
                          delegate: SliverChildListDelegate([
                            _buildWelcomeHeader(state),
                            _buildOfflineIndicator(state),

                            // Banner "Vérifiez votre email" — visible uniquement
                            // quand l'utilisateur est connecté et que l'email
                            // n'a pas encore été cliqué via le magic link.
                            VerifyEmailBanner(
                              visible: state is HomePageLoaded &&
                                  state.user != null &&
                                  !state.user!.emailVerified,
                            ),

                            const SizedBox(height: 20),

                            // ── Recommandés pour vous (carrousel compact 5 max) ──
                            _buildRecommendationsSection(state),

                            const SizedBox(height: 24),

                            // ── Filtres + liste paginée ──
                            _buildFilterButtons(),
                            const SizedBox(height: 16),
                          ]),
                        ),
                      ),

                      SliverPadding(
                        padding: EdgeInsets.symmetric(
                          horizontal: innerHorizontalPadding,
                        ),
                        sliver: _buildFilteredMangaSliver(state),
                      ),

                      const SliverPadding(padding: EdgeInsets.only(bottom: 24)),
                    ],
                  ),
                ),
              );
            },
          );
        },
      ),
    );
  }

  // ─── Header ──────────────────────────────────────────────────────────────

  Widget _buildWelcomeHeader(HomePageState state) {
    String? displayUsername;
    if (state is HomePageLoaded) displayUsername = state.user?.username;
    return WelcomeHeader(username: displayUsername);
  }

  // ─── Offline banner ───────────────────────────────────────────────────────

  Widget _buildOfflineIndicator(HomePageState state) {
    final isOffline = (state is HomePageLoaded && state.isOffline) ||
        (state is HomePageError && state.isOffline);
    if (!isOffline) return const SizedBox.shrink();
    final pendingActions = state is HomePageLoaded ? state.pendingActions : 0;
    // Refactor 2026-05-18 : utilise OfflineBanner du design system.
    return Padding(
      padding: const EdgeInsets.only(top: 12, bottom: 4),
      child: OfflineBanner(pendingActions: pendingActions),
    );
  }

  // ─── Section Recommandé pour toi ─────────────────────────────────────────

  /// Carrousel court (5 mangas max) avec bouton « Voir plus par genre » qui
  /// navigue vers la page dédiée `/recommendations/by-genre`.
  Widget _buildRecommendationsSection(HomePageState state) {
    final l10n = AppLocalizations.of(context);
    final title = l10n?.recommendedForYouHome ?? 'Recommandés pour vous';

    if (state is HomePageLoading) {
      return _buildHorizontalSection(
        title: title,
        child: _buildSkeletonRow(),
      );
    }

    if (state is! HomePageLoaded) return const SizedBox.shrink();

    final recs = state.recommendations.take(10).toList();
    final isOffline = state.isOffline;

    if (recs.isEmpty) {
      // Si offline + pas de recos en cache → on cache la section pour ne pas
      // afficher un message décourageant alors que le réseau est en cause.
      if (isOffline) return const SizedBox.shrink();
      return _buildHorizontalSection(
        title: title,
        child: SizedBox(
          height: 160,
          child: Center(
            child: Text(
              l10n?.recommendedForYouEmpty ??
                  'Ajoutez des mangas à votre bibliothèque\npour obtenir des recommandations personnalisées.',
              textAlign: TextAlign.center,
              style: Theme.of(context)
                  .textTheme
                  .bodySmall
                  ?.copyWith(color: Colors.grey),
            ),
          ),
        ),
      );
    }

    return _buildHorizontalSection(
      title: title,
      trailing: TextButton.icon(
        onPressed: () => context.push('/recommendations'),
        icon: const Icon(Icons.arrow_forward, size: 18),
        label: Text(l10n?.seeAllRecommendations ?? 'Tout voir'),
      ),
      child: SizedBox(
        height: 220,
        child: ListView.builder(
          scrollDirection: Axis.horizontal,
          itemCount: recs.length,
          padding: const EdgeInsets.symmetric(horizontal: 4),
          itemBuilder: (context, index) {
            final manga = recs[index];
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
    );
  }

  Widget _buildHorizontalSection({
    required String title,
    Widget? trailing,
    required Widget child,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Expanded(
              child: Text(
                title,
                style: Theme.of(context).textTheme.titleSmall,
              ),
            ),
            if (trailing != null) trailing,
          ],
        ),
        const SizedBox(height: 12),
        child,
      ],
    );
  }

  Widget _buildSkeletonRow() {
    return SizedBox(
      height: 220,
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        itemCount: 5,
        padding: const EdgeInsets.symmetric(horizontal: 4),
        itemBuilder: (_, __) => Padding(
          padding: const EdgeInsets.only(right: 12),
          child: Container(
            width: 120,
            decoration: BoxDecoration(
              color: Colors.grey.shade300,
              borderRadius: AppRadius.circularMd,
            ),
          ),
        ),
      ),
    );
  }

  // ─── Filtres ─────────────────────────────────────────────────────────────

  Widget _buildFilterButtons() {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Builder(
        builder: (context) {
          final l10n = AppLocalizations.of(context);
          return Row(
            children: [
              FilterButton(
                label: l10n?.trending ?? 'Tendances',
                selected: indexButtonBar == 0,
                onPressed: () => setState(() => indexButtonBar = 0),
              ),
              const SizedBox(width: 10),
              FilterButton(
                label: l10n?.popular ?? 'Populaires',
                selected: indexButtonBar == 1,
                onPressed: () => setState(() => indexButtonBar = 1),
              ),
              const SizedBox(width: 10),
              FilterButton(
                label: l10n?.newReleases ?? 'Nouveautés',
                selected: indexButtonBar == 2,
                onPressed: () => setState(() => indexButtonBar = 2),
              ),
            ],
          );
        },
      ),
    );
  }

  // ─── Liste filtrée (Sliver) ───────────────────────────────────────────────

  Widget _buildFilteredMangaSliver(HomePageState state) {
    final l10n = AppLocalizations.of(context);

    if (state is HomePageLoading) {
      return const SliverFillRemaining(
        child: Center(child: CircularProgressIndicator()),
      );
    }

    if (state is HomePageError) {
      return SliverFillRemaining(
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                l10n?.errorWithMessage(state.message) ??
                    'Erreur : ${state.message}',
              ),
              const SizedBox(height: 16),
              ElevatedButton(
                onPressed: () => _homePageBloc.add(const LoadHomePage()),
                child: Text(l10n?.retry ?? 'Réessayer'),
              ),
            ],
          ),
        ),
      );
    }

    if (state is HomePageLoaded) {
      final List<MangaQuickViewDto> mangaList;
      switch (indexButtonBar) {
        case 1:
          mangaList = state.popularMangas;
        case 2:
          mangaList = state.newMangas;
        default:
          mangaList = state.trendingMangas;
      }

      if (mangaList.isEmpty) {
        return SliverFillRemaining(
          child: Center(
            child: Text(l10n?.noData ?? 'Aucune donnée disponible'),
          ),
        );
      }

      return SliverList(
        delegate: SliverChildBuilderDelegate(
          (context, index) {
            final manga = mangaList[index];
            return MangaRow(
              mangaName: manga.title,
              muId: manga.muId.toString(),
              mangaAuthor: manga.year,
              mediumImgPath: manga.mediumCoverUrl,
              lastChapter: manga.totalChapters,
              readChapter: manga.readChapters,
              rating: manga.rating,
            );
          },
          childCount: mangaList.length,
        ),
      );
    }

    return SliverFillRemaining(
      child: Center(
        child: Text(l10n?.noData ?? 'Aucune donnée disponible'),
      ),
    );
  }
}
