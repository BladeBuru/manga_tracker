part of 'reading_groups_bloc.dart';

/// BLoC dédié à la page détail d'un groupe (polling 30s).
///
/// Au mount : LoadDetail + démarrage du polling. Le polling se contente de
/// re-fetch le groupe pour récupérer la progression à jour des autres
/// membres — et ne tourne que tant que la page est affichée
/// ([GroupDetailVisibilityChanged]) : chaque page de groupe empilée gardait
/// avant le sien.
///
/// La progression d'un groupe = celle de chaque membre dans SA bibliothèque
/// (il n'existe pas de progression « du groupe » côté API) : « Ma
/// progression » s'enregistre donc comme sur la fiche du manga
/// (`PUT /library/chapter`, utilisateur courant), puis le groupe est relu.
class ReadingGroupDetailBloc
    extends Bloc<ReadingGroupDetailEvent, ReadingGroupDetailState> {
  final ReadingGroupsService _service;
  final ChapterProgressService? _progressOverride;
  final int groupId;

  /// Intervalle du rafraîchissement périodique.
  final Duration pollInterval;

  Timer? _pollTimer;
  bool _visible = true;
  bool _fetching = false;
  int _attempt = 0;

  ReadingGroupDetailBloc(
    this.groupId, {
    ReadingGroupsService? service,
    ChapterProgressService? progressService,
    this.pollInterval = const Duration(seconds: 30),
  }) : _service = service ?? getIt<ReadingGroupsService>(),
       _progressOverride = progressService,
       super(const ReadingGroupDetailInitial()) {
    on<LoadGroupDetail>(_onLoad);
    on<PollGroupDetail>(_onPoll);
    on<GroupDetailVisibilityChanged>(_onVisibilityChanged);
    on<UpdateMyGroupProgress>(_onUpdateMyProgress);
    on<DeleteGroupRequested>(_onDelete);
  }

  ChapterProgressService get _progress =>
      _progressOverride ?? getIt<ChapterProgressService>();

  Future<void> _onLoad(
    LoadGroupDetail event,
    Emitter<ReadingGroupDetailState> emit,
  ) async {
    emit(const ReadingGroupDetailLoading());
    try {
      final group = await _service.getGroup(groupId);
      emit(ReadingGroupDetailLoaded(group: group));
      _startPolling();
    } catch (e) {
      emit(ReadingGroupDetailError(e.toString()));
    }
  }

  Future<void> _onPoll(
    PollGroupDetail event,
    Emitter<ReadingGroupDetailState> emit,
  ) async {
    if (state is! ReadingGroupDetailLoaded || _fetching) return;
    _fetching = true;
    try {
      final group = await _service.getGroup(groupId);
      // Relire l'état APRÈS l'attente : un enregistrement a pu commencer.
      final latest = state;
      if (latest is! ReadingGroupDetailLoaded) return;
      emit(ReadingGroupDetailLoaded(
        group: group,
        isSavingProgress: latest.isSavingProgress,
      ));
    } catch (_) {
      // Erreur silencieuse pendant le poll — on garde la dernière vue valide.
    } finally {
      _fetching = false;
    }
  }

  void _onVisibilityChanged(
    GroupDetailVisibilityChanged event,
    Emitter<ReadingGroupDetailState> emit,
  ) {
    _visible = event.visible;
    if (!event.visible) {
      _pollTimer?.cancel();
      return;
    }
    // De retour sur la page : relire tout de suite (la progression a pu
    // changer sur la fiche du manga), puis reprendre la minuterie.
    if (state is ReadingGroupDetailLoaded) {
      add(const PollGroupDetail());
      _startPolling();
    }
  }

  Future<void> _onUpdateMyProgress(
    UpdateMyGroupProgress event,
    Emitter<ReadingGroupDetailState> emit,
  ) async {
    final current = state;
    if (current is! ReadingGroupDetailLoaded || current.isSavingProgress) {
      return;
    }
    final muId = int.tryParse(current.group.mangaMuId);
    if (muId == null || muId <= 0) return;
    emit(ReadingGroupDetailLoaded(group: current.group, isSavingProgress: true));

    // Geste explicite : au-delà du total connu, on signale (comme un tap sur
    // un chapitre de la fiche) ; titre absent de la bibliothèque, on l'ajoute.
    final result = await _progress.save(
      muId,
      event.readChapters,
      autoReportIfAboveTotal: true,
      addToLibraryIfMissing: true,
      origin: this,
    );
    if (isClosed) return;

    var group = current.group;
    if (result.isAppliedOnServer) {
      try {
        group = await _service.getGroup(groupId);
      } catch (_) {
        // Relecture impossible : la minuterie s'en chargera.
      }
    }
    if (isClosed) return;
    final latest = state;
    if (!result.isAppliedOnServer && latest is ReadingGroupDetailLoaded) {
      group = latest.group;
    }
    emit(ReadingGroupProgressUpdated(
      group: group,
      readChapters: event.readChapters,
      result: result,
      attempt: ++_attempt,
    ));
  }

  Future<void> _onDelete(
    DeleteGroupRequested event,
    Emitter<ReadingGroupDetailState> emit,
  ) async {
    final current = state;
    if (current is! ReadingGroupDetailLoaded) return;
    try {
      _pollTimer?.cancel();
      await _service.deleteGroup(groupId);
      emit(const ReadingGroupDetailDeleted());
    } catch (e) {
      emit(ReadingGroupDetailDeleteFailed(
        group: current.group,
        message: e.toString(),
      ));
      // On reprend l'affichage normal — l'UI a déjà reçu le signal d'échec.
      emit(ReadingGroupDetailLoaded(group: current.group));
      _startPolling();
    }
  }

  void _startPolling() {
    _pollTimer?.cancel();
    if (!_visible) return;
    _pollTimer = Timer.periodic(pollInterval, (_) {
      if (!isClosed && _visible) add(const PollGroupDetail());
    });
  }

  @override
  Future<void> close() {
    _pollTimer?.cancel();
    return super.close();
  }
}
