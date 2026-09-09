import 'package:flutter/material.dart';
import 'package:mangatracker/core/service_locator/service_locator.dart';
import 'package:mangatracker/core/services/library_index_service.dart';

/// Fournit a son enfant l'ensemble des `muId` deja en bibliotheque, et le
/// reconstruit quand cet ensemble change (ajout depuis une fiche, retrait,
/// synchronisation de la bibliotheque, deconnexion).
///
/// Cout reseau **nul** : l'index derive du cache local `cached_library`
/// (cf. [LibraryIndexService]). Si le service n'est pas disponible (tests
/// widget sans service locator), l'ensemble est simplement vide : les cartes
/// s'affichent sans indicateur au lieu de planter.
class LibraryOwnedIdsBuilder extends StatefulWidget {
  final Widget Function(BuildContext context, Set<int> ownedMuIds) builder;

  const LibraryOwnedIdsBuilder({super.key, required this.builder});

  @override
  State<LibraryOwnedIdsBuilder> createState() => _LibraryOwnedIdsBuilderState();
}

class _LibraryOwnedIdsBuilderState extends State<LibraryOwnedIdsBuilder> {
  LibraryIndexService? _index;

  @override
  void initState() {
    super.initState();
    try {
      _index = getIt<LibraryIndexService>()..ensureLoaded();
    } catch (_) {
      _index = null;
    }
  }

  @override
  Widget build(BuildContext context) {
    final index = _index;
    if (index == null) return widget.builder(context, const <int>{});
    return ValueListenableBuilder<Set<int>>(
      valueListenable: index.listenable,
      builder: (context, ownedMuIds, _) => widget.builder(context, ownedMuIds),
    );
  }
}
