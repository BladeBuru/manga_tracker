import 'package:auto_size_text/auto_size_text.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:html/parser.dart';
import 'package:mangatracker/core/router/app_router.dart';
import 'package:mangatracker/core/service_locator/service_locator.dart';
import 'package:mangatracker/features/manga/bloc/detail_bloc.dart';
import 'package:mangatracker/features/manga/bloc/detail_event.dart';
import 'package:mangatracker/features/manga/bloc/detail_state.dart';
import 'package:mangatracker/features/manga/dto/reading_status.enum.dart';
import 'package:mangatracker/features/manga/helpers/chapters.helper.dart';
import 'package:mangatracker/features/manga/helpers/image.helper.dart';
import 'package:mangatracker/features/manga/views/late_detail.view.dart';
import 'package:mangatracker/features/manga/widgets/manga_card.dart';
import 'package:mangatracker/features/manga/services/manga.service.dart';
import 'package:mangatracker/core/notifier/notifier.dart';
import 'package:mangatracker/core/theme/app_radius.dart';
import 'package:mangatracker/core/components/user_rating_stars.dart';
import '../../reader/utils/chapter_link_resolver.dart';
import '../dto/manga_recommendation_view.dto.dart';
import 'package:mangatracker/l10n/app_localizations.dart';
import '../services/custom_selectors.service.dart';
import 'chapter_download_dialog.dart';
import 'package:mangatracker/features/download/services/download_manager_service.dart';

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
    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white, size: 34),
          onPressed: () => Navigator.of(context).pop(),
        ),
        actions: [
          BlocBuilder<DetailBloc, DetailState>(
            builder: (context, state) {
              final isOffline = state is DetailLoaded && state.isOffline ||
                               state is DetailError && state.isOffline;
              
              if (!isOffline) return const SizedBox.shrink();
              
              return Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                margin: const EdgeInsets.only(right: 8),
                decoration: BoxDecoration(
                  color: Colors.orange,
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
                      color: state.isOffline ? Colors.orange : Colors.red,
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
                    barrierColor: Colors.black87,
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
                                    child: ImageHelper.loadMangaImage(
                                      widget.coverPath ?? manga.largeCoverUrl ?? manga.mediumCoverUrl,
                                      fit: BoxFit.contain,
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
                      child: ImageHelper.loadMangaImage(
                        widget.coverPath ?? manga.mediumCoverUrl,
                        fit: BoxFit.cover,
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
                        left: 16,
                        right: 16,
                        child: GestureDetector(
                          onTap: () {}, // Empêcher le clic de remonter au GestureDetector parent
                          child: SizedBox(
                            height: 32,
                            child: Scrollbar(
                              thumbVisibility: true,
                              thickness: 4,
                              radius: const Radius.circular(2),
                              child: ListView(
                                scrollDirection: Axis.horizontal,
                                children: manga.genres!
                                    .map((g) => Padding(
                                          padding: const EdgeInsets.only(right: 8),
                                          child: Container(
                                            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                                            decoration: BoxDecoration(
                                              color: Colors.white.withValues(alpha: 0.9),
                                              borderRadius: AppRadius.circularXl,
                                              border: Border.all(
                                                color: Colors.white.withValues(alpha: 0.3),
                                                width: 1,
                                              ),
                                            ),
                                            child: Text(
                                              g,
                                              style: const TextStyle(
                                                fontSize: 12,
                                                fontWeight: FontWeight.w500,
                                                color: Colors.black87,
                                              ),
                                            ),
                                          ),
                                        ))
                                    .toList(),
                              ),
                            ),
                          ),
                        ),
                      ),
                  ],
                ),
              ),
              // Détails du manga (LateDetailView)
              Expanded(
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
                  ),
                ),
              ),
              // Notation utilisateur (visible uniquement si dans la bibliothèque)
              if (manga.inLibrary) _buildUserRatingRow(manga.userRating),
              // Barre d'action en bas
              _buildBottomActionBar(status),
            ],
          ),
        ),
      ],
    );
  }

  /// Affiche le widget de notation 5 étoiles + label "Votre note".
  /// Mis à jour optimiste via [UpdateUserRating] event.
  Widget _buildUserRatingRow(int currentRating) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Builder(
            builder: (context) {
              final l10n = AppLocalizations.of(context);
              return Text(
                l10n?.yourRating ?? 'Votre note',
                style: Theme.of(context).textTheme.labelMedium,
              );
            },
          ),
          UserRatingStars(
            rating: currentRating,
            size: 24,
            onRatingChanged: (newRating) {
              context.read<DetailBloc>().add(
                    UpdateUserRating(widget.muId, newRating),
                  );
            },
          ),
        ],
      ),
    );
  }

  Widget _buildBottomActionBar(ReadingStatus? status) {
    final muId = widget.muId;
    final buttonShape = RoundedRectangleBorder(
      borderRadius: BorderRadius.circular(AppRadius.xxl),
    );

    if (status == null) {
      return Container(
        height: 70,
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8.0),
        child: Row(
          children: [
            Expanded(
              child: SizedBox(
                width: double.infinity,
                height: double.infinity,
                child: ElevatedButton.icon(
                  icon: Icon(ReadingStatus.readLater.icon),
                  label: Builder(
                    builder: (context) {
                      final l10n = AppLocalizations.of(context);
                      return Text(l10n?.addToLibrary ?? 'Ajouter à "À lire plus tard"');
                    },
                  ),
                  onPressed: () {
                    final l10n = AppLocalizations.of(context);
                    context.read<DetailBloc>().add(AddToLibrary(muId));
                    widget.notifier.info(l10n?.addToLibrary ?? "Manga ajouté à 'À lire plus tard'");
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Theme.of(context).colorScheme.primary,
                    foregroundColor: Theme.of(context).colorScheme.onPrimary,
                    shape: buttonShape,
                    textStyle: const TextStyle(fontSize: 17),
                  ),
                ),
              ),
            ),
            const SizedBox(width: 12),
            _buildRecommendationButton(buttonShape, muId),
          ],
        ),
      );
    }

    final leftButton = ElevatedButton(
      style: ElevatedButton.styleFrom(
        backgroundColor: status.color.withAlpha(50),
        foregroundColor: status.color,
        elevation: 0,
        shape: buttonShape,
      ),
      onPressed: () => _showManageLibrarySheet(status),
      child: Icon(status.icon),
    );

    if (customLink == null) {
      final rightButton = ElevatedButton.icon(
        style: ElevatedButton.styleFrom(
          backgroundColor: Theme.of(context).colorScheme.primary,
          foregroundColor: Theme.of(context).colorScheme.onPrimary,
          shape: buttonShape,
        ),
        onPressed: _addCustomLink,
        icon: const Icon(Icons.link_off),
        label: Builder(
          builder: (context) {
            final l10n = AppLocalizations.of(context);
            return Text(
              l10n?.addLink ?? 'Ajouter un lien',
              style: const TextStyle(fontSize: 17),
            );
          },
        ),
      );

      return Container(
        height: 70,
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8.0),
        child: Row(
          children: [
            Flexible(
              flex: 3,
              child: SizedBox(
                width: double.infinity,
                height: double.infinity,
                child: leftButton,
              ),
            ),
            const SizedBox(width: 15),
            Flexible(
              flex: 5,
              child: SizedBox(
                width: double.infinity,
                height: double.infinity,
                child: rightButton,
              ),
            ),
            const SizedBox(width: 12),
            _buildRecommendationButton(buttonShape, muId),
          ],
        ),
      );
    }

    final rightButton = SizedBox(
      width: double.infinity,
      height: double.infinity,
      child: Stack(
        children: [
          Positioned.fill(
            child: ElevatedButton.icon(
              style: ElevatedButton.styleFrom(
                backgroundColor: Theme.of(context).colorScheme.primary,
                foregroundColor: Theme.of(context).colorScheme.onPrimary,
                shape: buttonShape,
              ),
              onPressed: () async {
                final lastRead = lastReadChapters;
                final nextChapterNumber = lastRead + 1;
                final baseLink = customLink ?? '';
                final targetUrl = await ChapterLinkResolver.buildUrlForChapter(
                        baseLink, nextChapterNumber) ?? baseLink;
                
                // Récupérer le titre du manga depuis le state
                final currentState = context.read<DetailBloc>().state;
                String? mangaTitle;
                if (currentState is DetailLoaded) {
                  mangaTitle = currentState.mangaDetail.title;
                } else {
                  mangaTitle = widget.mangaTitle;
                }

                // Vérifier si le chapitre est téléchargé
                final downloadManager = DownloadManagerService();
                final isDownloaded = await downloadManager.isChapterDownloaded(muId, nextChapterNumber);
                
                if (isDownloaded && mangaTitle != null) {
                  // Utiliser la version hors ligne
                  await context.push(
                    '/manga/$muId/read-offline?chapter=$nextChapterNumber',
                    extra: OfflineReaderExtras(mangaTitle: mangaTitle!),
                  );
                } else {
                  // Utiliser la version en ligne
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
              },
              icon: const Icon(Icons.link),
              label: const Padding(
                padding: EdgeInsets.only(right: 24),
                child: Text('Lire en ligne', style: TextStyle(fontSize: 17)),
              ),
            ),
          ),
          Positioned(
            top: 0,
            bottom: 0,
            right: 8,
            child: Center(
              child: IconButton(
                icon: const Icon(Icons.more_vert, size: 20),
                color: Theme.of(context).colorScheme.onPrimary,
                onPressed: _showCustomLinkMenu,
                tooltip: (() {
                  final l10n = AppLocalizations.of(context);
                  return l10n?.manageLink ?? 'Gérer le lien';
                })(),
              ),
            ),
          ),
        ],
      ),
    );

    return Container(
      height: 70,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8.0),
      child: Row(
        children: [
          Flexible(
            flex: 3,
            child: SizedBox(
              width: double.infinity,
              height: double.infinity,
              child: leftButton,
            ),
          ),
          const SizedBox(width: 15),
          Flexible(
            flex: 5,
            child: SizedBox(
              width: double.infinity,
              height: double.infinity,
              child: rightButton,
            ),
          ),
          const SizedBox(width: 12),
          _buildRecommendationButton(buttonShape, muId),
        ],
      ),
    );
  }

  Widget _buildRecommendationButton(RoundedRectangleBorder buttonShape, int muId) {
    return SizedBox(
      width: 52,
      height: double.infinity,
      child: Tooltip(
        message: (() {
          final l10n = AppLocalizations.of(context);
          return l10n?.recommendations ?? 'Recommandations';
        })(),
        child: ElevatedButton(
          style: ElevatedButton.styleFrom(
            backgroundColor: Theme.of(context).colorScheme.primary,
            foregroundColor: Theme.of(context).colorScheme.onPrimary,
            padding: EdgeInsets.zero,
            elevation: 0,
            shape: buttonShape,
            minimumSize: Size.zero,
          ),
          onPressed: () async {
            // Chargement des recommandations avec gestion d'erreur
            if (_mangaRecommendationsCache == null) {
              try {
                _mangaRecommendationsCache = await widget.mangaService
                    .getMangaRecommendations(muId.toString());
              } catch (e) {
                _mangaRecommendationsCache = [];
                debugPrint('❌ Erreur chargement recommandations: $e');
              }
            }
            if (!mounted) return;

            final screenSize = MediaQuery.of(context).size;
            final recos = _mangaRecommendationsCache ?? [];

            showDialog(
              context: context,
              builder: (dialogContext) => AlertDialog(
                title: Builder(
                  builder: (ctx) {
                    final l10n = AppLocalizations.of(ctx);
                    return Text(l10n?.recommendedMangas ?? 'Mangas recommandés');
                  },
                ),
                content: ConstrainedBox(
                  constraints: BoxConstraints(
                    maxHeight: screenSize.height * 0.6,
                    minHeight: 200,
                    maxWidth: screenSize.width * 0.9,
                  ),
                  child: SizedBox(
                    width: screenSize.width * 0.9,
                    child: recos.isEmpty
                        ? Builder(
                            builder: (ctx) {
                              final l10n = AppLocalizations.of(ctx);
                              return Center(
                                child: Padding(
                                  padding: const EdgeInsets.all(32.0),
                                  child: Text(
                                    l10n?.noRecommendationsAvailable ??
                                        'Aucune recommandation disponible.',
                                    textAlign: TextAlign.center,
                                  ),
                                ),
                              );
                            },
                          )
                        : SingleChildScrollView(
                            padding: const EdgeInsets.symmetric(vertical: 8.0),
                            child: Wrap(
                              spacing: 12,
                              runSpacing: 12,
                              children: recos.map((manga) {
                                return SizedBox(
                                  width: 120,
                                  child: MangaCard(
                                    muId: manga.muId.toString(),
                                    mangaTitle: manga.title,
                                    mangaAuthor: manga.year,
                                    mediumImgPath: manga.mediumCoverUrl,
                                    rating: manga.rating,
                                  ),
                                );
                              }).toList(),
                            ),
                          ),
                  ),
                ),
                actions: [
                  Builder(
                    builder: (ctx) {
                      final l10n = AppLocalizations.of(ctx);
                      return TextButton(
                        child: Text(l10n?.close ?? 'Fermer'),
                        onPressed: () => Navigator.of(dialogContext).pop(),
                      );
                    },
                  ),
                ],
              ),
            );
          },
          child: const Icon(Icons.auto_awesome, size: 22),
        ),
      ),
    );
  }

  void _showManageLibrarySheet(ReadingStatus status) {
    final muId = widget.muId;
    final detailBloc = context.read<DetailBloc>();
    showModalBottomSheet(
      context: context,
      builder: (ctx) {
        return BlocProvider.value(
          value: detailBloc,
          child: SafeArea(
            child: Wrap(
              children: <Widget>[
                // Titre de la section
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                  child: Builder(
                    builder: (context) {
                      final l10n = AppLocalizations.of(context);
                      return Text(
                        l10n?.changeStatus ?? 'Changer le statut',
                        style: Theme.of(context).textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                      );
                    },
                  ),
                ),
                const Divider(height: 1),
                
                // En cours
                if (status != ReadingStatus.reading)
                  Builder(
                    builder: (context) {
                      final l10n = AppLocalizations.of(context);
                      return ListTile(
                        leading: Icon(ReadingStatus.reading.icon, color: ReadingStatus.reading.color),
                        title: Text(ReadingStatus.reading.getLabel(context)),
                        onTap: () {
                          Navigator.of(ctx).pop();
                          context.read<DetailBloc>().add(const UpdateReadingStatus(ReadingStatus.reading));
                          widget.notifier.info("${l10n?.mangaMarkedAs ?? 'Manga marqué comme'} '${ReadingStatus.reading.getLabel(context)}'");
                        },
                      );
                    },
                  ),
                
                // À lire plus tard
                if (status != ReadingStatus.readLater)
                  Builder(
                    builder: (context) {
                      final l10n = AppLocalizations.of(context);
                      return ListTile(
                        leading: Icon(ReadingStatus.readLater.icon, color: ReadingStatus.readLater.color),
                        title: Text(ReadingStatus.readLater.getLabel(context)),
                        onTap: () {
                          Navigator.of(ctx).pop();
                          context.read<DetailBloc>().add(const UpdateReadingStatus(ReadingStatus.readLater));
                          widget.notifier.info("${l10n?.mangaMarkedAs ?? 'Manga marqué comme'} '${ReadingStatus.readLater.getLabel(context)}'");
                        },
                      );
                    },
                  ),
                
                // À jour
                if (status != ReadingStatus.caughtUp)
                  Builder(
                    builder: (context) {
                      final l10n = AppLocalizations.of(context);
                      return ListTile(
                        leading: Icon(ReadingStatus.caughtUp.icon, color: ReadingStatus.caughtUp.color),
                        title: Text(ReadingStatus.caughtUp.getLabel(context)),
                        onTap: () {
                          Navigator.of(ctx).pop();
                          context.read<DetailBloc>().add(const UpdateReadingStatus(ReadingStatus.caughtUp));
                          widget.notifier.info("${l10n?.mangaMarkedAs ?? 'Manga marqué comme'} '${ReadingStatus.caughtUp.getLabel(context)}'");
                        },
                      );
                    },
                  ),
                
                // Terminé
                if (status != ReadingStatus.completed)
                  Builder(
                    builder: (context) {
                      final l10n = AppLocalizations.of(context);
                      return ListTile(
                        leading: Icon(ReadingStatus.completed.icon, color: ReadingStatus.completed.color),
                        title: Text(ReadingStatus.completed.getLabel(context)),
                        onTap: () {
                          Navigator.of(ctx).pop();
                          context.read<DetailBloc>().add(const UpdateReadingStatus(ReadingStatus.completed));
                          widget.notifier.info("${l10n?.mangaMarkedAs ?? 'Manga marqué comme'} '${ReadingStatus.completed.getLabel(context)}'");
                        },
                      );
                    },
                  ),
                
                const Divider(height: 1),
                
                // Retirer de la bibliothèque
                Builder(
                  builder: (context) {
                    final l10n = AppLocalizations.of(context);
                    return ListTile(
                      leading: const Icon(Icons.delete_outline, color: Colors.red),
                      title: Text(
                        l10n?.removeFromLibrary ?? 'Retirer de la bibliothèque',
                        style: const TextStyle(color: Colors.red),
                      ),
                      onTap: () {
                        Navigator.of(ctx).pop();
                        context.read<DetailBloc>().add(RemoveFromLibrary(muId));
                        widget.notifier.info(l10n?.mangaRemovedFromLibrary ?? "Manga retiré de la bibliothèque");
                      },
                    );
                  },
                ),
              ],
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

    if (link != null) {
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