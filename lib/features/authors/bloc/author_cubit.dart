import 'package:bloc/bloc.dart';
import 'package:equatable/equatable.dart';
import 'package:mangatracker/core/network/failure_classifier.dart';
import 'package:mangatracker/features/authors/dto/author_details.dto.dart';
import 'package:mangatracker/features/authors/services/author.service.dart';

part 'author_state.dart';

/// Page auteur : une fiche par page (instance créée par la vue, fermée avec
/// elle). Réseau d'abord, repli sur la dernière fiche connue de l'appareil.
class AuthorCubit extends Cubit<AuthorState> {
  final AuthorService _service;
  final int authorId;

  AuthorCubit({required this.authorId, AuthorService? service})
    : _service = service ?? const AuthorService(),
      super(const AuthorLoading());

  Future<void> load() async {
    if (state is! AuthorLoaded) emit(const AuthorLoading());
    try {
      final author = await _service.fetch(authorId);
      if (!isClosed) emit(AuthorLoaded(author));
    } on AuthorException catch (e) {
      if (e.failure == AuthorFailure.notFound) {
        if (!isClosed) emit(const AuthorError(notFound: true));
        return;
      }
      await _fallback(isOffline: false);
    } catch (e) {
      await _fallback(isOffline: showsOfflineIndicator(classifyFailure(e)));
    }
  }

  Future<void> _fallback({required bool isOffline}) async {
    final cached = await _service.cached(authorId);
    if (isClosed) return;
    if (cached != null) {
      emit(AuthorLoaded(cached, isOffline: isOffline));
    } else {
      emit(AuthorError(isOffline: isOffline));
    }
  }
}
