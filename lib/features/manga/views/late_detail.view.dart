import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:html/parser.dart';

import '../dto/author.dto.dart';
import 'row_chapter.dart';

class LateDetailView extends StatefulWidget {
  final String mangaTitle;
  final String mangaDescription;
  final String rating;
  final List mangaChapters;
  final num? mangaTotalChapters;
  final bool? isCompleted;
  final List<AuthorDto>? authors;
  final String year;

  const LateDetailView({
    super.key,
    required this.mangaTitle,
    required this.mangaDescription,
    required this.rating,
    required this.mangaChapters,
    this.mangaTotalChapters,
    this.isCompleted,
    this.authors,
    required this.year,
  });

  @override
  State<LateDetailView> createState() => _LateDetailViewState();
}

class _LateDetailViewState extends State<LateDetailView> {
  bool _isExpanded = false;

  @override
  Widget build(BuildContext context) {
    final synopsisText =
    parse(widget.mangaDescription).documentElement!.text.trim();

    // Séparer auteurs / artistes
    final authors = widget.authors
        ?.where((a) => a.type.toLowerCase() == 'author')
        .map((a) => a.name)
        .toList() ??
        [];
    final artists = widget.authors
        ?.where((a) => a.type.toLowerCase() == 'artist')
        .map((a) => a.name)
        .toList() ??
        [];

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
                        fontWeight: FontWeight.w600),
                  ),
                  Wrap(
                    children: [
                      const Icon(Icons.star, color: Colors.orange, size: 30),
                      Text(widget.rating,
                          style: GoogleFonts.poppins(
                              textStyle: const TextStyle(fontSize: 20),
                              fontWeight: FontWeight.bold,
                              color: Color.fromARGB(255, 138, 40, 31))),
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
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
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
                            const Text('Auteur :',
                                style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold)),
                            ...authors.map((n) => Text(n, textAlign: TextAlign.center)),
                          ],
                        ),
                      ),
                    if (artists.isNotEmpty)
                      Flexible(
                        flex: 1,
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.center,
                          children: [
                            const Text('Artiste :',
                                style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold)),
                            ...artists.map((n) => Text(n, textAlign: TextAlign.center)),
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
              child: Text('Synopsis',
                  style: GoogleFonts.poppins(
                      textStyle: const TextStyle(fontSize: 18),
                      fontWeight: FontWeight.bold)),
            ),
            Padding(
              padding:
              const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
              child: AnimatedCrossFade(
                firstChild: Text(
                  synopsisText,
                  maxLines: 3,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                      fontSize: 13,
                      color: Colors.grey,
                      fontWeight: FontWeight.w600),
                ),
                secondChild: Text(
                  synopsisText,
                  style: const TextStyle(
                      fontSize: 13,
                      color: Colors.grey,
                      fontWeight: FontWeight.w600),
                ),
                crossFadeState: _isExpanded
                    ? CrossFadeState.showSecond
                    : CrossFadeState.showFirst,
                duration: const Duration(milliseconds: 200),
              ),
            ),
            Padding(
              padding: const EdgeInsets.only(left: 16),
              child: TextButton.icon(
                onPressed: () => setState(() => _isExpanded = !_isExpanded),
                icon: Icon(
                    _isExpanded ? Icons.expand_less : Icons.expand_more),
                label: Text(_isExpanded ? 'Voir moins' : 'Voir plus'),
                style: TextButton.styleFrom(
                  foregroundColor: Colors.pinkAccent,
                  padding: EdgeInsets.zero,
                  alignment: Alignment.centerLeft,
                ),
              ),
            ),

            const SizedBox(height: 8),

            // Chapitres en simple Column (plus de scroll interne)
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Column(
                children: widget.mangaChapters.map<Widget>((c) {
                  return RowChapter(
                    line: c[0],
                    chapter: c[1],
                    lock: c[2],
                  );
                }).toList(),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
