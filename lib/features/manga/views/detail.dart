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

import '../services/manga.service.dart';

class Detail extends StatefulWidget {
  final String muId;
  final String mangaTitle;
  final String? coverPath;

  const Detail(
      {super.key,
      required this.muId,
      required this.mangaTitle,
      this.coverPath});
  @override
  State<Detail> createState() => _DetailState();
}

bool isFavorite = true;

Widget iconFavorite = Icon(
  color: isFavorite == true ? Colors.grey : Colors.orange,
  Icons.star,
);

final List mangaType = [
  'Manwha',
  'Manga',
  'Ghibli',
  'JeSaisPas',
  'JeSaisPas',
  'JeSaisPas',
  'JeSaisPas',
  'JeSaisPas',
  'JeSaisPas',
];

class _DetailState extends State<Detail> {
  get image => null;
  late Future<MangaDetailDto> mangaDetail;
  MangaService mangaService = getIt<MangaService>();

  @override
  void initState() {
    super.initState();
    mangaDetail = mangaService.getMangaDetail(widget.muId);
  }

  void toggleFavorite() {
    setState(() {
      isFavorite = !isFavorite;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: FutureBuilder<MangaDetailDto>(
        future: mangaDetail,
        builder: (context, snapshot) {
          // en attente du fetch
          if (snapshot.connectionState != ConnectionState.done) {
            return const Center(child: CircularProgressIndicator());
          }
          // erreur
          if (snapshot.hasError) {
            return Center(child: Text('Erreur : ${snapshot.error}'));
          }
          // données reçues
          final manga = snapshot.data!;
          return SafeArea(
            child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(vertical: 8),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  // barre de retour
                  Row(
                    children: [
                      IconButton(
                        icon: const Icon(Icons.arrow_back, size: 30),
                        onPressed: () => Navigator.of(context).pop(),
                      ),
                    ],
                  ),

                  // couverture
                  SizedBox(
                    height: 160,
                    width: 250,
                    child: Padding(
                      padding: const EdgeInsets.all(7),
                      child: ImageHelper.loadMangaImage(widget.coverPath),
                    ),
                  ),

                  const SizedBox(height: 10),

                  // liste des genres
                  if (manga.genres != null && manga.genres!.isNotEmpty)
                    SizedBox(
                      height: 40,
                      child: ListView.builder(
                        scrollDirection: Axis.horizontal,
                        itemCount: manga.genres!.length,
                        itemBuilder: (ctx, i) =>
                            MangaType(type: manga.genres![i]),
                      ),
                    ),

                  const SizedBox(height: 12),

                  // titre
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    child: Text(
                      parse(widget.mangaTitle).documentElement!.text,
                      textAlign: TextAlign.center,
                      style: GoogleFonts.poppins(
                        textStyle: const TextStyle(
                          fontSize: 24,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ),

                  const SizedBox(height: 16),

                  // LateDetailView avec description, rating, chapitres…
                  LateDetailView(
                    mangaTitle: manga.title,
                    mangaDescription: manga.description,
                    rating: manga.rating,
                    mangaChapters:
                    ChaptersHelper.buildChapterList(manga.totalChapters),
                    mangaTotalChapters: manga.totalChapters,
                  ),

                  const SizedBox(height: 24),

                  // barre de boutons
                  Container(
                    height: 70,
                    padding: const EdgeInsets.symmetric(horizontal: 16),
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
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        // bouton favoris
                        ElevatedButton(
                          onPressed: toggleFavorite,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: isFavorite
                                ? Colors.orange
                                : Colors.grey.shade300,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(8),
                            ),
                            padding: const EdgeInsets.all(0),
                          ),
                          child: Icon(
                            Icons.star,
                            color: isFavorite ? Colors.white : Colors.white70,
                          ),
                        ),

                        // bouton lire
                        ElevatedButton(
                          onPressed: () {
                            // TODO: action de lecture
                          },
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Theme.of(context).primaryColor,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(15),
                            ),
                          ),
                          child: const Text(
                            'Lire',
                            style: TextStyle(fontSize: 17),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}

loadIconFavorite() {
  if (isFavorite) {
    iconFavorite = const Icon(
      color: Colors.orange,
      Icons.star,
    );
  } else {
    iconFavorite = const Icon(
      color: Colors.grey,
      Icons.star,
    );
  }
}
