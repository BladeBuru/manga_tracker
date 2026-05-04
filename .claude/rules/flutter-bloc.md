# BLoC Standards — Manga Tracker Flutter

> Snippet injecté automatiquement quand vous éditez un fichier dans `lib/.../bloc/`.

## Structure obligatoire

```
features/[feature]/bloc/
├── [feature]_bloc.dart       # class [Feature]Bloc extends Bloc<Event, State>
├── [feature]_event.dart      # part of '[feature]_bloc.dart'
└── [feature]_state.dart      # part of '[feature]_bloc.dart'
```

## Events

```dart
// Nommage : verbe à l'infinitif, descriptif
// ✅ BON
class LoadHomePage extends HomePageEvent {}
class AddToLibrary extends HomePageEvent { final String muId; }
class UpdateReadingStatus extends LibraryEvent { final ReadingStatus status; }

// ❌ MAUVAIS
class FetchData extends HomePageEvent {}
class Click extends LibraryEvent {}
```

- Toujours `extends Equatable`
- `@override List<Object?> get props` sur tous les events avec paramètres
- `const` constructors obligatoires

## States

```dart
class FeatureInitial extends FeatureState {}
class FeatureLoading extends FeatureState {}

class FeatureLoaded extends FeatureState {
  final List<MyData> data;
  final bool isOffline;        // Toujours inclure
  final int pendingActions;    // Si applicable

  const FeatureLoaded({
    required this.data,
    this.isOffline = false,
    this.pendingActions = 0,
  });

  @override
  List<Object?> get props => [data, isOffline, pendingActions];
}

class FeatureError extends FeatureState {
  final String message;
  const FeatureError(this.message);
  @override
  List<Object?> get props => [message];
}
```

## BLoC

```dart
class FeatureBloc extends Bloc<FeatureEvent, FeatureState> {
  final FeatureService _featureService;
  final CacheHelperService _cacheHelper;

  FeatureBloc({
    required FeatureService featureService,
    required CacheHelperService cacheHelper,
  })  : _featureService = featureService,
        _cacheHelper = cacheHelper,
        super(FeatureInitial()) {
    on<LoadFeature>(_onLoadFeature);
  }

  Future<void> _onLoadFeature(LoadFeature event, Emitter<FeatureState> emit) async {
    emit(FeatureLoading());
    try {
      final data = await _featureService.getData();
      emit(FeatureLoaded(data: data));
    } on SocketException {
      final cached = await _cacheHelper.getCachedData();
      emit(FeatureLoaded(data: cached, isOffline: true));
    } catch (e) {
      emit(FeatureError(e.toString()));
    }
  }
}
```

## Enregistrement GetIt

```dart
// Lazy singleton (HomePageBloc, LibraryBloc)
getIt.registerLazySingleton<HomePageBloc>(
  () => HomePageBloc(
    mangaService: getIt<MangaService>(),
    cacheHelper: getIt<CacheHelperService>(),
  ),
);

// Factory (DetailBloc — OBLIGATOIRE pour éviter les race conditions)
getIt.registerFactory<DetailBloc>(
  () => DetailBloc(
    libraryService: getIt<LibraryService>(),
    mangaService: getIt<MangaService>(),
  ),
);
```

## Utilisation dans les views

```dart
class FeatureBlocView extends StatelessWidget {
  const FeatureBlocView({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<FeatureBloc, FeatureState>(
      builder: (context, state) {
        return switch (state) {
          FeatureLoading() => const Center(child: CircularProgressIndicator()),
          FeatureLoaded(:final data, :final isOffline) => _FeatureContent(
              data: data,
              isOffline: isOffline,
            ),
          FeatureError(:final message) => _FeatureError(message: message),
          _ => const SizedBox.shrink(),
        };
      },
    );
  }
}
```

## Limite

**MAX 200 lignes** par BLoC. Si dépassement → extraire les handlers en méthodes privées ou helpers.

## Anti-patterns INTERDITS

- ❌ Accès BuildContext dans un BLoC
- ❌ Navigation dans un BLoC (utiliser des streams ou callbacks)
- ❌ Logique UI dans un BLoC
- ❌ Un BLoC qui gère plusieurs features indépendantes
- ❌ States sans `Equatable`
- ❌ `emit()` après `await` sans vérifier `isClosed`
