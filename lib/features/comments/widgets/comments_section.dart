import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:mangatracker/core/components/app_chip.dart';
import 'package:mangatracker/core/components/app_error_state.dart';
import 'package:mangatracker/core/theme/app_spacing.dart';
import 'package:mangatracker/features/comments/bloc/comments_bloc.dart';
import 'package:mangatracker/features/comments/dto/comment.dto.dart';
import 'package:mangatracker/features/comments/widgets/comment_input.dart';
import 'package:mangatracker/features/comments/widgets/comment_tile.dart';
import 'package:mangatracker/l10n/app_localizations.dart';

/// Section commentaires à embarquer dans `detail_bloc_view.dart` ou ailleurs
/// (Phase 7.1).
///
/// Self-contained : porte son propre `BlocProvider<CommentsBloc>` et son
/// scroll listener pour le pagination "load more". À placer en bas d'un
/// CustomScrollView via SliverToBoxAdapter, ou dans un Column scrollable.
class CommentsSection extends StatelessWidget {
  final int muId;
  const CommentsSection({super.key, required this.muId});

  @override
  Widget build(BuildContext context) {
    return BlocProvider<CommentsBloc>(
      create: (_) => CommentsBloc(muId)..add(const LoadComments()),
      child: const _CommentsContent(),
    );
  }
}

class _CommentsContent extends StatefulWidget {
  const _CommentsContent();

  @override
  State<_CommentsContent> createState() => _CommentsContentState();
}

class _CommentsContentState extends State<_CommentsContent> {
  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return BlocConsumer<CommentsBloc, CommentsState>(
      listenWhen: (a, b) =>
          b is CommentsLoaded && b.lastError != null,
      listener: (context, state) {
        if (state is CommentsLoaded && state.lastError != null) {
          ScaffoldMessenger.of(context).showSnackBar(SnackBar(
            content: Text(state.lastError!),
            backgroundColor: Theme.of(context).colorScheme.error,
          ));
        }
      },
      builder: (context, state) {
        return Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            _Header(state: state),
            const SizedBox(height: 8),
            CommentInput(
              onSubmit: (content, rating) {
                context.read<CommentsBloc>().add(PostComment(
                      content: content,
                      rating: rating,
                    ));
              },
            ),
            const SizedBox(height: 12),
            if (state is CommentsLoading || state is CommentsInitial)
              const Padding(
                padding: EdgeInsets.all(24),
                child: Center(child: CircularProgressIndicator()),
              )
            else if (state is CommentsError)
              AppErrorState(
                message: state.message,
                retryLabel: l10n.retry,
                onRetry: () =>
                    context.read<CommentsBloc>().add(const LoadComments()),
              )
            else if (state is CommentsLoaded)
              if (state.items.isEmpty)
                Padding(
                  padding: const EdgeInsets.all(16),
                  child: Text(
                    l10n.commentsEmpty,
                    textAlign: TextAlign.center,
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          color: Theme.of(context).colorScheme.onSurfaceVariant,
                        ),
                  ),
                )
              else
                _CommentsList(state: state),
          ],
        );
      },
    );
  }
}

class _Header extends StatelessWidget {
  final CommentsState state;
  const _Header({required this.state});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final sort = state is CommentsLoaded
        ? (state as CommentsLoaded).sort
        : CommentSort.recent;
    final count =
        state is CommentsLoaded ? (state as CommentsLoaded).items.length : 0;
    return Row(
      children: [
        Expanded(
          child: Text(
            '${l10n.commentsTitle} ($count)',
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.w700,
                ),
          ),
        ),
        // Sort toggle — 2 AppChip cliquables (cohérent avec le reste du
        // design system). Plus de SegmentedButton qui rendait orange.
        Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            sort == CommentSort.recent
                ? AppChip.primary(
                    label: l10n.commentsSortRecent,
                    icon: Icons.schedule,
                  )
                : AppChip(
                    label: l10n.commentsSortRecent,
                    icon: Icons.schedule,
                    onTap: () => context
                        .read<CommentsBloc>()
                        .add(const ChangeCommentSort(CommentSort.recent)),
                  ),
            const SizedBox(width: AppSpacing.xs),
            sort == CommentSort.top
                ? AppChip.primary(
                    label: l10n.commentsSortTop,
                    icon: Icons.trending_up,
                  )
                : AppChip(
                    label: l10n.commentsSortTop,
                    icon: Icons.trending_up,
                    onTap: () => context
                        .read<CommentsBloc>()
                        .add(const ChangeCommentSort(CommentSort.top)),
                  ),
          ],
        ),
      ],
    );
  }
}

class _CommentsList extends StatelessWidget {
  final CommentsLoaded state;
  const _CommentsList({required this.state});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        for (final comment in state.items)
          CommentTile(
            comment: comment,
            onDelete: () =>
                context.read<CommentsBloc>().add(DeleteComment(comment.id)),
          ),
        if (state.hasMore)
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 8),
            child: Center(
              child: state.isLoadingMore
                  ? const CircularProgressIndicator()
                  : OutlinedButton(
                      onPressed: () => context
                          .read<CommentsBloc>()
                          .add(const LoadMoreComments()),
                      child: Text(AppLocalizations.of(context)!.commentsLoadMore),
                    ),
            ),
          ),
      ],
    );
  }
}

// _ErrorBlock retiré — utilise désormais AppErrorState du design system.
