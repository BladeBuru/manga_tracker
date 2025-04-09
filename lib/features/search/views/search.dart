import 'dart:async';

import 'package:flutter/material.dart';
import 'package:mangatracker/core/service_locator/service_locator.dart';

import '../../home/widgets/homepage_manga_list.dart';
import '../../manga/dto/manga_quick_view.dto.dart';
import '../../manga/services/manga.service.dart';

class Search extends StatefulWidget {
  const Search({Key? key}) : super(key: key);
  @override
  State<Search> createState() => _RechercheState();
}

class _RechercheState extends State<Search> {
  get border => null;
  MangaService mangaService = getIt<MangaService>();
  late Future<List<MangaQuickViewDto>> searchedMangas;
  final searchController = TextEditingController();
  Timer? searchOnStoppedTyping;
  final Color themePage = const Color(0xffe0234f);
  int indexButtonBar = 0;
  late Widget childWidget =
      const Center(child: Text("Nothing to display yet!"));

  void doSearchManga() async {
    if (searchController.text.isEmpty) {
      return;
    }
    searchedMangas = mangaService.searchForMangas(searchController.text);
    setState(() {
      childWidget = HomepageMangaList(mangas: searchedMangas);
    });
  }

  _onChangeHandler(String value) {
    const duration = Duration(milliseconds: 800);
    if (searchOnStoppedTyping != null) {
      setState(() => searchOnStoppedTyping?.cancel());
    }
    setState(
        () => searchOnStoppedTyping = Timer(duration, () => doSearchManga()));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      resizeToAvoidBottomInset: false,
      body: Padding(
        padding: const EdgeInsets.all(25.0),
        child: Column(children: [
          //Espace
          const SizedBox(height: 20),

          // Search bar
          Container(
            width: 950,
            decoration: BoxDecoration(
                color: const Color(0xfff4f3fd),
                border: Border.all(color: Colors.white),
                borderRadius: BorderRadius.circular(12)),
            child: Row(
              children: [
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 10.0),
                  child: SizedBox(
                    height: 20,
                    child: Image.asset('assets/images/mask_logo.png'),
                  ),
                ),
                Expanded(
                  child: TextField(
                      controller: searchController,
                      onChanged: _onChangeHandler,
                      decoration: const InputDecoration(
                          border: InputBorder.none,
                          hintText: 'Search Manga, Manwha, ...',
                          hintStyle: TextStyle(color: Color(0xffb8b8d2)))),
                ),
                const SizedBox(
                  width: 10,
                ),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 10.0),
                  child: IconButton(
                    icon: const Icon(Icons.clear, size: 20),
                    onPressed: () {
                      searchController.clear();
                    },
                  ),
                )
              ],
            ),
          ),
          Expanded(
            child: SizedBox(
              child: childWidget,
            ),
          )
        ]),
      ),
    );
  }
}
