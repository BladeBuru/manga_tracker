import 'package:equatable/equatable.dart';
import 'package:mangatracker/features/home/dto/home_section.dto.dart';
import 'package:mangatracker/features/home/dto/home_section_kind.dart';
import 'package:mangatracker/features/manga/dto/manga_quick_view.dto.dart';

/// Etats du [HomeSectionPageBloc].
abstract class HomeSectionPageState extends Equatable {
  const HomeSectionPageState();

  bool get isOffline => false;
  bool get requiresReauth => false;

  @override
  List<Object?> get props => [];
}

class HomeSectionPageInitial extends HomeSectionPageState {
  const HomeSectionPageInitial();
}

class HomeSectionPageLoading extends HomeSectionPageState {
  const HomeSectionPageLoading();
}

class HomeSectionPageLoaded extends HomeSectionPageState {
  final String sectionId;

  /// `null` si le serveur a renvoye un `kind` inconnu : le titre retombe
  /// sur l'identifiant brut.
  final HomeSectionKind? kind;
  final HomeSectionParams params;
  final List<MangaQuickViewDto> items;

  /// Derniere page chargee (1-based).
  final int page;

  /// Total annonce par le serveur (0 si inconnu).
  final int total;
  final bool hasMore;
  final bool isLoadingMore;

  /// La page suivante n'a pas pu etre chargee : la vue propose de reessayer.
  final bool loadMoreFailed;

  @override
  final bool isOffline;

  @override
  final bool requiresReauth;

  const HomeSectionPageLoaded({
    required this.sectionId,
    required this.kind,
    this.params = HomeSectionParams.none,
    required this.items,
    required this.page,
    this.total = 0,
    required this.hasMore,
    this.isLoadingMore = false,
    this.loadMoreFailed = false,
    this.isOffline = false,
    this.requiresReauth = false,
  });

  HomeSectionPageLoaded copyWith({
    List<MangaQuickViewDto>? items,
    int? page,
    int? total,
    bool? hasMore,
    bool? isLoadingMore,
    bool? loadMoreFailed,
    bool? isOffline,
    bool? requiresReauth,
  }) {
    return HomeSectionPageLoaded(
      sectionId: sectionId,
      kind: kind,
      params: params,
      items: items ?? this.items,
      page: page ?? this.page,
      total: total ?? this.total,
      hasMore: hasMore ?? this.hasMore,
      isLoadingMore: isLoadingMore ?? this.isLoadingMore,
      loadMoreFailed: loadMoreFailed ?? this.loadMoreFailed,
      isOffline: isOffline ?? this.isOffline,
      requiresReauth: requiresReauth ?? this.requiresReauth,
    );
  }

  @override
  List<Object?> get props => [
        sectionId,
        kind,
        params,
        items,
        page,
        total,
        hasMore,
        isLoadingMore,
        loadMoreFailed,
        isOffline,
        requiresReauth,
      ];
}

class HomeSectionPageError extends HomeSectionPageState {
  final String message;

  /// 404 : la section n'existe pas (ou plus) cote serveur.
  final bool notFound;

  @override
  final bool isOffline;

  @override
  final bool requiresReauth;

  const HomeSectionPageError({
    required this.message,
    this.notFound = false,
    this.isOffline = false,
    this.requiresReauth = false,
  });

  @override
  List<Object?> get props => [message, notFound, isOffline, requiresReauth];
}
