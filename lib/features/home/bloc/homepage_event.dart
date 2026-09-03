import 'package:equatable/equatable.dart';

/// Événements pour HomePageBloc
abstract class HomePageEvent extends Equatable {
  const HomePageEvent();

  @override
  List<Object?> get props => [];
}

/// Charger la page d'accueil
class LoadHomePage extends HomePageEvent {
  const LoadHomePage();
}

/// Rafraîchir la page d'accueil
class RefreshHomePage extends HomePageEvent {
  const RefreshHomePage();
}

/// Charger les mangas populaires
class LoadPopularMangas extends HomePageEvent {
  const LoadPopularMangas();
}

/// Charger les nouveaux mangas
class LoadNewMangas extends HomePageEvent {
  const LoadNewMangas();
}

/// Charger les mangas en tendance
class LoadTrendingMangas extends HomePageEvent {
  const LoadTrendingMangas();
}

/// Charger les informations utilisateur
class LoadUserInfo extends HomePageEvent {
  const LoadUserInfo();
}

/// Retirer de l'accueil un titre ecarte par l'utilisateur
/// (« pas interesse / deja vu »).
///
/// Le serveur a deja enregistre le rejet : cet event ne fait que refleter
/// la decision dans l'etat courant, sans refetch. Le BLoC etant un lazy
/// singleton, le titre reste absent tant que l'accueil n'est pas recharge.
class DismissRecommendation extends HomePageEvent {
  final num muId;

  const DismissRecommendation(this.muId);

  @override
  List<Object?> get props => [muId];
}
