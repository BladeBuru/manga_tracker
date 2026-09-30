part of 'community_recommendations_cubit.dart';

class CommunityRecommendationsState extends Equatable {
  final bool loading;
  final bool failed;
  final bool isOffline;
  final List<CommunityRecommendationDto> items;

  /// Œuvres dont le vote est en cours d'envoi (bouton désactivé).
  final Set<num> pending;

  const CommunityRecommendationsState({
    this.loading = true,
    this.failed = false,
    this.isOffline = false,
    this.items = const [],
    this.pending = const {},
  });

  CommunityRecommendationsState copyWith({
    bool? loading,
    bool? failed,
    bool? isOffline,
    List<CommunityRecommendationDto>? items,
    Set<num>? pending,
  }) => CommunityRecommendationsState(
    loading: loading ?? this.loading,
    failed: failed ?? this.failed,
    isOffline: isOffline ?? this.isOffline,
    items: items ?? this.items,
    pending: pending ?? this.pending,
  );

  @override
  List<Object?> get props => [
    loading,
    failed,
    isOffline,
    pending,
    [for (final i in items) '${i.muId}:${i.totalVotes}:${i.recommendedByMe}'],
  ];
}
