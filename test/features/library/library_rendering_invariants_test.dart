import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

/// Fil de détente : la bibliothèque « clignotait » (retour utilisateur
/// 2026-09) parce que son rendu dépendait de `Future` créés PENDANT le
/// rendu. Chaque reconstruction — frappe dans la recherche, simple appui
/// dans le champ, ouverture du clavier, geste retour prédictif maintenu —
/// remplaçait la liste par un indicateur de chargement puis rechargeait
/// toutes les couvertures.
///
/// Si ce test casse, c'est l'invariant qu'on casse, pas le test : calculer
/// les données hors du rendu (BLoC, `initState`, action utilisateur).
void main() {
  const files = [
    'lib/features/library/views/library_bloc_view.dart',
    'lib/features/library/widgets/library_list_view.dart',
    'lib/features/library/widgets/library_grid_view.dart',
  ];

  for (final path in files) {
    test('$path : aucun FutureBuilder dans le rendu de la bibliothèque', () {
      final source = File(path).readAsStringSync();
      expect(RegExp(r'FutureBuilder\s*[<(]').hasMatch(source), isFalse);
    });
  }

  test('les lignes et cartes portent une clé stable (muId)', () {
    for (final path in files.skip(1)) {
      final source = File(path).readAsStringSync();
      expect(
        source.contains('key: ValueKey(manga.muId)'),
        isTrue,
        reason: path,
      );
    }
  });

  test('la recherche ignore les notifications sans changement de texte', () {
    final source = File(files.first).readAsStringSync();
    expect(source.contains('if (query == _searchQuery) return;'), isTrue);
  });
}
