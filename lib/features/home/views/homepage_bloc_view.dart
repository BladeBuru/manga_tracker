import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:mangatracker/core/service_locator/service_locator.dart';
import 'package:mangatracker/features/home/bloc/homepage_bloc.dart';
import 'package:mangatracker/features/home/bloc/homepage_event.dart';
import 'package:mangatracker/features/home/bloc/homepage_state.dart';
import 'package:mangatracker/features/manga/dto/manga_quick_view.dto.dart';
import 'package:mangatracker/features/home/widgets/homepage_manga_list.dart';
import 'package:mangatracker/features/manga/widgets/manga_card.dart';
import '../../../core/components/filter_button.dart';
import '../../../core/components/welcome_header.dart';
import '../../auth/views/login.view.dart';

/// Vue réactive de la page d'accueil utilisant BLoC - Design original conservé
class HomePageBlocView extends StatefulWidget {
  const HomePageBlocView({super.key});

  @override
  State<HomePageBlocView> createState() => _HomePageBlocViewState();
}

class _HomePageBlocViewState extends State<HomePageBlocView> {
  final HomePageBloc _homePageBloc = getIt<HomePageBloc>();
  int indexButtonBar = 0;

  @override
  void initState() {
    super.initState();
    print('🏠 HomePageBlocView initialisée - Utilisation du BLoC !');
    // Charger la page d'accueil au démarrage
    _homePageBloc.add(const LoadHomePage());
  }

  void _redirectToLoginPage() {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => const LoginView()),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: BlocConsumer<HomePageBloc, HomePageState>(
        bloc: _homePageBloc,
        listener: (context, state) {
          // Gérer les erreurs d'authentification
          if (state is HomePageError) {
            if (state.message.contains('InvalidCredentials') || 
                state.message.contains('Expired session')) {
              _redirectToLoginPage();
            }
          }
        },
        builder: (context, state) {
          return Padding(
            padding: const EdgeInsets.all(25.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const SizedBox(height: 20),
                _buildWelcomeHeader(state),
                
                // Indicateur de mode hors ligne
                _buildOfflineIndicator(state),

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
                _buildTrendingSection(state),

                const SizedBox(height: 20),
                // Boutons filtres
                _buildFilterButtons(),

                const SizedBox(height: 20),
                Expanded(
                  child: _buildFilteredMangaList(state),
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildWelcomeHeader(HomePageState state) {
    String? displayUsername;
    
    if (state is HomePageLoaded) {
      displayUsername = state.user?.username;
    }
    
    return WelcomeHeader(username: displayUsername);
  }

  Widget _buildOfflineIndicator(HomePageState state) {
    final isOffline = state is HomePageLoaded && state.isOffline ||
                      state is HomePageError && state.isOffline;
    
    if (!isOffline) return const SizedBox.shrink();
    
    final pendingActions = state is HomePageLoaded ? state.pendingActions : 0;
    
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(12),
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: Colors.orange.withOpacity(0.1),
        border: Border.all(color: Colors.orange),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        children: [
          const Icon(Icons.cloud_off, color: Colors.orange, size: 20),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              'Mode hors ligne - Données en cache${pendingActions > 0 ? ' ($pendingActions actions en attente)' : ''}',
              style: const TextStyle(color: Colors.orange, fontWeight: FontWeight.w500),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTrendingSection(HomePageState state) {
    if (state is HomePageLoading) {
      return const SizedBox(
        height: 200,
        child: Center(child: CircularProgressIndicator()),
      );
    }
    
    if (state is HomePageError) {
      return SizedBox(
        height: 200,
        child: Center(
          child: Text('Erreur : ${state.message}'),
        ),
      );
    }
    
    if (state is HomePageLoaded) {
      final mangaList = state.trendingMangas;
      return SizedBox(
        height: 200,
        child: mangaList.isEmpty
            ? const Center(child: Text('Aucun manga en tendance'))
            : ListView.builder(
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
              ),
      );
    }
    
    return const SizedBox(height: 200);
  }

  Widget _buildFilterButtons() {
    return SingleChildScrollView(
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
    );
  }

  Widget _buildFilteredMangaList(HomePageState state) {
    if (state is HomePageLoading) {
      return const Center(child: CircularProgressIndicator());
    }
    
    if (state is HomePageError) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text('Erreur : ${state.message}'),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: () => _homePageBloc.add(const LoadHomePage()),
              child: const Text('Réessayer'),
            ),
          ],
        ),
      );
    }
    
    if (state is HomePageLoaded) {
      late List<MangaQuickViewDto> mangaList;
      
      switch (indexButtonBar) {
        case 0:
          mangaList = state.trendingMangas;
          break;
        case 1:
          mangaList = state.popularMangas;
          break;
        case 2:
          mangaList = state.newMangas;
          break;
        default:
          mangaList = state.trendingMangas;
      }
      
      // Utiliser le widget HomepageMangaList existant pour garder le même rendu
      return HomepageMangaList(mangas: Future.value(mangaList));
    }
    
    return const Center(child: Text('Aucune donnée disponible'));
  }
}