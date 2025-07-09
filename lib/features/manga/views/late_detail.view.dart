import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../core/notifier/notifier.dart';
import '../../../core/service_locator/service_locator.dart';
import '../../library/services/library.service.dart';
import '../dto/author.dto.dart';
import 'row_chapter.dart';
import 'package:flutter_markdown/flutter_markdown.dart';
import 'package:url_launcher/url_launcher.dart';

class LateDetailView extends StatefulWidget {
  final String muId;
  final String mangaTitle;
  final String? mangaDescription;
  final String rating;
  final List mangaChapters;
  final num? mangaTotalChapters;
  final bool? isCompleted;
  final List<AuthorDto>? authors;
  final String year;
  final num readChapters;
  final Function(num)? onReadCountChanged;

  const LateDetailView({
    super.key,
    required this.muId,
    required this.mangaTitle,
    this.mangaDescription,
    required this.rating,
    required this.mangaChapters,
    this.mangaTotalChapters,
    this.isCompleted,
    this.authors,
    required this.year,
    required this.readChapters,
    this.onReadCountChanged,
  });

  @override
  State<LateDetailView> createState() => _LateDetailViewState();
}

class _LateDetailViewState extends State<LateDetailView> {
  bool _isExpanded = false;
  num? _currentReadCount;
  bool _isSaving = false;
  final LibraryService _libraryService = getIt<LibraryService>();
  final Notifier _notifier = getIt<Notifier>();

  @override
  void initState() {
    super.initState();
    _currentReadCount = widget.readChapters;
  }


  @override
  Widget build(BuildContext context) {


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

    Future<void> handleAddToLibrary(String mangaId) async {
      bool success = await _libraryService.addMangaToLibrary(int.parse(mangaId));
      if (success && mounted) {
        setState(() {
          _currentReadCount = 0;
        });
        _notifier.success('${widget.mangaTitle} a été ajouté à la bibliothèque !');
      } else if (mounted) { // Ajout du else if
        _notifier.error('Erreur lors de l\'ajout à la bibliothèque.');
      }
    }

    Future<void> handleSaveChapter(String mangaId, num chapterNumber) async {
      if (_isSaving) return;
      setState(() => _isSaving = true);

      if (_currentReadCount! < 0) {
        await handleAddToLibrary(mangaId);
      }

      int newCount;
      bool success;
      if (_currentReadCount! >= chapterNumber) {
        newCount = chapterNumber.toInt() - 1;
        if (newCount == 0) {
          success =
          await _libraryService.removeMangaFromLibrary(int.parse(mangaId));

        } else {
          success = await _libraryService.saveChapterProgress(
              int.parse(mangaId), newCount);
        }
      } else {
        newCount = chapterNumber.toInt();
        success =
        await _libraryService.saveChapterProgress(int.parse(mangaId), newCount);
      }

      if (!success && mounted) {
        setState(() => _isSaving = false);
        _notifier.error('Erreur lors de la mise à jour du chapitre.');
        return;
      }

      if (mounted) {
        setState(() {
          _currentReadCount = (newCount == 0) ? -1 : newCount;
          _isSaving = false;
        });

        final message = newCount == 0
            ? 'Manga retiré de la bibliothèque'
            : 'Chapitre $chapterNumber ${_currentReadCount! >= chapterNumber
            ? 'lu'
            : 'non lu'}';

        _notifier.info(message);
        if (widget.onReadCountChanged != null) {
          widget.onReadCountChanged!(_currentReadCount!);
        }
      }
    }

    Future<void> handleLinkTap(String url) async {
      final uri = Uri.parse(url);
      if (await canLaunchUrl(uri)) {
        await launchUrl(uri, mode: LaunchMode.externalApplication);
      } else {
        _notifier.error("Impossible d'ouvrir le lien : $url");
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
                      Icon(Icons.star, color: Theme
                          .of(context)
                          .colorScheme
                          .primary, size: 25),
                      Text(
                        widget.rating,
                        style: GoogleFonts.poppins(
                          textStyle: const TextStyle(fontSize: 20),
                          fontWeight: FontWeight.bold,
                          color: Theme
                              .of(context)
                              .colorScheme
                              .primary,
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
                      'Statut : ${widget.isCompleted == true
                          ? "Terminé"
                          : "En cours"}',
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
            if (widget.mangaDescription != null && widget.mangaDescription!.isNotEmpty)
              ...[
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
                  child: AnimatedContainer(
                    constraints: BoxConstraints(
                      maxHeight: _isExpanded ? 1000 : 70.0,
                    ),
                    duration: const Duration(milliseconds: 300),
                    curve: Curves.easeInOut,

                    child: SingleChildScrollView(

                      physics: const NeverScrollableScrollPhysics(),
                      child: MarkdownBody(
                        data: widget.mangaDescription!,
                        onTapLink: (text, href, title) {
                          if (href != null) handleLinkTap(href);
                        },
                        styleSheet: MarkdownStyleSheet(
                          p: const TextStyle(
                            fontSize: 13,
                            color: Colors.grey,
                          ),
                          strong: const TextStyle(
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
                // Le bouton "Voir plus / Voir moins" ne change pas
                Padding(
                  padding: const EdgeInsets.only(left: 16),
                  child: TextButton.icon(
                    onPressed: () => setState(() => _isExpanded = !_isExpanded),
                    icon: Icon(_isExpanded ? Icons.expand_less : Icons.expand_more),
                    label: Text(_isExpanded ? 'Voir moins' : 'Voir plus'),
                    style: TextButton.styleFrom(
                      foregroundColor: Theme.of(context).colorScheme.primary,
                      padding: EdgeInsets.zero,
                      alignment: Alignment.centerLeft,
                    ),
                  ),
                ),
              ],
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
                    children: chapNumbers.map((chapNum) {
                      final line = chapNum.toString().padLeft(2, '0');
                      final isRead = chapNum <= _currentReadCount!;

                      return Padding(
                        padding: const EdgeInsets.symmetric(vertical: 4),
                        child: Material(
                          color: Colors.white, // couleur de fond de la ligne
                          borderRadius: BorderRadius.circular(12),
                          child: InkWell(
                            borderRadius: BorderRadius.circular(12),
                            onTap: _isSaving
                                ? null
                                : () => handleSaveChapter(widget.muId, chapNum),
                            child: AnimatedScale(
                              scale: _isSaving ? 1.0 : 1.0,
                              duration: const Duration(milliseconds: 100),
                              child: RowChapter(
                                line: line,
                                chapter: chapNum.toString(),
                                read: isRead,
                              ),
                            ),
                          ),
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
