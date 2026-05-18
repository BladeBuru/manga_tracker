import 'package:bloc/bloc.dart';
import 'package:equatable/equatable.dart';
import 'package:mangatracker/core/service_locator/service_locator.dart';
import 'package:mangatracker/features/comments/dto/comment.dto.dart';
import 'package:mangatracker/features/comments/services/comments.service.dart';

part 'comments_event.dart';
part 'comments_state.dart';

/// BLoC des commentaires d'une page détail manga (Phase 7.1).
///
/// Une instance par muId (créée via `CommentsBloc(muId)` directement, ou
/// via `BlocProvider` au mount de `CommentsSection`). Pas de singleton —
/// chaque manga a son propre stream de commentaires.
class CommentsBloc extends Bloc<CommentsEvent, CommentsState> {
  final CommentsService _service = getIt<CommentsService>();
  final int muId;

  CommentsBloc(this.muId) : super(const CommentsInitial()) {
    on<LoadComments>(_onLoad);
    on<LoadMoreComments>(_onLoadMore);
    on<PostComment>(_onPost);
    on<EditComment>(_onEdit);
    on<DeleteComment>(_onDelete);
    on<ChangeCommentSort>(_onChangeSort);
  }

  Future<void> _onLoad(LoadComments event, Emitter<CommentsState> emit) async {
    emit(const CommentsLoading());
    try {
      final page = await _service.listForManga(muId, sort: event.sort);
      emit(CommentsLoaded(
        items: page.items,
        currentPage: page.page,
        hasMore: page.hasMore,
        sort: event.sort,
      ));
    } catch (e) {
      emit(CommentsError(e.toString()));
    }
  }

  Future<void> _onLoadMore(
    LoadMoreComments event,
    Emitter<CommentsState> emit,
  ) async {
    if (state is! CommentsLoaded) return;
    final current = state as CommentsLoaded;
    if (!current.hasMore || current.isLoadingMore) return;

    emit(current.copyWith(isLoadingMore: true));
    try {
      final next = await _service.listForManga(
        muId,
        page: current.currentPage + 1,
        sort: current.sort,
      );
      emit(current.copyWith(
        items: [...current.items, ...next.items],
        currentPage: next.page,
        hasMore: next.hasMore,
        isLoadingMore: false,
      ));
    } catch (_) {
      emit(current.copyWith(isLoadingMore: false));
    }
  }

  Future<void> _onPost(PostComment event, Emitter<CommentsState> emit) async {
    if (state is! CommentsLoaded) return;
    final current = state as CommentsLoaded;
    try {
      final created = event.parentCommentId == null
          ? await _service.create(
              muId,
              content: event.content,
              rating: event.rating,
            )
          : await _service.reply(
              event.parentCommentId!,
              content: event.content,
              rating: event.rating,
            );
      // On insère en tête pour donner un feedback immédiat.
      emit(current.copyWith(items: [created, ...current.items]));
    } catch (e) {
      emit(current.copyWith(lastError: e.toString()));
    }
  }

  Future<void> _onEdit(EditComment event, Emitter<CommentsState> emit) async {
    if (state is! CommentsLoaded) return;
    final current = state as CommentsLoaded;
    try {
      final updated = await _service.update(
        event.commentId,
        content: event.content,
        rating: event.rating,
      );
      emit(current.copyWith(
        items: current.items
            .map((c) => c.id == event.commentId ? updated : c)
            .toList(),
      ));
    } catch (e) {
      emit(current.copyWith(lastError: e.toString()));
    }
  }

  Future<void> _onDelete(
    DeleteComment event,
    Emitter<CommentsState> emit,
  ) async {
    if (state is! CommentsLoaded) return;
    final current = state as CommentsLoaded;
    try {
      await _service.delete(event.commentId);
      // Soft delete côté serveur : on update le item local pour refléter.
      emit(current.copyWith(
        items: current.items.map((c) {
          if (c.id != event.commentId) return c;
          return CommentDto(
            id: c.id,
            content: '[supprimé]',
            rating: null,
            authorId: c.authorId,
            authorUsername: c.authorUsername,
            authorDisplayName: c.authorDisplayName,
            authorAvatarUrl: c.authorAvatarUrl,
            parentCommentId: c.parentCommentId,
            isDeleted: true,
            replyCount: c.replyCount,
            createdAt: c.createdAt,
            updatedAt: DateTime.now(),
          );
        }).toList(),
      ));
    } catch (e) {
      emit(current.copyWith(lastError: e.toString()));
    }
  }

  Future<void> _onChangeSort(
    ChangeCommentSort event,
    Emitter<CommentsState> emit,
  ) async {
    add(LoadComments(sort: event.sort));
  }
}
