import 'package:auto_size_text/auto_size_text.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:html/parser.dart';
import 'package:mangatracker/core/service_locator/service_locator.dart';
import 'package:mangatracker/features/manga/dto/manga_detail.dto.dart';
import 'package:mangatracker/features/manga/dto/manga_quick_view.dto.dart';
import 'package:mangatracker/features/manga/helpers/image.helper.dart';
import 'package:mangatracker/features/manga/views/late_detail.view.dart';
import 'package:mangatracker/features/manga/widgets/manga_type_bubble.dart';

import '../../../core/notifier/notifier.dart';
import '../../library/services/library.service.dart';
import '../dto/reading_status.enum.dart';
import '../helpers/chapters.helper.dart';
import '../services/manga.service.dart';


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


  @override
  void initState() {
    super.initState();
    _pageDataFuture = _loadPageData();
  }

  Future<_PageData> _loadPageData() async {
    final muId = int.parse(widget.muId);

    final mangaDetailFuture = _mangaDetailCache != null
        ? Future.value(_mangaDetailCache)
        : _mangaService.getMangaDetail(widget.muId);

    final libraryEntryFuture = _libraryService.getLibraryEntry(muId);

    final results = await Future.wait([mangaDetailFuture, libraryEntryFuture]);


    _mangaDetailCache = results[0] as MangaDetailDto;

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
                              parse(widget.mangaTitle).documentElement?.text ?? '',
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

    Widget leftButton;

    if (status == null) {
      leftButton = ElevatedButton.icon(
        icon: const Icon(Icons.bookmark_add_outlined),
        label: const Text('Ajouter à "À lire plus tard"'),
        onPressed: () async {
          final success = await _libraryService.addMangaToLibrary(muId);
          if (success) _refreshLibraryState(); // APPEL CORRIGÉ
        },
        style: ElevatedButton.styleFrom(
            padding: const EdgeInsets.symmetric(vertical: 12)),
      );
      return Container(
          padding: const EdgeInsets.all(16),
          width: double.infinity,
          child: leftButton);
    } else {
      leftButton = ElevatedButton(
        style: ElevatedButton.styleFrom(
          backgroundColor: status.color.withValues(alpha: 0.2),
          foregroundColor: status.color,
          elevation: 0,
          shape:
          RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
        ),
        onPressed: () => _showManageLibrarySheet(status),
        child: Icon(status.icon),
      );
    }

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
                child: leftButton),
          ),
          const SizedBox(width: 15),
          Flexible(
            flex: 5,
            child: ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: Theme.of(context).colorScheme.primary,
                foregroundColor: Theme.of(context).colorScheme.onPrimary,
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(15)),
              ),
              onPressed: () { /* TODO: Naviguer vers la lecture */ },
              child: const Text('Commencer la lecture', style: TextStyle(fontSize: 17)),
            ),
          ),
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
                        muId, ReadingStatus.readLater);
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
                title: const Text('Retirer de la bibliothèque',
                    style: TextStyle(color: Colors.red)),
                onTap: () async {
                  Navigator.of(ctx).pop();
                  final success =
                  await _libraryService.removeMangaFromLibrary(muId);
                  if (success){
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


}
