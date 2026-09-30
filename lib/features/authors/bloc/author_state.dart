part of 'author_cubit.dart';

sealed class AuthorState extends Equatable {
  const AuthorState();

  @override
  List<Object?> get props => [];
}

class AuthorLoading extends AuthorState {
  const AuthorLoading();
}

class AuthorLoaded extends AuthorState {
  final AuthorDetailsDto author;

  /// La fiche vient du cache de l'appareil (réseau indisponible).
  final bool isOffline;

  const AuthorLoaded(this.author, {this.isOffline = false});

  @override
  List<Object?> get props => [author.id, author.works.length, isOffline];
}

class AuthorError extends AuthorState {
  final bool notFound;
  final bool isOffline;

  const AuthorError({this.notFound = false, this.isOffline = false});

  @override
  List<Object?> get props => [notFound, isOffline];
}
