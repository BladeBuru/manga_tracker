import 'package:html/parser.dart';
import 'package:mangatracker/core/service_locator/service_locator.dart';
import 'package:mangatracker/features/manga/dto/manga_detail.dto.dart';
import 'package:mangatracker/features/manga/helpers/chapters.helper.dart';
import 'package:mangatracker/features/manga/helpers/image.helper.dart';
import 'package:mangatracker/features/manga/views/late_detail.view.dart';
import 'package:mangatracker/features/manga/widgets/manga_type_bubble.dart';
import 'package:mangatracker/main.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../library/services/library.service.dart';
import '../services/manga.service.dart';

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

bool isFavorite = true;

Widget iconFavorite = Icon(
  color: isFavorite == true ? Colors.grey : Colors.orange,
  Icons.star,
);

class _DetailState extends State<Detail> {
  get image => null;
  late Future<MangaDetailDto> mangaDetail;
  late Future<num> readChapter;
  final MangaService _mangaService = getIt<MangaService>();
  final LibraryService _libraryService = getIt<LibraryService>();

  @override
  void initState() {
    super.initState();
    mangaDetail = _mangaService.getMangaDetail(widget.muId);
    readChapter = _libraryService.getReadChapterByUid(int.parse(widget.muId));
  }

  /*Future<void> _handleToggleReadLater() async {
    final id = widget.muId;
    bool success;

    if (!_isReadLater) {
      // on ajoute « À lire plus tard »
      success = await _readLater.addToReadLater(id);
    } else {
      // on retire de la liste readLater
      success = await _readLater.removeFromReadLater(id);
    }

    if (!success && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Erreur sur la liste À lire plus tard.')),
      );
      return;
    }

    setState(() => _isReadLater = !_isReadLater);
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            _isReadLater
                ? 'Ajouté à « À lire plus tard »'
                : 'Retiré de « À lire plus tard »',
          ),
        ),
      );
    }
  }*/

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
              child: FutureBuilder<MangaDetailDto>(
                future: mangaDetail,
                builder: (context, snapshot) {
                  if (snapshot.connectionState != ConnectionState.done) {
                    return const Center(child: CircularProgressIndicator());
                  }
                  if (snapshot.hasError) {
                    return Center(child: Text('Error: \${snapshot.error}'));
                  }
                  final manga = snapshot.data!;
                  return Column(
                    children: [
                      // HEADER FIXE AVEC FULL COVER
                      Stack(
                        children: [
                          // Cover full-width
                          SizedBox(
                            width: double.infinity,
                            height: 340,
                            child: ImageHelper.loadMangaImage(
                              widget.coverPath,
                              fit: BoxFit.cover,
                            ),
                          ),
                          // Surcouche sombre
                          Container(
                            width: double.infinity,
                            height: 340,
                            color: Colors.black.withValues(alpha: 0.4),
                          ),

                          // Titre centré
                          Positioned(
                            top: 70,
                            left: 16,
                            right: 16,
                            child: Text(
                              parse(widget.mangaTitle).documentElement!.text,
                              textAlign: TextAlign.center,
                              style: GoogleFonts.poppins(
                                fontSize: 28,
                                fontWeight: FontWeight.bold,
                                color: Colors.white,
                              ),
                            ),
                          ),
                          // Genres en bas
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
                      FutureBuilder<num>(
                        future: readChapter,
                        builder: (ctx2, snap2) {
                          if (snap2.connectionState != ConnectionState.done) {
                            return const Center(
                              child: CircularProgressIndicator(),
                            );
                          }
                          if (snap2.hasError) {
                            final err = snap2.error;
                            return Center(child: Text('Erreur lecture: $err'));
                          }
                          final readChapter = snap2.data!;
                          // DÉTAIL DÉFILABLE
                          return Expanded(
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
                              readChapters: readChapter,
                            ),
                          );
                        },
                      ),
                    ],
                  );
                },
              ),
            ),
            // BARRE DE BOUTONS FIXE EN BAS
            Container(
              height: 70,
              decoration: BoxDecoration(
                color: Colors.white,
                boxShadow: [
                  BoxShadow(
                    color: Colors.grey.shade100,
                    spreadRadius: 2,
                    blurRadius: 5,
                    offset: const Offset(0, -3),
                  ),
                ],
              ),
              child: FractionallySizedBox(
                heightFactor: 0.9,
                child: Row(
                  children: [
                    // Bouton 1 => ratio 3 sur total 8, maxWidth = 150
                    const SizedBox(width: 10),
                    Flexible(
                      flex: 3,
                      fit: FlexFit.loose,
                      child: ConstrainedBox(
                        constraints: const BoxConstraints(maxWidth: 150),
                        child: SizedBox(
                          width: double.infinity,
                          height: double.infinity,
                          child: ElevatedButton(
                            style: ButtonStyle(
                              backgroundColor: WidgetStateProperty.all<Color>(
                                const Color.fromRGBO(255, 235, 240, 50),
                              ),
                              shape: WidgetStateProperty.all<OutlinedBorder>(
                                RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(15),
                                ),
                              ),
                            ),
                            onPressed: () {
                              /* … */
                            },
                            child: iconFavorite,
                          ),
                        ),
                      ),
                    ),

                    const SizedBox(width: 15), // espace entre boutons
                    // Bouton 2 => ratio 5 sur total 8, maxWidth = 350
                    Flexible(
                      flex: 5,
                      fit: FlexFit.loose,
                      child: ConstrainedBox(
                        constraints: const BoxConstraints(maxWidth: 300),
                        child: SizedBox(
                          width: double.infinity,
                          height: double.infinity,
                          child: ElevatedButton(
                            style: ButtonStyle(
                              backgroundColor: WidgetStateProperty.all<Color>(
                                themePage,
                              ),
                              shape: WidgetStateProperty.all<OutlinedBorder>(
                                RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(15),
                                ),
                              ),
                            ),
                            onPressed: () {
                              /* … */
                            },
                            child: const Text(
                              'Lire plus tard',
                              style: TextStyle(fontSize: 17,color: Colors.white),
                            ),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  loadIconFavorite() {
    if (isFavorite) {
      iconFavorite = const Icon(color: Colors.orange, Icons.star);
    } else {
      iconFavorite = const Icon(color: Colors.grey, Icons.star);
    }
  }
}
