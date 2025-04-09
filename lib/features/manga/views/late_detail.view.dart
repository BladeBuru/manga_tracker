import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:html/parser.dart';

import 'row_chapter.dart';

class LateDetailView extends StatefulWidget {
  final String mangaTitle;
  final String mangaDescription;
  final String rating;
  final List mangaChapters;
  final num? mangaTotalChapters;

  const LateDetailView(
      {super.key,
      required this.mangaTitle,
      required this.mangaDescription,
      required this.rating,
      required this.mangaChapters,
      this.mangaTotalChapters});

  @override
  State<LateDetailView> createState() => _LateDetailViewState();
}

class _LateDetailViewState extends State<LateDetailView> {
  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              Text(
                '${widget.mangaTotalChapters} Chapters',
                style: const TextStyle(
                    fontSize: 15,
                    color: Colors.grey,
                    fontWeight: FontWeight.w600),
              ),
              Wrap(children: [
                const Icon(
                  Icons.star,
                  color: Colors.orange,
                  size: 30,
                ),
                Text(widget.rating,
                    style: GoogleFonts.poppins(
                      textStyle: const TextStyle(fontSize: 20),
                      fontWeight: FontWeight.bold,
                      fontStyle: FontStyle.normal,
                      color: const Color.fromARGB(255, 138, 40, 31),
                    )),
              ]),
            ],
          ),
          Text('Synopsis',
              textAlign: TextAlign.left,
              style: GoogleFonts.poppins(
                textStyle: const TextStyle(fontSize: 18),
                fontWeight: FontWeight.bold,
                fontStyle: FontStyle.normal,
              )),
          Text(
            parse(widget.mangaDescription).documentElement!.text,
            overflow: TextOverflow.clip,
            style: const TextStyle(
                fontSize: 13, color: Colors.grey, fontWeight: FontWeight.w600),
          ),
          Expanded(
            child: SizedBox(
              height: 450,
              child: ListView.builder(
                itemCount: widget.mangaChapters.length,
                scrollDirection: Axis.vertical,
                itemBuilder: (context, index) {
                  return RowChapter(
                    line: widget.mangaChapters[index][0],
                    chapter: widget.mangaChapters[index][1],
                    lock: widget.mangaChapters[index][2],
                  );
                },
              ),
            ),
          ),
        ],
      ),
    );
  }
}
