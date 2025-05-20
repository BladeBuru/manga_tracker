import 'package:flutter/material.dart';
import 'package:mangatracker/core/service_locator/service_locator.dart';
import 'package:mangatracker/features/library/services/library.service.dart';

import '../../auth/exceptions/invalid_credentials.exception.dart';
import '../../auth/views/login.view.dart';
import '../../home/widgets/homepage_manga_list.dart';
import '../../manga/dto/manga_quick_view.dto.dart';

class LibraryView extends StatefulWidget {
  const LibraryView({super.key});

  @override
  State<LibraryView> createState() => _LibraryViewState();
}

class _LibraryViewState extends State<LibraryView> {
  LibraryService libraryService = getIt<LibraryService>();

  late Future<List<MangaQuickViewDto>> savedMangas;

  @override
  void initState() {
    super.initState();
    try {
      savedMangas = libraryService.getUserSavedMangas();
    } on InvalidCredentialsException {
      if (context.mounted) {
        redirectToLoginPage();
      }
    }
  }

  void reloadMangas() {
    setState(() {
      savedMangas = libraryService.getUserSavedMangas();
    });
  }

  void redirectToLoginPage() {
    Navigator.push(
        context, MaterialPageRoute(builder: (context) => const LoginView()));
  }

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: SizedBox(
            height: 290,
            child: HomepageMangaList(
              mangas: savedMangas,
              onDetailReturn: reloadMangas,
            ),
          ),
        ),
      ],
    );
  }
}
