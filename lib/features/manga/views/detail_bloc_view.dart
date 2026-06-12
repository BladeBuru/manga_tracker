import 'package:auto_size_text/auto_size_text.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:html/parser.dart';
import 'package:mangatracker/core/components/refreshable_manga_image.dart';
import 'package:mangatracker/core/router/app_router.dart';
import 'package:mangatracker/core/service_locator/service_locator.dart';
import 'package:mangatracker/features/manga/bloc/detail_bloc.dart';
import 'package:mangatracker/features/manga/bloc/detail_event.dart';
import 'package:mangatracker/features/manga/bloc/detail_state.dart';
import 'package:mangatracker/features/manga/dto/reading_status.enum.dart';
import 'package:mangatracker/features/manga/helpers/chapters.helper.dart';
import 'package:mangatracker/features/manga/views/late_detail.view.dart';
import 'package:mangatracker/features/manga/services/manga.service.dart';
import 'package:mangatracker/core/notifier/notifier.dart';
import 'package:mangatracker/core/theme/app_breakpoints.dart';
import 'package:mangatracker/core/theme/app_colors.dart';
import 'package:mangatracker/core/theme/app_radius.dart';
import 'package:mangatracker/core/theme/app_spacing.dart';
import '../../reader/utils/chapter_link_resolver.dart';
import '../dto/manga_recommendation_view.dto.dart';
import 'package:mangatracker/features/manga/widgets/detail_genre_chips.dart';
import 'package:mangatracker/features/manga/widgets/detail_rating_section.dart';
import 'package:mangatracker/features/manga/widgets/detail_read_online_button.dart';
import 'package:mangatracker/features/manga/widgets/detail_recommendations_section.dart';
// `DetailStatusSelector` et `DetailStatusButton` ne sont plus utilisés —
// le statut est désormais une icône dans l'action bar (`_StatusIconButton`).
// `DetailAddToLibraryButton` est encore utilisé (CTA "Ajouter à la
// bibliothèque" pleine largeur quand le manga n'est pas encore ajouté).
import 'package:mangatracker/features/manga/widgets/detail_status_selector.dart'
    show DetailAddToLibraryButton;
import 'package:mangatracker/l10n/app_localizations.dart';
import '../services/custom_selectors.service.dart';
import 'chapter_download_dialog.dart';
import 'package:mangatracker/features/download/services/download_manager_service.dart';
import 'package:mangatracker/features/sharing/widgets/share_manga_sheet.dart';
import 'package:mangatracker/features/sharing/widgets/create_reading_group_sheet.dart';

/// Vue réactive des détails de manga utilisant BLoC - Design original conservé
class DetailBlocView extends StatefulWidget {
  final int muId;
  final String? mangaTitle;
  final String? coverPath;
  
  const DetailBlocView({
    super.key,
    required this.muId,
    this.mangaTitle,
    this.coverPath,
  });

  @override
  State<DetailBlocView> createState() => _DetailBlocViewState();
}

class _DetailBlocViewState extends State<DetailBlocView> {
  // Plus besoin de _detailBloc car on utilise BlocProvider maintenant
  final MangaService _mangaService = getIt<MangaService>();
  final Notifier _notifier = getIt<Notifier>();

  void _redirectToLoginPage() {
    context.push('/login');
  }

  void _refreshLibraryState(BuildContext context) {
    context.read<DetailBloc>().add(const RefreshMangaDetail());
  }

  @override
  Widget build(BuildContext context) {
    // Créer une instance unique de DetailBloc pour cette page
    return BlocProvider(
      create: (context) {
        final bloc = DetailBloc();
        debugPrint('📖 DetailBlocView initialisée pour manga ${widget.muId} - Utilisation du BLoC !');
        // Charger les détails immédiatement après création
        bloc.add(LoadMangaDetail(widget.muId));
        return bloc;
      },
      child: _DetailBlocViewContent(
        muId: widget.muId,
        mangaTitle: widget.mangaTitle,
        coverPath: widget.coverPath,
        mangaService: _mangaService,
        notifier: _notifier,
        onRefreshLibraryState: _refreshLibraryState,
        onRedirectToLogin: _redirectToLoginPage,
      ),
    );
  }
}

/// Widget séparé pour accéder au contexte BlocProvider
class _DetailBlocViewContent extends StatefulWidget {
  final int muId;
  final String? mangaTitle;
  final String? coverPath;
  final MangaService mangaService;
  final Notifier notifier;
  final void Function(BuildContext) onRefreshLibraryState;
  final VoidCallback onRedirectToLogin;
  
  const _DetailBlocViewContent({
    required this.muId,
    this.mangaTitle,
    this.coverPath,
    required this.mangaService,
    required this.notifier,
    required this.onRefreshLibraryState,
    required this.onRedirectToLogin,
  });

  @override
  State<_DetailBlocViewContent> createState() => _DetailBlocViewContentState();
}

