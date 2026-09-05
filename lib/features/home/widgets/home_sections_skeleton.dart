import 'package:flutter/material.dart';
import 'package:mangatracker/core/components/app_skeleton_box.dart';
import 'package:mangatracker/core/theme/app_radius.dart';
import 'package:mangatracker/core/theme/app_spacing.dart';
import 'package:mangatracker/features/home/helpers/home_layout_metrics.dart';

/// Squelette de l'accueil pendant le premier chargement : trois sections
/// esquissees (tile + barre de titre, puis une rangee de cartes) aux memes
/// dimensions que le contenu reel, pour eviter tout saut de mise en page.
class HomeSectionsSkeleton extends StatelessWidget {
  final HomeLayoutMetrics metrics;
  final int sectionCount;

  const HomeSectionsSkeleton({
    super.key,
    required this.metrics,
    this.sectionCount = 3,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: List.generate(
        sectionCount,
        (_) => _SectionSkeleton(metrics: metrics),
      ),
    );
  }
}

class _SectionSkeleton extends StatelessWidget {
  final HomeLayoutMetrics metrics;

  const _SectionSkeleton({required this.metrics});

  @override
  Widget build(BuildContext context) {
    final hPad = metrics.horizontalPadding;
    return Padding(
      padding: const EdgeInsets.only(bottom: HomeLayoutMetrics.sectionGap),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: EdgeInsets.symmetric(horizontal: hPad),
            child: Row(
              children: [
                AppSkeletonBox(
                  width: AppSpacing.xl,
                  height: AppSpacing.xl,
                  borderRadius: AppRadius.circularLg,
                ),
                const SizedBox(width: AppSpacing.s + AppSpacing.xs),
                AppSkeletonBox(
                  width: metrics.cardWidth * 1.25,
                  height: AppSpacing.m,
                ),
              ],
            ),
          ),
          const SizedBox(height: AppSpacing.s + AppSpacing.xs),
          SizedBox(
            height: metrics.cardHeight,
            child: ListView.builder(
              scrollDirection: Axis.horizontal,
              physics: const NeverScrollableScrollPhysics(),
              padding: EdgeInsets.symmetric(horizontal: hPad),
              itemCount: 6,
              itemBuilder: (_, index) => Padding(
                padding: const EdgeInsets.only(right: HomeLayoutMetrics.cardGap),
                child: _CardSkeleton(metrics: metrics),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _CardSkeleton extends StatelessWidget {
  final HomeLayoutMetrics metrics;

  const _CardSkeleton({required this.metrics});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: metrics.cardWidth,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          AppSkeletonBox(
            width: metrics.cardWidth,
            height: metrics.coverHeight,
            borderRadius: AppRadius.circularXl,
          ),
          const SizedBox(height: AppSpacing.s),
          AppSkeletonBox(width: metrics.cardWidth * 0.85, height: AppSpacing.m - 4),
          const SizedBox(height: AppSpacing.xs + 2),
          AppSkeletonBox(width: metrics.cardWidth * 0.5, height: AppSpacing.s + 2),
        ],
      ),
    );
  }
}
