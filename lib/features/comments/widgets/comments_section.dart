import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:mangatracker/core/components/app_chip.dart';
import 'package:mangatracker/core/components/app_error_state.dart';
import 'package:mangatracker/core/network/api_error_message.dart';
import 'package:mangatracker/core/router/app_modals.dart';
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

  /// Injectable pour les tests.
  final CommentsBloc Function()? createBloc;

  const CommentsSection({super.key, required this.muId, this.createBloc});

  @override
  Widget build(BuildContext context) {
    return BlocProvider<CommentsBloc>(
      create: (_) =>
          (createBloc?.call() ?? CommentsBloc(muId))..add(const LoadComments()),
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
          b is CommentsLoaded && (b.lastError != null || b.feedback != null),
      listener: (context, state) {
        if (state is! CommentsLoaded) return;
        final messenger = ScaffoldMessenger.of(context);
        if (state.lastError != null) {
          messenger.showSnackBar(SnackBar(
            content: Text(userFacingErrorMessage(state.lastError, l10n)),
            backgroundColor: Theme.of(context).colorScheme.error,
          ));
        } else if (state.feedback == CommentsFeedback.reported) {
          messenger.showSnackBar(
            SnackBar(content: Text(l10n.commentsReportSuccess)),
          );
        }
      },
      builder: (context, state) {
        return Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            CommentsHeader(
              count: state is CommentsLoaded ? state.items.length : 0,
              sort: state is CommentsLoaded ? state.sort : CommentSort.recent,
              onSortChanged: (sort) => context
                  .read<CommentsBloc>()
                  .add(ChangeCommentSort(sort)),
            ),
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
                message: userFacingErrorMessage(state.error, l10n),
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

/// En-tête « Commentaires (n) » + tri (Récents / Populaires).
///
/// `Wrap` : titre à gauche et tri à droite quand ils tiennent sur une ligne ;
/// sinon (petit écran, texte agrandi, allemand) le tri passe dessous au lieu
/// d'écraser le titre, qui se cassait au milieu des mots.
class CommentsHeader extends StatelessWidget {
  final int count;
  final CommentSort sort;
  final ValueChanged<CommentSort> onSortChanged;

  const CommentsHeader({
    super.key,
    required this.count,
    required this.sort,
    required this.onSortChanged,
  });

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return Wrap(
      alignment: WrapAlignment.spaceBetween,
      crossAxisAlignment: WrapCrossAlignment.center,
      spacing: AppSpacing.s,
      runSpacing: AppSpacing.s,
      children: [
        Text(
          '${l10n.commentsTitle} ($count)',
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: Theme.of(context).textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.w700,
              ),
        ),
        // Sort toggle — 2 AppChip cliquables (cohérent avec le reste du
        // design system). Plus de SegmentedButton qui rendait orange.
        Wrap(
          spacing: AppSpacing.xs,
          runSpacing: AppSpacing.xs,
          children: [
            sort == CommentSort.recent
                ? AppChip.primary(
                    label: l10n.commentsSortRecent,
                    icon: Icons.schedule,
                  )
                : AppChip(
                    label: l10n.commentsSortRecent,
                    icon: Icons.schedule,
                    onTap: () => onSortChanged(CommentSort.recent),
                  ),
            sort == CommentSort.top
                ? AppChip.primary(
                    label: l10n.commentsSortTop,
                    icon: Icons.trending_up,
                  )
                : AppChip(
                    label: l10n.commentsSortTop,
                    icon: Icons.trending_up,
                    onTap: () => onSortChanged(CommentSort.top),
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
            // « Supprimer » : mes commentaires seulement ; « Signaler » :
            // ceux des autres (après confirmation).
            onDelete: state.isMine(comment)
                ? () =>
                    context.read<CommentsBloc>().add(DeleteComment(comment.id))
                : null,
            onReport: state.isMine(comment)
                ? null
                : () => _confirmReport(context, comment.id),
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

/// « Signaler ce commentaire ? » puis envoi.
Future<void> _confirmReport(BuildContext context, int commentId) async {
  final l10n = AppLocalizations.of(context)!;
  final bloc = context.read<CommentsBloc>();
  final confirmed = await showAppDialog<bool>(
    context: context,
    builder: (ctx) => AlertDialog(
      scrollable: true,
      title: Text(l10n.commentsReportConfirmTitle),
      content: Text(l10n.commentsReportConfirmBody),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(ctx).pop(false),
          child: Text(l10n.cancel),
        ),
        FilledButton(
          onPressed: () => Navigator.of(ctx).pop(true),
          child: Text(l10n.commentsReport),
        ),
      ],
    ),
  );
  if (confirmed == true) bloc.add(ReportComment(commentId));
}

// _ErrorBlock retiré — utilise désormais AppErrorState du design system.
