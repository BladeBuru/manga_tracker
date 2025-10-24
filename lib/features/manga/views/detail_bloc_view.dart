import 'package:auto_size_text/auto_size_text.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:html/parser.dart';
import 'package:mangatracker/core/service_locator/service_locator.dart';
import 'package:mangatracker/features/manga/bloc/detail_bloc.dart';
import 'package:mangatracker/features/manga/bloc/detail_event.dart';
import 'package:mangatracker/features/manga/bloc/detail_state.dart';
import 'package:mangatracker/features/manga/dto/reading_status.enum.dart';
import 'package:mangatracker/features/manga/helpers/chapters.helper.dart';
import 'package:mangatracker/features/manga/helpers/image.helper.dart';
import 'package:mangatracker/features/manga/views/late_detail.view.dart';
import 'package:mangatracker/features/manga/views/web_view.dart';
import 'package:mangatracker/features/manga/widgets/manga_card.dart';
import 'package:mangatracker/features/manga/widgets/manga_type_bubble.dart';
import 'package:mangatracker/features/manga/services/manga.service.dart';
import 'package:mangatracker/core/notifier/notifier.dart';
import '../../library/services/library.service.dart';
import '../../reader/utils/chapter_link_resolver.dart';
import '../dto/manga_recommendation_view.dto.dart';
import '../../auth/views/login.view.dart';

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
  final DetailBloc _detailBloc = getIt<DetailBloc>();
  final MangaService _mangaService = getIt<MangaService>();
  final Notifier _notifier = getIt<Notifier>();
  
  List<MangaRecommendationView>? _mangaRecommendationsCache;
  String? customLink;
  int lastReadChapters = -1;

  @override
  void initState() {
    super.initState();
    print('📖 DetailBlocView initialisée pour manga ${widget.muId} - Utilisation du BLoC !');
    _detailBloc.add(LoadMangaDetail(widget.muId));
  }

  void _redirectToLoginPage() {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => const LoginView()),
    );
  }

  void _refreshLibraryState() {
    _detailBloc.add(const RefreshMangaDetail());
  }

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
            bloc: _detailBloc,
            builder: (context, state) {
              final isOffline = state is DetailLoaded && state.isOffline ||
                               state is DetailError && state.isOffline;
              
              if (!isOffline) return const SizedBox.shrink();
              
              return Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                margin: const EdgeInsets.only(right: 8),
                decoration: BoxDecoration(
                  color: Colors.orange,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.cloud_off, size: 16, color: Colors.white),
                    SizedBox(width: 4),
                    Text('Hors ligne', style: TextStyle(color: Colors.white, fontSize: 12)),
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
          bloc: _detailBloc,
          listener: (context, state) {
            if (state is DetailError) {
              if (state.message.contains('InvalidCredentials') || 
                  state.message.contains('Expired session')) {
                _redirectToLoginPage();
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
                    Text(
                      state.isOffline 
                          ? 'Mode hors ligne - Aucune donnée en cache'
                          : 'Erreur: ${state.message}',
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 16),
                    ElevatedButton(
                      onPressed: () => _detailBloc.add(LoadMangaDetail(widget.muId)),
                      child: const Text('Réessayer'),
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
              Stack(
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
                    child: AutoSizeText(
                      parse(widget.mangaTitle ?? manga.title).documentElement?.text ?? '',
                      textAlign: TextAlign.center,
                      maxLines: 2,
                      style: GoogleFonts.poppins(
                        fontSize: 28,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                  ),
                  if (manga.genres != null)
                    Positioned(
                      bottom: 14,
                      left: 16,
                      right: 14,
                      child: SizedBox(
                        height: 24,
                        child: ListView(
                          scrollDirection: Axis.horizontal,
                          children: manga.genres!
                              .map((g) => Padding(
                                    padding: const EdgeInsets.only(right: 8),
                                    child: MangaType(type: g),
                                  ))
                              .toList(),
                        ),
                      ),
                    ),
                ],
              ),
              // Détails du manga (LateDetailView)
              Expanded(
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
                  onReadCountChanged: (newCount) {
                    // Dispatcher l'événement au BLoC pour mise à jour réactive
                    _detailBloc.add(SaveChapterProgress(widget.muId, newCount.toInt()));
                  },
                  onAddToLibrary: () {
                    // Dispatcher l'événement au BLoC
                    _detailBloc.add(AddToLibrary(widget.muId));
                  },
                  onRemoveFromLibrary: () {
                    // Dispatcher l'événement au BLoC
                    _detailBloc.add(RemoveFromLibrary(widget.muId));
                  },
                ),
              ),
              // Barre d'action en bas
              _buildBottomActionBar(status),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildBottomActionBar(ReadingStatus? status) {
    final muId = widget.muId;
    final buttonShape = RoundedRectangleBorder(
      borderRadius: BorderRadius.circular(15),
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
                  label: const Text('Ajouter à "À lire plus tard"'),
                  onPressed: () {
                    _detailBloc.add(AddToLibrary(muId));
                    _notifier.info("Manga ajouté à 'À lire plus tard'");
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
        label: const Text('Ajouter un lien', style: TextStyle(fontSize: 17)),
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
                final baseLink = customLink ?? '';
                final targetUrl = ChapterLinkResolver.buildUrlForChapter(
                        baseLink, lastRead + 1) ?? baseLink;

                await Navigator.of(context).push(
                  MaterialPageRoute(
                    builder: (_) => ReaderWebView(
                      muId: muId,
                      initialLastRead: lastRead,
                      initialUrl: targetUrl ?? '',
                      baseUserLink: baseLink,
                    ),
                  ),
                );
                if (mounted) _refreshLibraryState();
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
                tooltip: 'Gérer le lien',
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
        message: 'Recommandations',
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
            _mangaRecommendationsCache ??=
                await _mangaService.getMangaRecommendations(muId.toString());
            if (!mounted) return;

            showDialog(
              context: context,
              builder: (_) => AlertDialog(
                title: const Text('Mangas recommandés'),
                content: SizedBox(
                  width: MediaQuery.of(context).size.width * 0.8,
                  height: 200,
                  child: (_mangaRecommendationsCache?.isEmpty ?? true)
                      ? const Center(
                          child: Text('Aucune recommandation disponible.',
                              textAlign: TextAlign.center),
                        )
                      : ListView.builder(
                          scrollDirection: Axis.horizontal,
                          itemCount: _mangaRecommendationsCache!.length,
                          itemBuilder: (_, index) {
                            final manga = _mangaRecommendationsCache![index];
                            return MangaCard(
                          muId: manga.muId.toString(),
                          mangaTitle: manga.title,
                          mangaAuthor: manga.year.toString(),
                          mediumImgPath: manga.mediumCoverUrl,
                          rating: manga.rating,
                            );
                          },
                        ),
                ),
                actions: [
                  TextButton(
                    child: const Text('Fermer'),
                    onPressed: () => Navigator.of(context).pop(),
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
    showModalBottomSheet(
      context: context,
      builder: (ctx) {
        return SafeArea(
          child: Wrap(
            children: <Widget>[
              // Titre de la section
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                child: Text(
                  'Changer le statut',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              const Divider(height: 1),
              
              // En cours
              if (status != ReadingStatus.reading)
                ListTile(
                  leading: Icon(ReadingStatus.reading.icon, color: ReadingStatus.reading.color),
                  title: Text(ReadingStatus.reading.label),
                  onTap: () {
                    Navigator.of(ctx).pop();
                    _detailBloc.add(const UpdateReadingStatus(ReadingStatus.reading));
                    _notifier.info("Manga marqué comme '${ReadingStatus.reading.label}'");
                  },
                ),
              
              // À lire plus tard
              if (status != ReadingStatus.readLater)
                ListTile(
                  leading: Icon(ReadingStatus.readLater.icon, color: ReadingStatus.readLater.color),
                  title: Text(ReadingStatus.readLater.label),
                  onTap: () {
                    Navigator.of(ctx).pop();
                    _detailBloc.add(const UpdateReadingStatus(ReadingStatus.readLater));
                    _notifier.info("Manga marqué comme '${ReadingStatus.readLater.label}'");
                  },
                ),
              
              // À jour
              if (status != ReadingStatus.caughtUp)
                ListTile(
                  leading: Icon(ReadingStatus.caughtUp.icon, color: ReadingStatus.caughtUp.color),
                  title: Text(ReadingStatus.caughtUp.label),
                  onTap: () {
                    Navigator.of(ctx).pop();
                    _detailBloc.add(const UpdateReadingStatus(ReadingStatus.caughtUp));
                    _notifier.info("Manga marqué comme '${ReadingStatus.caughtUp.label}'");
                  },
                ),
              
              // Terminé
              if (status != ReadingStatus.completed)
                ListTile(
                  leading: Icon(ReadingStatus.completed.icon, color: ReadingStatus.completed.color),
                  title: Text(ReadingStatus.completed.label),
                  onTap: () {
                    Navigator.of(ctx).pop();
                    _detailBloc.add(const UpdateReadingStatus(ReadingStatus.completed));
                    _notifier.info("Manga marqué comme '${ReadingStatus.completed.label}'");
                  },
                ),
              
              const Divider(height: 1),
              
              // Retirer de la bibliothèque
              ListTile(
                leading: const Icon(Icons.delete_outline, color: Colors.red),
                title: const Text(
                  'Retirer de la bibliothèque',
                  style: TextStyle(color: Colors.red),
                ),
                onTap: () {
                  Navigator.of(ctx).pop();
                  _detailBloc.add(RemoveFromLibrary(muId));
                  _notifier.info("Manga retiré de la bibliothèque");
                },
              ),
            ],
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
                title: const Text("Modifier le lien"),
                onTap: () {
                  Navigator.of(ctx).pop();
                  _addCustomLink();
                },
              ),
              ListTile(
                leading: const Icon(Icons.delete_outline, color: Colors.red),
                title: const Text(
                  "Supprimer le lien",
                  style: TextStyle(color: Colors.red),
                ),
                onTap: () {
                  Navigator.of(ctx).pop();
                  _removeCustomLink();
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
    final link = await showDialog<String?>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Ajouter ou modifier un lien'),
        content: TextField(
          controller: controller,
          decoration: const InputDecoration(
            hintText: 'https://exemple.com',
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(null),
            child: Text(
              'Annuler',
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
                _notifier.error(
                  "Lien invalide. Le lien doit commencer par http:// ou https://",
                );
              }
            },
            child: const Text('Valider'),
          ),
        ],
      ),
    );

    if (link != null) {
      await _saveCustomLink(link);
    }
  }

  Future<void> _saveCustomLink(String link) async {
    _detailBloc.add(UpdateCustomLink(link));
    _notifier.success("Lien enregistré !");
  }

  Future<void> _removeCustomLink() async {
    _detailBloc.add(DeleteCustomLink());
    _notifier.success("Lien supprimé !");
  }
}