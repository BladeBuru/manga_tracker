import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:mangatracker/core/service_locator/service_locator.dart';
import 'package:mangatracker/features/manga/services/manga.service.dart';

import '../../manga/dto/manga_quick_view.dto.dart';
import '../../../core/network/http_service.dart';

class LibraryService {
  HttpService httpService = getIt<HttpService>();
  MangaService mangaService = getIt<MangaService>();

  Future<LibraryService> init() async {
    return this;
  }

  Future<List<MangaQuickViewDto>> getUserSavedMangas() async {
    Uri url = Uri.https(dotenv.env['MT_API_URL']!, '/library/all');
    return mangaService.getMangas(url);
  }
}
