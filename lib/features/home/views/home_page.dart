import 'package:mangatracker/core/service_locator/service_locator.dart';
import 'package:mangatracker/core/services/cache_helper_service.dart';
import 'package:mangatracker/core/services/connectivity_service.dart';
import 'package:mangatracker/features/auth/exceptions/invalid_credentials.exception.dart';
import 'package:mangatracker/features/home/widgets/homepage_manga_list.dart';
import 'package:mangatracker/features/profile/dto/user_information.dto.dart';
import 'package:mangatracker/features/profile/services/user.service.dart';

import '../../../core/components/filter_button.dart';
import '../../../core/components/welcome_header.dart';
import '../../../core/notifier/notifier.dart';
import '../../auth/services/auth.service.dart';
import '../../auth/views/login.view.dart';
import '../../manga/services/manga.service.dart';
import '../../manga/dto/manga_quick_view.dto.dart';
import 'package:flutter/material.dart';

import '../../manga/widgets/manga_card.dart';

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  final MangaService mangaService = getIt<MangaService>();
  final UserService userService = getIt<UserService>();
  final AuthService authService = getIt<AuthService>();
  final CacheHelperService _cacheHelper = getIt<CacheHelperService>();
  final ConnectivityService _connectivityService = getIt<ConnectivityService>();
  final Notifier notifier = Notifier();
  String? displayUsername;
  bool hasAlreadyBeenRedirected = false;
  bool _isOffline = false;

  UserInformationDto? user;
  late Future<List<MangaQuickViewDto>> trendingMangas;
  late Future<List<MangaQuickViewDto>> popularMangas;
  late Future<List<MangaQuickViewDto>> newMangas;

  @override
  void initState() {
    super.initState();
    loadResources();
    _listenToConnectivity();
  }

  void _listenToConnectivity() {
    _connectivityService.connectivityStream.listen((isConnected) {
      if (mounted) {
        setState(() {
          _isOffline = !isConnected;
        });
        // Rafraîchir les données si on revient en ligne
        if (isConnected) {
          loadResources();
        }
      }
    });
    
    // Vérifier l'état initial
    _checkInitialConnectivity();
  }
  
  void _checkInitialConnectivity() async {
    final isConnected = await _connectivityService.checkConnectivity();
    if (mounted) {
      setState(() {
        _isOffline = !isConnected;
      });
    }
  }

  void loadResources() {
    // Utiliser le cache pour chaque section séparément
    trendingMangas = _cacheHelper.loadSearchResults(
      query: 'trending',
      networkCall: () => mangaService.getTrendingMangas(),
    ).catchError((err) {
      _errorHandler();
      return List<MangaQuickViewDto>.empty();
    }, test: (err) => err is InvalidCredentialsException);

    popularMangas = _cacheHelper.loadSearchResults(
      query: 'popular',
      networkCall: () => mangaService.getPopularMangas(),
    ).catchError((err) {
      _errorHandler();
      return List<MangaQuickViewDto>.empty();
    }, test: (err) => err is InvalidCredentialsException);

    newMangas = _cacheHelper.loadSearchResults(
      query: 'new',
      networkCall: () => mangaService.getNewMangas(),
    ).catchError((err) {
      _errorHandler();
      return List<MangaQuickViewDto>.empty();
    }, test: (err) => err is InvalidCredentialsException);

    userService
        .getUserInformation()
        .then((value) {
          setState(() {
            if (!mounted || hasAlreadyBeenRedirected) return;
            user = value;
            displayUsername = value.username;
          });
        })
        .catchError((err) {
          if (!mounted || hasAlreadyBeenRedirected) return;
          _errorHandler();
        }, test: (err) => err is InvalidCredentialsException);
  }

  void _errorHandler() {
    if (!hasAlreadyBeenRedirected && context.mounted) {
      authService.logout();
      redirectToLoginPage();
      notifier.error( 'Expired session');
      setState(() {
        if (!mounted || hasAlreadyBeenRedirected) return;
        hasAlreadyBeenRedirected = true;
      });
    }
  }

  void redirectToLoginPage() {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => const LoginView()),
    );
  }

  get border => null;

  final Color themePage = const Color(0xffe0234f);

  int indexButtonBar = 0;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Padding(
        padding: const EdgeInsets.all(25.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 20),
            WelcomeHeader(username: displayUsername),
            
            // Indicateur de mode hors ligne
            if (_isOffline)
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(12),
                margin: const EdgeInsets.only(bottom: 16),
                decoration: BoxDecoration(
                  color: Colors.orange.withOpacity(0.1),
                  border: Border.all(color: Colors.orange),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Row(
                  children: [
                    Icon(Icons.cloud_off, color: Colors.orange, size: 20),
                    SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        'Mode hors ligne - Données en cache',
                        style: TextStyle(color: Colors.orange, fontWeight: FontWeight.w500),
                      ),
                    ),
                  ],
                ),
              ),

            const SizedBox(height: 20),
            Row(
              children: [
                Text(
                  'Tendances',
                  style: Theme.of(context).textTheme.titleSmall,
                ),
                const Spacer(),
                const Icon(Icons.add_circle_outline),
              ],
            ),

            const SizedBox(height: 20),
            SizedBox(
              height: 200,
              child: FutureBuilder<List<MangaQuickViewDto>>(
                future: trendingMangas,
                builder: (context, snapshot) {
                  if (snapshot.hasData) {
                    final mangaList = snapshot.data!;
                    return ListView.builder(
                      scrollDirection: Axis.horizontal,
                      itemCount: mangaList.length,
                      itemBuilder: (context, index) {
                        final manga = mangaList[index];
                        return MangaCard(
                          muId: manga.muId.toString(),
                          mangaTitle: manga.title,
                          mangaAuthor: manga.year.toString(),
                          mediumImgPath: manga.mediumCoverUrl,
                          rating: manga.rating,
                        );
                      },
                    );
                  } else if (snapshot.hasError) {
                    return Text('Erreur : ${snapshot.error}');
                  } else {
                    return const Center(child: CircularProgressIndicator());
                  }
                },
              ),
            ),

            const SizedBox(height: 20),
            // Boutons filtres
            SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                children: [
                  FilterButton(
                    label: 'Tous',
                    selected: indexButtonBar == 0,
                    onPressed: () => setState(() => indexButtonBar = 0),
                  ),
                  const SizedBox(width: 10),
                  FilterButton(
                    label: 'Populaires',
                    selected: indexButtonBar == 1,
                    onPressed: () => setState(() => indexButtonBar = 1),
                  ),
                  const SizedBox(width: 10),
                  FilterButton(
                    label: 'Nouveautés',
                    selected: indexButtonBar == 2,
                    onPressed: () => setState(() => indexButtonBar = 2),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 20),
            Expanded(
              child: Builder(
                builder: (context) {
                  switch (indexButtonBar) {
                    case 0:
                      return HomepageMangaList(mangas: trendingMangas);
                    case 1:
                      return HomepageMangaList(mangas: popularMangas);
                    case 2:
                      return HomepageMangaList(mangas: newMangas);
                    default:
                      return const Center(child: Text('Erreur de chargement'));
                  }
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

}
