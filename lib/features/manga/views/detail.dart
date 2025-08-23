import 'package:auto_size_text/auto_size_text.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:html/parser.dart';
import 'package:mangatracker/core/service_locator/service_locator.dart';
import 'package:mangatracker/features/manga/dto/manga_detail.dto.dart';
import 'package:mangatracker/features/manga/dto/manga_quick_view.dto.dart';
import 'package:mangatracker/features/manga/helpers/image.helper.dart';
import 'package:mangatracker/features/manga/views/late_detail.view.dart';
import 'package:mangatracker/features/manga/views/web_view.dart';
import 'package:mangatracker/features/manga/widgets/manga_type_bubble.dart';

import '../../../core/notifier/notifier.dart';
import '../../library/services/library.service.dart';
import '../../reader/utils/chapter_link_resolver.dart';
import '../dto/manga_recommendation_view.dto.dart';
import '../dto/reading_status.enum.dart';
import '../helpers/chapters.helper.dart';
import '../services/manga.service.dart';
import '../widgets/manga_card.dart';

class _PageData {
  final MangaDetailDto mangaDetail;
  final MangaQuickViewDto? libraryEntry;

  _PageData({required this.mangaDetail, this.libraryEntry});
}

class Detail extends StatefulWidget {
  final String muId;
  final String mangaTitle;
  final String? coverPath;


  const Detail({
    super.key,
    required this.muId,
    required this.mangaTitle,
    this.coverPath,
  });

  @override
  State<Detail> createState() => _DetailState();
}

class _DetailState extends State<Detail> {
  late Future<_PageData> _pageDataFuture;
  final Notifier _notifier = getIt<Notifier>();

  final MangaService _mangaService = getIt<MangaService>();
  final LibraryService _libraryService = getIt<LibraryService>();
  MangaDetailDto? _mangaDetailCache;
  List<MangaRecommendationView>? _mangaRecommendationsCache;
  String? customLink;
  int lastReadChapters = -1;

  @override
  void initState() {
    super.initState();
    _pageDataFuture = _loadPageData();
  }

  Future<_PageData> _loadPageData() async {
    final muId = int.parse(widget.muId);

    final mangaDetailFuture =
    _mangaDetailCache != null
        ? Future.value(_mangaDetailCache)
        : _mangaService.getMangaDetail(widget.muId);

    final libraryEntryFuture = _libraryService.getLibraryEntry(muId);

    final results = await Future.wait([mangaDetailFuture, libraryEntryFuture]);

    _mangaDetailCache = results[0] as MangaDetailDto;
    lastReadChapters = _mangaDetailCache?.readChaptersCount ?? 0;
    return _PageData(
      mangaDetail: _mangaDetailCache!,
      libraryEntry: results[1] as MangaQuickViewDto?,
    );
  }

  void _refreshLibraryState() {
    setState(() {
      _pageDataFuture = _loadPageData();
    });
  }

  Future<void> _saveCustomLink(String link) async {
    final muId = int.parse(widget.muId);
    final success = await _libraryService.updateCustomLink(muId, link);
    if (success) {
      setState(() {
        customLink = link;
      });
      _notifier.success("Lien enregistré !");
    } else {
      _notifier.error("Erreur lors de l'enregistrement du lien.");
    }
  }

