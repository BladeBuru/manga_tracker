# VERSIONNING — recommendations

| Version | Date | Artefact/Composant | Changement | Auteur |
|---------|------|--------------------|------------|--------|
| 0.1.0 | 2026-06-04 | Module complet | Documentation initiale (rétro-ingénierie) | Rétro |
| 0.2.0 | 2026-06-19 | `recommendation.service.dart`, `paginated_recommendations_view.dart`, `recommendations_by_genre_view.dart` | Ajout `getSleeperHits()`, section pépites cachées, breakpoints `AppBreakpoints`, invalidation cache sur mutation bibliothèque | Sprint responsive/social/stats-v2 |
| 0.3.0 | 2026-09-04 | `recommendation_dismissal.service.dart`, `dismissible_recommendation_card.dart`, `manga_card.dart` | Rejet « pas intéressé / déjà vu » : appui long + feuille modale + SnackBar annulation 6 s, `DismissalReason` enum, invalidation cache sur rejet/annulation, event `DismissRecommendation` sur `HomePageBloc` | feat/pas-interesse |