class _DetailBlocViewContentState extends State<_DetailBlocViewContent> {
  List<MangaRecommendationView>? _mangaRecommendationsCache;
  String? customLink;
  int lastReadChapters = -1;

  @override
  Widget build(BuildContext context) {
    final brightness = Theme.of(context).brightness;
    return Scaffold(
      // **Fix 2026-05-19** : bg `dsBg` (peachy off-white) au lieu du blanc
      // pur du thème par défaut. Sans ça les cards blanches DetailInfoCard
      // n'ont AUCUN contraste avec le fond → effet "fade" reproché. Avec
      // `dsBg`, les blancs des cards ressortent + l'ombre prend du sens.
      backgroundColor: brightness == Brightness.dark
          ? AppColors.dsBgDark
          : AppColors.dsBgLight,
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white, size: 34),
          onPressed: () => Navigator.of(context).pop(),
        ),
        actions: [
          // Phase 8.3 UI : bouton "Lire à deux" (créer un reading group)
          BlocBuilder<DetailBloc, DetailState>(
            builder: (context, state) {
              final mangaTitle = state is DetailLoaded
                  ? state.mangaDetail.title
                  : (widget.mangaTitle ?? '');
              return IconButton(
                icon: const Icon(Icons.groups_outlined,
                    color: Colors.white, size: 26),
                tooltip: AppLocalizations.of(context)?.readingGroupCreateTitle ??
                    'Lire à deux',
                onPressed: () {
                  showModalBottomSheet(
                    context: context,
                    isScrollControlled: true,
                    showDragHandle: false,
                    shape: const RoundedRectangleBorder(
                      borderRadius:
                          BorderRadius.vertical(top: Radius.circular(20)),
                    ),
                    builder: (_) => CreateReadingGroupSheet(
                      muId: widget.muId,
                      mangaTitle: mangaTitle,
                    ),
                  );
                },
              );
            },
          ),
          // Phase 8.1 : bouton "Partager avec un ami"
          IconButton(
            icon: const Icon(Icons.share_outlined,
                color: Colors.white, size: 26),
            tooltip: AppLocalizations.of(context)?.shareTitle ?? 'Partager',
            onPressed: () {
              showModalBottomSheet(
                context: context,
                isScrollControlled: true,
                showDragHandle: false,
                shape: const RoundedRectangleBorder(
                  borderRadius:
                      BorderRadius.vertical(top: Radius.circular(20)),
                ),
                builder: (_) => ShareMangaSheet(muId: widget.muId),
              );
            },
          ),
          BlocBuilder<DetailBloc, DetailState>(
            builder: (context, state) {
              final isOffline = state is DetailLoaded && state.isOffline ||
                               state is DetailError && state.isOffline;

              if (!isOffline) return const SizedBox.shrink();
              
              return Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                margin: const EdgeInsets.only(right: 8),
                decoration: BoxDecoration(
                  // Refactor 2026-05-18 : errorContainer au lieu de Colors.orange
                  color: Theme.of(context).colorScheme.error,
                  borderRadius: AppRadius.circularXl,
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(Icons.cloud_off, size: 16, color: Colors.white),
                    const SizedBox(width: 4),
                    Builder(
                      builder: (context) {
                        final l10n = AppLocalizations.of(context);
                        return Text(
                          l10n?.offlineMode ?? 'Hors ligne',
                          style: const TextStyle(color: Colors.white, fontSize: 12),
                        );
                      },
                    ),
                  ],
                ),
              );
            },
          ),
        ],
      ),
      // Responsive (audit 2026-06-12) : le cap local 900 qui contraignait
      // toute la page (hero compris) est retiré — le hero reste pleine
      // largeur (cinématique) et le contenu sous le hero est centré via
      // AppContentWidth (cf. `_buildDetailContent`).
      body: SafeArea(
        top: false,
        child: BlocConsumer<DetailBloc, DetailState>(
          listener: (context, state) {
            if (state is DetailError) {
              if (state.message.contains('InvalidCredentials') ||
                  state.message.contains('Expired session')) {
                widget.onRedirectToLogin();
              }
            }
          },
          builder: (context, state) {
            if (state is DetailLoading) {
              return const Center(child: CircularProgressIndicator());
            }
            
            if (state is DetailActionInProgress) {
              return Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const CircularProgressIndicator(),
                    const SizedBox(height: 16),
                    Text(
                      state.action,
                      style: Theme.of(context).textTheme.bodyLarge,
                    ),
                  ],
                ),
              );
            }
            
            if (state is DetailError) {
              return Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      state.isOffline ? Icons.cloud_off : Icons.error,
                      size: 64,
                      // Refactor 2026-05-18 : utilise le theme au lieu de Colors.orange/red
                      color: Theme.of(context).colorScheme.error,
                    ),
                    const SizedBox(height: 16),
                    Builder(
                      builder: (context) {
                        final l10n = AppLocalizations.of(context);
                        return Text(
                          state.isOffline 
                              ? (l10n?.offlineModeNoCache ?? 'Mode hors ligne - Aucune donnée en cache')
                              : '${l10n?.error ?? "Erreur"}: ${state.message}',
                          textAlign: TextAlign.center,
                        );
                      },
                    ),
                    const SizedBox(height: 16),
                    Builder(
                      builder: (context) {
                        final l10n = AppLocalizations.of(context);
                        return ElevatedButton(
                          onPressed: () => context.read<DetailBloc>().add(LoadMangaDetail(widget.muId)),
                          child: Text(l10n?.retry ?? 'Réessayer'),
                        );
                      },
                    ),
                  ],
                ),
              );
            }
            
            if (state is DetailLoaded) {
              return _buildDetailContent(state);
            }

            return const SizedBox.shrink();
          },
        ),
      ),
    );
  }

  Widget _buildDetailContent(DetailLoaded state) {
    final manga = state.mangaDetail;
    customLink = manga.customLink;
    lastReadChapters = manga.readChaptersCount ?? 0;
    
    // Récupérer l'état de la bibliothèque
    final readChapters = manga.readChaptersCount ?? -1;
    // Le statut est récupéré depuis le DTO - null si pas dans la bibliothèque
    final ReadingStatus? status = manga.inLibrary ? (manga.readingStatus ?? ReadingStatus.readLater) : null;

    return Column(
      children: [
        Expanded(
          child: Column(
            children: [
              // Header avec image et titre
              GestureDetector(
                onTap: () {
                  // Afficher l'image en plein écran
                  showDialog(
                    context: context,
                    // Barrier adapté au thème : 0.75 en light suffit pour
                    // isoler l'image, 0.85 en dark (audit design 2026-06-12).
                    barrierColor: Theme.of(context).brightness ==
                            Brightness.dark
                        ? Colors.black.withValues(alpha: 0.85)
                        : Colors.black.withValues(alpha: 0.75),
                    builder: (context) => Dialog(
                      backgroundColor: Colors.transparent,
                      insetPadding: const EdgeInsets.all(20),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(AppRadius.jumbo),
                      ),
                      child: ClipRRect(
                        borderRadius: AppRadius.circularJumbo,
                        child: Container(
                          decoration: BoxDecoration(
                            borderRadius: AppRadius.circularJumbo,
                            color: Colors.transparent,
                          ),
                          child: Stack(
                            children: [
                              Center(
                                child: ClipRRect(
                                  borderRadius: AppRadius.circularJumbo,
                                  child: InteractiveViewer(
                                    minScale: 0.5,
                                    maxScale: 3.0,
                                    // Proxy (hotfix-v0-10-1 US-2) : l'URL MU
                                    // brute est bloquée par CORS sur le web.
                                    child: RefreshableMangaImage(
                                      muId: widget.muId.toString(),
                                      originalUrl: widget.coverPath ??
                                          manga.largeCoverUrl ??
                                          manga.mediumCoverUrl,
                                      fit: BoxFit.contain,
                                      useProxy: true,
                                    ),
                                  ),
                                ),
                              ),
                              Positioned(
                                top: 10,
                                right: 10,
                                child: Container(
                                  decoration: BoxDecoration(
                                    color: Colors.black54,
                                    shape: BoxShape.circle,
                                  ),
                                  child: IconButton(
                                    icon: const Icon(Icons.close, color: Colors.white, size: 24),
                                    onPressed: () => Navigator.of(context).pop(),
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  );
                },
                child: Stack(
                  children: [
                    SizedBox(
                      width: double.infinity,
                      height: 340,
                      // Proxy (hotfix-v0-10-1 US-2) : CORS web.
                      child: RefreshableMangaImage(
                        muId: widget.muId.toString(),
                        originalUrl: widget.coverPath ?? manga.mediumCoverUrl,
                        fit: BoxFit.cover,
                        useProxy: true,
                      ),
                    ),
                    Container(
                      width: double.infinity,
                      height: 340,
                      color: Colors.black.withValues(alpha: 0.4),
                    ),
                    Positioned(
                      top: 70,
                      left: 16,
                      right: 16,
                      child: IgnorePointer(
                        child: AutoSizeText(
                          parse(manga.title).documentElement?.text ?? '',
                          textAlign: TextAlign.center,
                          maxLines: 2,
                          style: GoogleFonts.poppins(
                            fontSize: 28,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                          ),
                        ),
                      ),
                    ),
                    if (manga.genres != null && manga.genres!.isNotEmpty)
                      Positioned(
                        bottom: 14,
                        left: AppSpacing.m,
                        right: AppSpacing.m,
                        child: GestureDetector(
                          // Empêcher le clic de remonter au GestureDetector parent
                          onTap: () {},
                          child: DetailGenreChips(genres: manga.genres!),
                        ),
                      ),
                  ],
                ),
              ),
              // Détails du manga (LateDetailView) — contenu sous le hero
              // centré (max 1100) via AppContentWidth (audit 2026-06-12) ;
              // le hero au-dessus reste pleine largeur (cinématique).
              Expanded(
                child: AppContentWidth(
                  child: RefreshIndicator(
                    onRefresh: () async {
                      context.read<DetailBloc>().add(const RefreshMangaDetail());
                      await Future.delayed(const Duration(milliseconds: 500));
                    },
                    child: LateDetailView(
                      muId: widget.muId.toString(),
                      mangaTitle: manga.title,
                      mangaDescription: manga.description,
                      rating: manga.rating,
                      mangaChapters: ChaptersHelper.buildChapterList(manga.totalChapters),
                      mangaTotalChapters: manga.totalChapters,
                      isCompleted: manga.isCompleted,
                      authors: manga.authors,
                      year: manga.year,
                      readChapters: readChapters,
                      genres: manga.genres,
                      seasonChapters: manga.seasonChapters,
                      bonusChapters: manga.bonusChapters,
                      associated: manga.associated,
                      onReadCountChanged: (newCount) {
                        // Dispatcher l'événement au BLoC pour mise à jour réactive
                        context.read<DetailBloc>().add(SaveChapterProgress(widget.muId, newCount.toInt()));
                      },
                      onAddToLibrary: () {
                        // Dispatcher l'événement au BLoC
                        context.read<DetailBloc>().add(AddToLibrary(widget.muId));
                      },
                      onRemoveFromLibrary: () {
                        // Dispatcher l'événement au BLoC
                        context.read<DetailBloc>().add(RemoveFromLibrary(widget.muId));
                      },
                      // **Fix 2026-05-19** : la notation utilisateur est désormais
                      // injectée dans le flux scrollable de LateDetailView (entre
                      // stats grid et Noms associés) au lieu d'être pinnée en bas.
                      // Libère de la place verticale fixe pour voir + de contenu.
                      inlineRatingSlot: manga.inLibrary
                          ? DetailRatingSection(
                              muId: widget.muId,
                              userRating: manga.userRating,
                              communityRating: manga.communityRating,
                              communityRatingCount: manga.communityRatingCount,
                            )
                          : null,
                    ),
                  ),
                ),
              ),
              // **Fix 2026-05-19 v2** : le bouton de statut a été déplacé
              // dans l'action bar (à gauche de "Lire en ligne") sous forme
              // d'icône 48px, pour libérer de la hauteur fixe. Cf. l'icône
              // `_StatusIconButton` dans `_buildBottomActionBar`.
              // L'action bar suit la même largeur max que le contenu.
              AppContentWidth(child: _buildBottomActionBar(status)),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildBottomActionBar(ReadingStatus? status) {
    final muId = widget.muId;
    final brightness = Theme.of(context).brightness;

    // Pas dans la bibliothèque → CTA full-width "Ajouter à la bibliothèque"
    // + petit bouton recos circulaire à droite.
    if (status == null) {
      return Container(
        padding: const EdgeInsets.fromLTRB(
          AppSpacing.m,
          AppSpacing.s,
          AppSpacing.m,
          AppSpacing.m,
        ),
        decoration: BoxDecoration(
          border: Border(
            top: BorderSide(
              color: AppColors.dsHairline(brightness),
              width: 1,
            ),
          ),
        ),
        child: Row(
          children: [
            Expanded(
              child: DetailAddToLibraryButton(
                muId: muId,
                onAdded: () {
                  final l10n = AppLocalizations.of(context);
                  widget.notifier.info(
                    l10n?.addToLibrary ?? "Manga ajouté à la bibliothèque",
                  );
                },
              ),
            ),
            const SizedBox(width: AppSpacing.s),
            _RecommendationsIconButton(
              onTap: () => _showRecommendationsSheet(muId),
            ),
          ],
        ),
      );
    }

    // Dans la bibliothèque → action bar V1 :
    //   [status icon] [Lire en ligne / Ajouter un lien] [recos icon]
    // **Fix 2026-05-19** : ajout du status icon à gauche (avant on avait un
    // bouton large au-dessus de l'action bar qui mangeait de la hauteur).
    return Container(
      padding: const EdgeInsets.fromLTRB(
        0,
        AppSpacing.xs,
        0,
        AppSpacing.s,
      ),
      decoration: BoxDecoration(
        border: Border(
          top: BorderSide(
            color: AppColors.dsHairline(brightness),
            width: 1,
          ),
        ),
      ),
      child: Row(
        children: [
          // status est garanti non-null ici (branch atteinte uniquement
          // quand le manga est dans la bibliothèque, cf. early return ligne ~499)
          Padding(
            padding: const EdgeInsets.only(left: AppSpacing.m),
            child: _StatusIconButton(
              status: status,
              onTap: () => _showManageLibrarySheet(status),
            ),
          ),
          Expanded(
            child: DetailReadOnlineButton(
              hasCustomLink: customLink != null,
              onReadOnline: () => _handleReadOnline(muId),
              onAddLink: _addCustomLink,
              onOpenMenu: _showCustomLinkMenu,
            ),
          ),
          Padding(
            padding: const EdgeInsets.only(right: AppSpacing.m),
            child: _RecommendationsIconButton(
              onTap: () => _showRecommendationsSheet(muId),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _handleReadOnline(int muId) async {
    final lastRead = lastReadChapters;
    final nextChapterNumber = lastRead + 1;
    final baseLink = customLink ?? '';
    final targetUrl = await ChapterLinkResolver.buildUrlForChapter(
            baseLink, nextChapterNumber) ?? baseLink;

    // Récupérer le titre du manga depuis le state
    if (!mounted) return;
    final currentState = context.read<DetailBloc>().state;
    String? mangaTitle;
    if (currentState is DetailLoaded) {
      mangaTitle = currentState.mangaDetail.title;
    } else {
      mangaTitle = widget.mangaTitle;
    }

    // Vérifier si le chapitre est téléchargé
    final downloadManager = DownloadManagerService();
    final isDownloaded = await downloadManager.isChapterDownloaded(
      muId,
      nextChapterNumber,
    );
    if (!mounted) return;

    if (isDownloaded && mangaTitle != null) {
      await context.push(
        '/manga/$muId/read-offline?chapter=$nextChapterNumber',
        extra: OfflineReaderExtras(mangaTitle: mangaTitle),
      );
    } else {
      await context.push(
        '/manga/$muId/read',
        extra: ReaderWebExtras(
          mangaTitle: mangaTitle,
          initialLastRead: lastRead,
          initialUrl: targetUrl,
          baseUserLink: baseLink,
        ),
      );
    }
    if (mounted) widget.onRefreshLibraryState(context);
  }

  Future<void> _showRecommendationsSheet(int muId) async {
    // Chargement des recommandations avec gestion d'erreur
    if (_mangaRecommendationsCache == null) {
      try {
        _mangaRecommendationsCache =
            await widget.mangaService.getMangaRecommendations(muId.toString());
      } catch (e) {
        _mangaRecommendationsCache = [];
        debugPrint('❌ Erreur chargement recommandations: $e');
      }
    }
    if (!mounted) return;

    final recos = _mangaRecommendationsCache ?? [];
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) {
        final l10n = AppLocalizations.of(ctx);
        return SafeArea(
          child: ConstrainedBox(
            constraints: BoxConstraints(
              maxHeight: MediaQuery.of(ctx).size.height * 0.7,
            ),
            child: Padding(
              padding: const EdgeInsets.only(top: AppSpacing.s),
              child: SingleChildScrollView(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Padding(
                      padding: const EdgeInsets.fromLTRB(
                        AppSpacing.m,
                        AppSpacing.s,
                        AppSpacing.m,
                        0,
                      ),
                      child: Text(
                        l10n?.recommendedMangas ?? 'Mangas recommandés',
                        style: Theme.of(ctx).textTheme.titleLarge?.copyWith(
                              fontWeight: FontWeight.w700,
                            ),
                      ),
                    ),
                    DetailRecommendationsSection(
                      recommendations: recos,
                    ),
                  ],
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  /// Sheet de gestion de bibliothèque V1 (refactor 2026-05-19).
  ///
  /// Affiche les 4 statuts disponibles sous forme de rows tappables
  /// (style ProfileEditField focused = primary border + bg primary léger
  /// pour le statut actif). En bas : bouton "Retirer de la bibliothèque"
  /// (action destructive isolée, OutlinedButton rouge).
  void _showManageLibrarySheet(ReadingStatus status) {
    final muId = widget.muId;
    final detailBloc = context.read<DetailBloc>();
    showModalBottomSheet(
      context: context,
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) {
        final scheme = Theme.of(ctx).colorScheme;
        final sheetBrightness = Theme.of(ctx).brightness;
        return BlocProvider.value(
          value: detailBloc,
          child: SafeArea(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(
                AppSpacing.m,
                AppSpacing.m,
                AppSpacing.m,
                AppSpacing.s,
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Builder(
                    builder: (context) {
                      final l10n = AppLocalizations.of(context);
                      return Text(
                        l10n?.changeStatus ?? 'Changer le statut',
                        style: Theme.of(context).textTheme.titleMedium?.copyWith(
                              fontWeight: FontWeight.w700,
                            ),
                      );
                    },
                  ),
                  const SizedBox(height: AppSpacing.m),
                  // 4 statuts tappables
                  for (final entry in const [
                    ReadingStatus.reading,
                    ReadingStatus.readLater,
                    ReadingStatus.caughtUp,
                    ReadingStatus.completed,
                  ])
                    _StatusSheetRow(
                      value: entry,
                      isActive: entry == status,
                      onTap: () {
                        Navigator.of(ctx).pop();
                        if (entry == status) return;
                        final l10n = AppLocalizations.of(context);
                        context
                            .read<DetailBloc>()
                            .add(UpdateReadingStatus(entry));
                        widget.notifier.info(
                          "${l10n?.mangaMarkedAs ?? 'Manga marqué comme'} '${entry.getLabel(context)}'",
                        );
                      },
                    ),
                  const SizedBox(height: AppSpacing.m),
                  Divider(color: AppColors.dsHairline(sheetBrightness)),
                  const SizedBox(height: AppSpacing.m),
                  Builder(
                    builder: (context) {
                      final l10n = AppLocalizations.of(context);
                      return OutlinedButton.icon(
                        onPressed: () {
                          Navigator.of(ctx).pop();
                          context
                              .read<DetailBloc>()
                              .add(RemoveFromLibrary(muId));
                          widget.notifier.info(
                            l10n?.mangaRemovedFromLibrary ??
                                "Manga retiré de la bibliothèque",
                          );
                        },
                        icon: const Icon(Icons.delete_outline, size: 18),
                        label: Text(
                          l10n?.removeFromLibrary ??
                              'Retirer de la bibliothèque',
                        ),
                        style: OutlinedButton.styleFrom(
                          foregroundColor: scheme.error,
                          minimumSize: const Size.fromHeight(48),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(14),
                          ),
                          side: BorderSide(
                            color: scheme.error.withValues(alpha: 0.5),
                          ),
                          textStyle: const TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      );
                    },
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  void _showCustomLinkMenu() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: false,
      builder: (ctx) {
        return SafeArea(
          child: Wrap(
            children: [
              ListTile(
                leading: Icon(
                  Icons.edit,
                  color: Theme.of(context).colorScheme.primary,
                ),
                title: Builder(
                  builder: (context) {
                    final l10n = AppLocalizations.of(context);
                    return Text(l10n?.modifyLink ?? "Modifier le lien");
                  },
                ),
                onTap: () {
                  Navigator.of(ctx).pop();
                  _addCustomLink();
                },
              ),
              ListTile(
                leading: const Icon(Icons.download, color: Colors.blue),
                title: const Text('Télécharger des chapitres'),
                onTap: () {
                  Navigator.of(ctx).pop();
                  _showDownloadDialog(ctx);
                },
              ),
              ListTile(
                leading: const Icon(Icons.delete_outline, color: Colors.red),
                title: Builder(
                  builder: (context) {
                    final l10n = AppLocalizations.of(context);
                    return Text(
                      l10n?.removeLink ?? "Supprimer le lien",
                      style: const TextStyle(color: Colors.red),
                    );
                  },
                ),
                onTap: () {
                  Navigator.of(ctx).pop();
                  _removeCustomLink(context);
                },
              ),
            ],
          ),
        );
      },
    );
  }

  Future<void> _addCustomLink() async {
    final controller = TextEditingController(text: customLink);
    bool hasChapterFormat = false;
    bool isCheckingCustomPatterns = false;
    final selectorsService = CustomSelectorsService();
    
    final link = await showDialog<String?>(
      context: context,
      builder: (ctx) {
        return StatefulBuilder(
          builder: (context, setState) {
            final l10n = AppLocalizations.of(context);
            
            // Vérifier si l'URL contient un format de chapitre
            Future<void> checkChapterFormat() async {
              final text = controller.text.trim();
              if (text.isEmpty) {
                setState(() {
                  hasChapterFormat = false;
                  isCheckingCustomPatterns = false;
                });
                return;
              }
              
              // Vérifier d'abord les patterns par défaut
              final detectedChapter = ChapterLinkResolver.extractChapterSync(text);
              if (detectedChapter != null) {
                setState(() {
                  hasChapterFormat = true;
                  isCheckingCustomPatterns = false;
                });
                return;
              }
              
              // Si aucun pattern par défaut ne correspond, vérifier les patterns personnalisés
              setState(() => isCheckingCustomPatterns = true);
              try {
                // Initialiser le service pour vérifier les patterns personnalisés
                ChapterLinkResolver.init(selectorsService);
                final customDetectedChapter = await ChapterLinkResolver.extractChapter(text);
                setState(() {
                  hasChapterFormat = customDetectedChapter != null;
                  isCheckingCustomPatterns = false;
                });
              } catch (e) {
                setState(() {
                  hasChapterFormat = false;
                  isCheckingCustomPatterns = false;
                });
              }
            }
            
            // Vérifier au chargement initial
            if (controller.text.isNotEmpty) {
              WidgetsBinding.instance.addPostFrameCallback((_) {
                checkChapterFormat();
              });
            }
            
            return AlertDialog(
              title: Row(
                children: [
                  const Icon(Icons.link, color: Colors.blue),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(l10n?.addOrModifyLink ?? 'Ajouter ou modifier un lien'),
                  ),
                ],
              ),
              content: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    TextField(
                      controller: controller,
                      decoration: InputDecoration(
                        labelText: l10n?.linkUrlLabel ?? 'URL du site de scan',
                        hintText: l10n?.linkUrlPlaceholder ?? 'https://exemple.com/manga/chapitre-23',
                        border: const OutlineInputBorder(),
                        prefixIcon: const Icon(Icons.language),
                        suffixIcon: isCheckingCustomPatterns
                            ? const SizedBox(
                                width: 20,
                                height: 20,
                                child: Padding(
                                  padding: EdgeInsets.all(12.0),
                                  child: CircularProgressIndicator(strokeWidth: 2),
                                ),
                              )
                            : null,
                      ),
                      onChanged: (_) => checkChapterFormat(),
                    ),
                    const SizedBox(height: 16),
                    // Message d'aide
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: Colors.blue.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: Colors.blue.withValues(alpha: 0.3)),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              const Icon(Icons.info_outline, color: Colors.blue, size: 20),
                              const SizedBox(width: 8),
                              Expanded(
                                child: Text(
                                  l10n?.linkFormatInfo ?? 'Format de chapitre requis',
                                  style: const TextStyle(
                                    fontWeight: FontWeight.bold,
                                    fontSize: 14,
                                  ),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 8),
                          Text(
                            l10n?.linkFormatDescription ?? 
                            'Incluez le numéro de chapitre dans l\'URL pour permettre la sauvegarde automatique de progression.\n\n'
                            'Formats acceptés :\n'
                            '• /chapitre-23/ ou /chapter-23/\n'
                            '• /c23/ ou /ch23/\n'
                            '• /ep-23/ ou /episode-23/\n'
                            '• ?chapter=23 ou ?num=24',
                            style: const TextStyle(fontSize: 12),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 12),
                    // Avertissement si pas de format détecté
                    if (!hasChapterFormat && controller.text.trim().isNotEmpty && !isCheckingCustomPatterns)
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: Colors.orange.withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(color: Colors.orange.withValues(alpha: 0.3)),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const Icon(Icons.warning_amber_rounded, color: Colors.orange, size: 20),
                                const SizedBox(width: 8),
                                Expanded(
                                  child: Text(
                                    l10n?.linkFormatWarning ?? 
                                    'Aucun format de chapitre détecté. Le lien redirigera vers la page du manga (pas un chapitre spécifique).',
                                    style: const TextStyle(fontSize: 12),
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 8),
                            InkWell(
                              onTap: () {
                                Navigator.of(ctx).pop();
                                context.push('/custom-selectors');
                              },
                              child: Container(
                                padding: const EdgeInsets.all(8),
                                decoration: BoxDecoration(
                                  color: Colors.orange.withValues(alpha: 0.1),
                                  borderRadius: BorderRadius.circular(6),
                                ),
                                child: Row(
                                  children: [
                                    const Icon(Icons.add_circle_outline, color: Colors.orange, size: 18),
                                    const SizedBox(width: 8),
                                    Expanded(
                                      child: Text(
                                        l10n?.linkAddCustomPattern ?? 
                                        'Ajouter un pattern personnalisé pour ce format',
                                        style: const TextStyle(
                                          fontSize: 11,
                                          color: Colors.orange,
                                          decoration: TextDecoration.underline,
                                        ),
                                      ),
                                    ),
                                    const Icon(Icons.arrow_forward, color: Colors.orange, size: 16),
                                  ],
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    // Confirmation si format détecté
                    if (hasChapterFormat && !isCheckingCustomPatterns)
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: Colors.green.withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(color: Colors.green.withValues(alpha: 0.3)),
                        ),
                        child: Row(
                          children: [
                            const Icon(Icons.check_circle, color: Colors.green, size: 20),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Text(
                                l10n?.linkFormatDetected ?? 
                                'Format de chapitre détecté ! La progression sera sauvegardée automatiquement.',
                                style: const TextStyle(fontSize: 12),
                              ),
                            ),
                          ],
                        ),
                      ),
                  ],
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.of(ctx).pop(null),
                  child: Text(
                    l10n?.cancel ?? 'Annuler',
                    style: TextStyle(
                      color: Theme.of(context).colorScheme.secondary,
                    ),
                  ),
                ),
                ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Theme.of(context).colorScheme.primary,
                    foregroundColor: Theme.of(context).colorScheme.onPrimary,
                  ),
                  onPressed: () {
                    final link = controller.text.trim();
                    final uri = Uri.tryParse(link);
                    final isValid = uri != null &&
                        uri.hasScheme &&
                        (uri.isAbsolute || uri.host.isNotEmpty);

                    if (isValid) {
                      Navigator.of(ctx).pop(link);
                    } else {
                      widget.notifier.error(
                        l10n?.invalidLink ?? "Lien invalide. Le lien doit commencer par http:// ou https://",
                      );
                    }
                  },
                  child: Text(l10n?.validate ?? 'Valider'),
                ),
              ],
            );
          },
        );
      },
    );

    if (link != null && mounted) {
      await _saveCustomLink(link, context);
    }
  }

  Future<void> _saveCustomLink(String link, BuildContext context) async {
    final l10n = AppLocalizations.of(context);
    context.read<DetailBloc>().add(UpdateCustomLink(link));
    widget.notifier.success(l10n?.linkSaved ?? "Lien enregistré !");
  }

  Future<void> _removeCustomLink(BuildContext context) async {
    final l10n = AppLocalizations.of(context);
    context.read<DetailBloc>().add(DeleteCustomLink());
    widget.notifier.success(l10n?.linkRemoved ?? "Lien supprimé !");
  }

  void _showDownloadDialog(BuildContext context) {
    final state = this.context.read<DetailBloc>().state;
    if (state is! DetailLoaded) return;

    final manga = state.mangaDetail;
    if (manga.customLink == null || manga.customLink!.isEmpty) {
      widget.notifier.warning('Veuillez d\'abord ajouter un lien personnalisé');
      return;
    }

    showDialog(
      context: context,
      builder: (ctx) => ChapterDownloadDialog(
        muId: widget.muId,
        mangaTitle: manga.title,
        baseUrl: manga.customLink!,
        totalChapters: manga.totalChapters,
        readChapters: manga.readChaptersCount,
      ),
    );
  }
}

/// Bouton icône "Recommandations" V1 — pill circulaire hairline + icône sparkles.
class _RecommendationsIconButton extends StatelessWidget {
  final VoidCallback onTap;
  const _RecommendationsIconButton({required this.onTap});

  @override
  Widget build(BuildContext context) {
    final brightness = Theme.of(context).brightness;
    final scheme = Theme.of(context).colorScheme;
    final isDark = brightness == Brightness.dark;
    final l10n = AppLocalizations.of(context);
    return Tooltip(
      message: l10n?.recommendations ?? 'Recommandations',
      child: InkWell(
        borderRadius: BorderRadius.circular(14),
        onTap: onTap,
        child: Container(
          width: 48,
          height: 48,
          decoration: BoxDecoration(
            color: isDark ? AppColors.dsSurfaceDark : Colors.white,
            borderRadius: BorderRadius.circular(14),
            border: Border.all(
              color: AppColors.dsBorder(brightness),
              width: 1,
            ),
          ),
          child: Icon(
            Icons.auto_awesome_outlined,
            size: 22,
            color: scheme.primary,
          ),
        ),
      ),
    );
  }
}

/// Bouton icône "Changer le statut" V1 — 48×48 hairline, icône du statut
/// courant en `primary`. Tap → ouvre la sheet de gestion. Placé à gauche
/// de "Lire en ligne" dans l'action bar (refactor 2026-05-19).
class _StatusIconButton extends StatelessWidget {
  final ReadingStatus status;
  final VoidCallback onTap;

  const _StatusIconButton({required this.status, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final brightness = Theme.of(context).brightness;
    final scheme = Theme.of(context).colorScheme;
    final isDark = brightness == Brightness.dark;
    final l10n = AppLocalizations.of(context);
    return Tooltip(
      message: l10n?.changeStatus ?? 'Changer le statut',
      child: InkWell(
        borderRadius: BorderRadius.circular(14),
        onTap: onTap,
        child: Container(
          width: 48,
          height: 48,
          decoration: BoxDecoration(
            color: isDark ? AppColors.dsSurfaceDark : Colors.white,
            borderRadius: BorderRadius.circular(14),
            border: Border.all(
              color: AppColors.dsBorder(brightness),
              width: 1,
            ),
          ),
          child: Icon(
            status.icon,
            size: 22,
            color: scheme.primary,
          ),
        ),
      ),
    );
  }
}

/// Row tappable d'un statut dans la sheet de gestion (V1 2026-05-19).
///
/// Affiche : icône du statut + label, avec un style mis en valeur si actif :
///   - actif : bg `dsRedSoft`, border primary, check icon à droite
///   - inactif : transparent, border hairline
class _StatusSheetRow extends StatelessWidget {
  final ReadingStatus value;
  final bool isActive;
  final VoidCallback onTap;

  const _StatusSheetRow({
    required this.value,
    required this.isActive,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final brightness = Theme.of(context).brightness;
    final scheme = Theme.of(context).colorScheme;
    final bg = isActive
        ? AppColors.dsRedSoft(brightness)
        : Colors.transparent;
    final borderColor = isActive
        ? scheme.primary
        : AppColors.dsHairline(brightness);
    final fg = isActive ? scheme.primary : scheme.onSurface;

    return Padding(
      padding: const EdgeInsets.only(bottom: AppSpacing.s),
      child: Material(
        color: Colors.transparent,
        borderRadius: BorderRadius.circular(12),
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(12),
          child: Container(
            padding: const EdgeInsets.symmetric(
              horizontal: 14,
              vertical: 12,
            ),
            decoration: BoxDecoration(
              color: bg,
              border: Border.all(color: borderColor, width: 1),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Row(
              children: [
                Icon(value.icon, size: 18, color: fg),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    value.getLabel(context),
                    style: TextStyle(
                      fontSize: 14.5,
                      fontWeight: isActive
                          ? FontWeight.w700
                          : FontWeight.w500,
                      color: fg,
                    ),
                  ),
                ),
                if (isActive)
                  Icon(Icons.check, size: 18, color: scheme.primary),
              ],
            ),
          ),
        ),
      ),
    );
  }
}