  Future<void> _removeCustomLink() async {
    final muId = int.parse(widget.muId);
    final success = await _libraryService.deleteCustomLink(muId);
    if (success) {
      setState(() {
        customLink = null;
      });
      _notifier.success("Lien supprimé !");
    } else {
      _notifier.error("Erreur lors de la suppression du lien.");
    }
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
      ),
      body: SafeArea(
        top: false,
        child: Column(
          children: [
            Expanded(
              child: FutureBuilder<_PageData>(
                future: _pageDataFuture,
                builder: (context, snapshot) {
                  if (snapshot.connectionState != ConnectionState.done) {
                    return const Center(child: CircularProgressIndicator());
                  }
                  if (snapshot.hasError) {
                    return Center(child: Text('Erreur: ${snapshot.error}'));
                  }

                  final manga = snapshot.data!.mangaDetail;
                  final libraryEntry = snapshot.data!.libraryEntry;
                  final readChapters = libraryEntry?.readChapters ?? -1;


                  return Column(
                    children: [
                      Stack(
                        children: [
                          SizedBox(
                            width: double.infinity,
                            height: 340,
                            child: ImageHelper.loadMangaImage(
                              widget.coverPath,
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
                              parse(widget.mangaTitle).documentElement?.text ??
                                  '',
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
                                  children:
                                      manga.genres!
                                          .map(
                                            (g) => Padding(
                                              padding: const EdgeInsets.only(
                                                right: 8,
                                              ),
                                              child: MangaType(type: g),
                                            ),
                                          )
                                          .toList(),
                                ),
                              ),
                            ),
                        ],
                      ),
                      Expanded(
                        child: LateDetailView(
                          muId: widget.muId,
                          mangaTitle: manga.title,
                          mangaDescription: manga.description,
                          rating: manga.rating,
                          mangaChapters: ChaptersHelper.buildChapterList(
                            manga.totalChapters,
                          ),
                          mangaTotalChapters: manga.totalChapters,
                          isCompleted: manga.isCompleted,
                          authors: manga.authors,
                          year: manga.year,
                          readChapters: readChapters,
                          onReadCountChanged: (newCount) {
                            _refreshLibraryState();
                          },
                        ),
                      ),
                      _buildBottomActionBar(libraryEntry?.readingStatus),
                    ],
                  );
                },
              ),
            ),

            // BARRE DE BOUTONS FIXE EN BAS
          ],
        ),
      ),
    );
  }

  Widget _buildBottomActionBar(ReadingStatus? status) {
    final muId = int.parse(widget.muId);
    final customLink = _mangaDetailCache?.customLink;

    final buttonShape = RoundedRectangleBorder(
      borderRadius: BorderRadius.circular(15),
    );

    if (status == null) {
      return Container(
        height: 70,
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8.0),
        child: Row(
          children: [
            // Gros bouton "Ajouter à 'À lire plus tard'"
            Expanded(
              child: SizedBox(
                width: double.infinity,
                height: double.infinity,
                child: ElevatedButton.icon(
                  icon: const Icon(Icons.bookmark_add_outlined),
                  label: const Text('Ajouter à "À lire plus tard"'),
                  onPressed: () async {
                    final success = await _libraryService.addMangaToLibrary(muId);
                    if (success) _refreshLibraryState();
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
            // Icône recommandations compact
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
          // Le bouton principal
          Positioned.fill(
            child: ElevatedButton.icon(
              style: ElevatedButton.styleFrom(
                backgroundColor: Theme.of(context).colorScheme.primary,
                foregroundColor: Theme.of(context).colorScheme.onPrimary,
                shape: buttonShape,
              ),onPressed: () async {
              final muId = int.parse(widget.muId);
              final lastRead = lastReadChapters;      // ex. 119
              final baseLink = customLink;                              // lien enregistré par l’utilisateur
              final targetUrl = ChapterLinkResolver.buildUrlForChapter(
                  baseLink, lastRead + 1) ?? baseLink;                 // vise le chapitre suivant si possible

              Navigator.of(context).push(
                MaterialPageRoute(
                  builder: (_) => ReaderWebView(
                    muId: muId,
                    initialLastRead: lastRead,
                    initialUrl: targetUrl,
                    baseUserLink: baseLink, // pour calculer les "next" robustement
                  ),
                ),
              );
            },
              icon: const Icon(Icons.link),
              label: const Padding(
                padding: EdgeInsets.only(right: 24),
                // Décale le texte vers la gauche
                child: Text('Lire en ligne', style: TextStyle(fontSize: 17)),
              ),
            ),
          ),

          // Les trois petits points bien alignés à droite
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

  void _showManageLibrarySheet(ReadingStatus status) {
    final muId = int.parse(widget.muId);
    showModalBottomSheet(
      context: context,
      builder: (ctx) {
        return SafeArea(
          child: Wrap(
            children: <Widget>[
              if (status == ReadingStatus.reading)
                ListTile(
                  leading: const Icon(Icons.bookmark_outline),
                  title: const Text("Passer à 'À lire plus tard'"),
                  onTap: () async {
                    Navigator.of(ctx).pop();
                    final success = await _libraryService.updateMangaStatus(
                      muId,
                      ReadingStatus.readLater,
                    );
                    if (success) {
                      _notifier.info("Manga passé à 'À lire plus tard'.");
                      _refreshLibraryState();
                    } else {
                      _notifier.error("Erreur lors du changement de statut.");
                    }
                  },
                ),
              ListTile(
                leading: const Icon(Icons.delete_outline, color: Colors.red),
                title: const Text(
                  'Retirer de la bibliothèque',
                  style: TextStyle(color: Colors.red),
                ),
                onTap: () async {
                  Navigator.of(ctx).pop();
                  final success = await _libraryService.removeMangaFromLibrary(
                    muId,
                  );
                  if (success) {
                    _notifier.info("Manga retiré de la bibliothèque");
                    _refreshLibraryState();
                  } else {
                    _notifier.error("Erreur lors du retrait du manga.");
                  }
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
      builder:
          (ctx) => AlertDialog(
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
                  final isValid =
                      uri != null &&
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
                        mangaAuthor: manga.year,
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

}
