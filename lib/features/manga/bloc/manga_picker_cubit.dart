import 'dart:async';

import 'package:bloc/bloc.dart';
import 'package:equatable/equatable.dart';
import 'package:mangatracker/core/service_locator/service_locator.dart';
import 'package:mangatracker/features/manga/dto/manga_quick_view.dto.dart';
import 'package:mangatracker/features/manga/services/manga.service.dart';

/// Recherche d'une œuvre à recommander : saisie temporisée (une requête par
/// pause de frappe), résultats de la recherche globale. Aucun historique.
class MangaPickerCubit extends Cubit<MangaPickerState> {
  static const Duration debounce = Duration(milliseconds: 450);

  final MangaService? _serviceOverride;
  Timer? _timer;
  int _generation = 0;

  MangaPickerCubit({MangaService? mangaService})
    : _serviceOverride = mangaService,
      super(const MangaPickerState());

  MangaService get _service => _serviceOverride ?? getIt<MangaService>();

  void queryChanged(String raw) {
    _timer?.cancel();
    final query = raw.trim();
    if (query.length < 2) {
      _generation++;
      emit(const MangaPickerState());
      return;
    }
    _timer = Timer(debounce, () => _search(query));
  }

  Future<void> _search(String query) async {
    final generation = ++_generation;
    emit(MangaPickerState(query: query, loading: true));
    try {
      final page = await _service.searchForMangas(query, page: 1, limit: 25);
      if (isClosed || generation != _generation) return;
      emit(MangaPickerState(query: query, results: page.results));
    } catch (_) {
      if (isClosed || generation != _generation) return;
      emit(MangaPickerState(query: query, failed: true));
    }
  }

  @override
  Future<void> close() {
    _timer?.cancel();
    return super.close();
  }
}

class MangaPickerState extends Equatable {
  final String query;
  final bool loading;
  final bool failed;
  final List<MangaQuickViewDto> results;

  const MangaPickerState({
    this.query = '',
    this.loading = false,
    this.failed = false,
    this.results = const [],
  });

  @override
  List<Object?> get props => [
    query,
    loading,
    failed,
    [for (final r in results) r.muId],
  ];
}
