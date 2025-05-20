import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:html/parser.dart';

import '../../../core/service_locator/service_locator.dart';
import '../../library/services/library.service.dart';
import '../dto/author.dto.dart';
import 'row_chapter.dart';

class LateDetailView extends StatefulWidget {
  final String muId;
  final String mangaTitle;
  final String mangaDescription;
  final String rating;
  final List mangaChapters;
  final num? mangaTotalChapters;
  final bool? isCompleted;
  final List<AuthorDto>? authors;
  final String year;
  final num readChapters;

  const LateDetailView({
    super.key,
    required this.muId,
    required this.mangaTitle,
    required this.mangaDescription,
    required this.rating,
    required this.mangaChapters,
    this.mangaTotalChapters,
    this.isCompleted,
    this.authors,
    required this.year,
    required this.readChapters,
  });

  @override
  State<LateDetailView> createState() => _LateDetailViewState();
}

class _LateDetailViewState extends State<LateDetailView> {
  bool _isExpanded = false;
  num? _currentReadCount;
  final LibraryService _libraryService =
      getIt<LibraryService>(); // Obtenir l'instance du service
  @override
  void initState() {
    super.initState();
    _currentReadCount = widget.readChapters;
  }

  @override
  Widget build(BuildContext context) {
    final synopsisText =
        parse(widget.mangaDescription).documentElement!.text.trim();

    // Séparer auteurs / artistes
    final authors =
        widget.authors
            ?.where((a) => a.type.toLowerCase() == 'author')
            .map((a) => a.name)
            .toList() ??
        [];
    final artists =
        widget.authors
            ?.where((a) => a.type.toLowerCase() == 'artist')
            .map((a) => a.name)
            .toList() ??
        [];

    Future<void> _handleAddToLibrary(String mangaId) async {
      print('UI: Tentative d\'ajout du manga ID: $mangaId à la bibliothèque');
      bool success = await _libraryService.addMangaToLibrary(mangaId);
      if (success && mounted) {
        setState(() {
          _currentReadCount = 0;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('${widget.mangaTitle} ajouté à la bibliothèque !'),
          ),
        );
      } else if (mounted) {
        print(success);
        print(mounted) ;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Erreur lors de l\'ajout à la bibliothèque.')),
        );
      }
    }

    Future<void> _handleSaveChapter(String mangaId, num chapterNumber) async {
      print(
        'UI: Tentative de sauvegarde du chapitre $chapterNumber pour le manga ID: $mangaId',
      );

      if (_currentReadCount! < 0) {
        await _handleAddToLibrary(mangaId);
      }

      bool success = await _libraryService.saveChapterProgress(mangaId, chapterNumber);
      if (success && mounted) {
        setState(() => _currentReadCount = chapterNumber.toInt());
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text('Chapitre $chapterNumber marqué comme lu !')));
      } else if (mounted) {
        ScaffoldMessenger.of(context)
            .showSnackBar(const SnackBar(content: Text('Erreur lors de la sauvegarde du chapitre.')));
      }
    }

    final total = widget.mangaTotalChapters?.toInt() ?? 0;
    final chapNumbers = List<int>.generate(total, (i) => i + 1)
      ..sort((a, b) => b.compareTo(a)); // tri décroissant

    return Scrollbar(
      thumbVisibility: true,
      child: SingleChildScrollView(
        padding: const EdgeInsets.only(bottom: 16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Titres, chapitres & note
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 8),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  Text(
                    '${widget.mangaTotalChapters ?? 0} Chapitres',
                    style: const TextStyle(
                      fontSize: 15,
                      color: Colors.grey,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  Wrap(
                    children: [
                      const Icon(Icons.star, color: Colors.orange, size: 30),
                      Text(
                        widget.rating,
                        style: GoogleFonts.poppins(
                          textStyle: const TextStyle(fontSize: 20),
                          fontWeight: FontWeight.bold,
                          color: Color.fromARGB(255, 138, 40, 31),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),

            // Statut & Année sur la même ligne
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  Flexible(
                    flex: 1,
                    child: Text(
                      'Statut : ${widget.isCompleted == true ? "Terminé" : "En cours"}',
                      textAlign: TextAlign.center,
                      style: const TextStyle(fontWeight: FontWeight.w500),
                    ),
                  ),
                  Flexible(
                    flex: 1,
                    child: Text(
                      'Année : ${widget.year}',
                      textAlign: TextAlign.center,
                      style: const TextStyle(fontWeight: FontWeight.w500),
                    ),
                  ),
                ],
              ),
            ),

            // Auteur & Artiste sur la même ligne
            if (authors.isNotEmpty || artists.isNotEmpty)
              Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 4,
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    if (authors.isNotEmpty)
                      Flexible(
                        flex: 1,
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.center,
                          children: [
                            const Text(
                              'Auteur :',
                              style: TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            ...authors.map(
                              (n) => Text(n, textAlign: TextAlign.center),
                            ),
                          ],
                        ),
                      ),
                    if (artists.isNotEmpty)
                      Flexible(
                        flex: 1,
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.center,
                          children: [
                            const Text(
                              'Artiste :',
                              style: TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            ...artists.map(
                              (n) => Text(n, textAlign: TextAlign.center),
                            ),
                          ],
                        ),
                      ),
                  ],
                ),
              ),

            const SizedBox(height: 8),

            // SYNOPSIS avec Voir plus / Voir moins
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Text(
                'Synopsis',
                style: GoogleFonts.poppins(
                  textStyle: const TextStyle(fontSize: 18),
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
              child: AnimatedCrossFade(
                firstChild: Text(
                  synopsisText,
                  maxLines: 3,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    fontSize: 13,
                    color: Colors.grey,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                secondChild: Text(
                  synopsisText,
                  style: const TextStyle(
                    fontSize: 13,
                    color: Colors.grey,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                crossFadeState:
                    _isExpanded
                        ? CrossFadeState.showSecond
                        : CrossFadeState.showFirst,
                duration: const Duration(milliseconds: 200),
              ),
            ),
            Padding(
              padding: const EdgeInsets.only(left: 16),
              child: TextButton.icon(
                onPressed: () => setState(() => _isExpanded = !_isExpanded),
                icon: Icon(_isExpanded ? Icons.expand_less : Icons.expand_more),
                label: Text(_isExpanded ? 'Voir moins' : 'Voir plus'),
                style: TextButton.styleFrom(
                  foregroundColor: Colors.pinkAccent,
                  padding: EdgeInsets.zero,
                  alignment: Alignment.centerLeft,
                ),
              ),
            ),

            const SizedBox(height: 8),

            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    '$total chapitres',
                    style: GoogleFonts.poppins(
                      textStyle: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                  const SizedBox(height: 10),
                  Column(
                    children:
                        chapNumbers.map((chapNum) {
                          final line = chapNum.toString().padLeft(2, '0');
                          final isRead = chapNum <= widget.readChapters;

                          return GestureDetector(
                            onTap: () async {
                                await _handleSaveChapter(widget.muId, chapNum);
                            },
                            child: RowChapter(
                              line: line,
                              chapter: chapNum.toString(),
                              read: isRead,
                            ),
                          );
                        }).toList(),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
