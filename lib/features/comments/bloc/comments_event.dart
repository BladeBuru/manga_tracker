part of 'comments_bloc.dart';

abstract class CommentsEvent extends Equatable {
  const CommentsEvent();
  @override
  List<Object?> get props => [];
}

class LoadComments extends CommentsEvent {
  final CommentSort sort;
  const LoadComments({this.sort = CommentSort.recent});
  @override
  List<Object?> get props => [sort];
}

class LoadMoreComments extends CommentsEvent {
  const LoadMoreComments();
}

class PostComment extends CommentsEvent {
  final String content;
  final int? rating;
  final int? parentCommentId;
  const PostComment({
    required this.content,
    this.rating,
    this.parentCommentId,
  });
  @override
  List<Object?> get props => [content, rating, parentCommentId];
}

class EditComment extends CommentsEvent {
  final int commentId;
  final String content;
  final int? rating;
  const EditComment({
    required this.commentId,
    required this.content,
    this.rating,
  });
  @override
  List<Object?> get props => [commentId, content, rating];
}

class DeleteComment extends CommentsEvent {
  final int commentId;
  const DeleteComment(this.commentId);
  @override
  List<Object?> get props => [commentId];
}

class ChangeCommentSort extends CommentsEvent {
  final CommentSort sort;
  const ChangeCommentSort(this.sort);
  @override
  List<Object?> get props => [sort];
}
