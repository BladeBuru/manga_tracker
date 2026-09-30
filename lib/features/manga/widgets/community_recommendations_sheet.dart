import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:mangatracker/core/components/app_empty_state.dart';
import 'package:mangatracker/core/components/app_error_state.dart';
import 'package:mangatracker/core/theme/app_colors.dart';
import 'package:mangatracker/core/theme/app_spacing.dart';
import 'package:mangatracker/features/manga/bloc/community_recommendations_cubit.dart';
import 'package:mangatracker/features/manga/dto/manga_recommendation_view.dto.dart';
import 'package:mangatracker/features/manga/widgets/community_recommendation_tile.dart';
import 'package:mangatracker/features/manga/widgets/detail_recommendations_section.dart';
import 'package:mangatracker/features/manga/widgets/manga_picker_sheet.dart';
import 'package:mangatracker/l10n/app_localizations.dart';

/// Feuille « Si vous avez aimé ce titre » de la fiche : recommandations
/// MangaUpdates + Manga Tracker (avec leur total), vote de l'utilisateur,
/// ajout d'une recommandation, puis les titres souvent présents dans les
/// mêmes bibliothèques ([readersAlsoRead], l'ancienne liste — conservée).
Future<void> showCommunityRecommendationsSheet(
  BuildContext context, {
  required int muId,
  List<MangaRecommendationView> readersAlsoRead = const [],
}) {
  return showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    backgroundColor: Theme.of(context).scaffoldBackgroundColor,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
    ),
    builder:
        (ctx) => BlocProvider(
          create:
              (_) => CommunityRecommendationsCubit(sourceMuId: muId)..load(),
          child: SafeArea(
            child: ConstrainedBox(
              constraints: BoxConstraints(
                maxHeight: MediaQuery.of(ctx).size.height * 0.85,
              ),
              // Messagerie propre à la feuille : sinon les messages de vote
              // s'affichent sur la fiche, SOUS la feuille, donc invisibles.
              child: ScaffoldMessenger(
                child: Scaffold(
                  backgroundColor: Colors.transparent,
                  resizeToAvoidBottomInset: false,
                  body: _SheetBody(
                    muId: muId,
                    readersAlsoRead: readersAlsoRead,
                  ),
                ),
              ),
            ),
          ),
        ),
  );
}

class _SheetBody extends StatelessWidget {
  final int muId;
  final List<MangaRecommendationView> readersAlsoRead;

  const _SheetBody({required this.muId, required this.readersAlsoRead});

  Future<void> _vote(
    BuildContext context,
    Future<CommunityVoteResult> Function() action,
  ) async {
    final l10n = AppLocalizations.of(context)!;
    final messenger = ScaffoldMessenger.of(context);
    final result = await action();
    final message = switch (result) {
      CommunityVoteResult.added => l10n.communityRecoAdded,
      CommunityVoteResult.removed => l10n.communityRecoRemoved,
      CommunityVoteResult.throttled => l10n.communityRecoThrottled,
      CommunityVoteResult.offline => l10n.networkError,
      CommunityVoteResult.failed => l10n.communityRecoActionError,
    };
    messenger.showSnackBar(SnackBar(content: Text(message)));
  }

  Future<void> _pickAndRecommend(BuildContext context) async {
    final cubit = context.read<CommunityRecommendationsCubit>();
    final picked = await showMangaPickerSheet(context, excludeMuId: muId);
    if (picked == null || !context.mounted) return;
    await _vote(
      context,
      () => cubit.recommend(picked.muId),
    );
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final theme = Theme.of(context);
    return BlocBuilder<
      CommunityRecommendationsCubit,
      CommunityRecommendationsState
    >(
      builder: (context, state) {
        final shownIds = state.items.map((i) => i.muId.toInt()).toSet();
        final others =
            readersAlsoRead
                .where((r) => !shownIds.contains(r.muId.toInt()))
                .toList();
        return CustomScrollView(
          shrinkWrap: true,
          slivers: [
            SliverPadding(
              padding: const EdgeInsets.fromLTRB(
                AppSpacing.m,
                AppSpacing.m,
                AppSpacing.m,
                AppSpacing.s,
              ),
              sliver: SliverToBoxAdapter(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      l10n.communityRecoTitle,
                      style: theme.textTheme.titleLarge?.copyWith(
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      l10n.communityRecoSubtitle,
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: AppColors.dsText2(theme.brightness),
                      ),
                    ),
                    const SizedBox(height: AppSpacing.s),
                    FilledButton.tonalIcon(
                      onPressed: () => _pickAndRecommend(context),
                      icon: const Icon(Icons.add_rounded),
                      label: Text(l10n.communityRecoAdd),
                    ),
                  ],
                ),
              ),
            ),
            ..._content(context, state),
            if (others.isNotEmpty)
              SliverToBoxAdapter(
                child: DetailRecommendationsSection(
                  recommendations: others,
                  title: l10n.communityRecoReadersAlsoRead,
                ),
              ),
          ],
        );
      },
    );
  }

  List<Widget> _content(
    BuildContext context,
    CommunityRecommendationsState state,
  ) {
    final l10n = AppLocalizations.of(context)!;
    final cubit = context.read<CommunityRecommendationsCubit>();
    if (state.loading && state.items.isEmpty) {
      return const [
        SliverToBoxAdapter(
          child: Padding(
            padding: EdgeInsets.all(AppSpacing.l),
            child: Center(child: CircularProgressIndicator()),
          ),
        ),
      ];
    }
    if (state.failed && state.items.isEmpty) {
      return [
        SliverToBoxAdapter(
          child: AppErrorState(
            message:
                state.isOffline
                    ? l10n.networkError
                    : l10n.communityRecoLoadError,
            retryLabel: l10n.retry,
            onRetry: cubit.load,
          ),
        ),
      ];
    }
    if (state.items.isEmpty) {
      return [
        SliverToBoxAdapter(
          child: AppEmptyState(
            icon: Icons.thumb_up_alt_outlined,
            title: l10n.communityRecoEmpty,
          ),
        ),
      ];
    }
    return [
      SliverList(
        delegate: SliverChildBuilderDelegate((context, index) {
          final item = state.items[index];
          return CommunityRecommendationTile(
            key: ValueKey(item.muId),
            item: item,
            pending: state.pending.contains(item.muId),
            onToggle: () => _vote(context, () => cubit.toggle(item)),
          );
        }, childCount: state.items.length),
      ),
    ];
  }
}
