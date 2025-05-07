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

Widget iconFavorite = const Icon(
  Icons.star,
  color: Colors.orange,
);

class _DetailState extends State<Detail> {
  late Future<MangaDetailDto> mangaDetail;
  final MangaService mangaService = getIt<MangaService>();

  @override
  void initState() {
    super.initState();
    mangaDetail = mangaService.getMangaDetail(widget.muId);
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      color: Colors.white,
      child: SafeArea(
        child: Scaffold(
          body: Column(
            children: [
              // ─────────── Barre supérieure ───────────
              Row(
                children: [
                  Padding(
                    padding: const EdgeInsets.all(10),
                    child: GestureDetector(
                      onTap: () => Navigator.pop(context),
                      child: const Icon(
                        Icons.arrow_back,
                        color: Colors.black,
                        size: 30,
                      ),
                    ),
                  ),
                ],
              ),

              // ─────────── Couverture + puces de genres ───────────
              Column(
                children: [
                  SizedBox(
                    height: 160,
                    width: 250,
                    child: Padding(
                      padding: const EdgeInsets.all(7),
                      child: Align(
                        alignment: Alignment.center,
                        child: ImageHelper.loadMangaImage(widget.coverPath),
                      ),
                    ),
                  ),
                  const SizedBox(height: 10),

                  // Affichage dynamique des genres
                  SizedBox(
                    height: 20,
                    width: 300,
                    child: FutureBuilder<MangaDetailDto>(
                      future: mangaDetail,
                      builder: (context, snapshot) {
                        if (snapshot.hasData) {
                          final List<String> genres =
                              snapshot.data!.genres ?? <String>[];
                          return ListView.builder(
                            itemCount: genres.length,
                            scrollDirection: Axis.horizontal,
                            itemBuilder: (context, index) =>
                                MangaType(type: genres[index]),
                          );
                        }
                        return const SizedBox.shrink();
                      },
                    ),
                  ),
                ],
              ),

              // ─────────── Titre ───────────
              Container(
                constraints: const BoxConstraints(maxWidth: 300),
                child: Text(
                  parse(widget.mangaTitle).documentElement!.text,
                  textAlign: TextAlign.center,
                  style: GoogleFonts.poppins(
                    textStyle: const TextStyle(fontSize: 24),
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),

              // ─────────── Détails (description, chapitres…) ───────────
              FutureBuilder<MangaDetailDto>(
                future: mangaDetail,
                builder: (context, snapshot) {
                  if (snapshot.hasData) {
                    final manga = snapshot.data!;
                    return LateDetailView(
                      mangaTitle: manga.title,
                      mangaDescription: manga.description,
                      rating: manga.rating,
                      mangaChapters:
                          ChaptersHelper.buildChapterList(manga.totalChapters),
                      mangaTotalChapters: manga.totalChapters,
                    );
                  } else if (snapshot.hasError) {
                    return Text('Error: ${snapshot.error}');
                  }
                  return const SizedBox(
                    height: 200,
                    width: 200,
                    child: Center(child: CircularProgressIndicator()),
                  );
                },
              ),

              // ─────────── Barre inférieure ───────────
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
                child: Row(
                  children: [
                    ButtonBar(
                      children: [
                        SizedBox(
                          height: double.infinity,
                          width: 100,
                          child: ElevatedButton(
                            style: ButtonStyle(
                              backgroundColor: MaterialStateProperty.all<Color>(
                                  const Color.fromRGBO(255, 235, 240, 50)),
                              shape: MaterialStateProperty.all<
                                  RoundedRectangleBorder>(
                                RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(8),
                                ),
                              ),
                            ),
                            onPressed: () {
                              setState(() {
                                isFavorite = !isFavorite;
                                loadIconFavorite();
                              });
                            },
                            child: iconFavorite,
                          ),
                        ),
                        SizedBox(
                          height: double.infinity,
                          child: ElevatedButton(
                            style: ButtonStyle(
                              backgroundColor:
                                  MaterialStateProperty.all<Color>(themePage),
                              shape: MaterialStateProperty.all<
                                  RoundedRectangleBorder>(
                                RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(15),
                                ),
                              ),
                            ),
                            onPressed: () {},
                            child: const Text(
                              'Lire',
                              style: TextStyle(fontSize: 17),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

void loadIconFavorite() {
  iconFavorite = Icon(
    Icons.star,
    color: isFavorite ? Colors.orange : Colors.grey,
  );
}
