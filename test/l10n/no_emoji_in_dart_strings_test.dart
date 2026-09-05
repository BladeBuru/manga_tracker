import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

/// Garde-fou anti-régression : aucun émoji ne doit apparaître dans un
/// littéral de chaîne visible par l'utilisateur (`lib/**/*.dart`). L'UI
/// utilise de vraies icônes Material (`Icons.*`), pas des émojis.
///
/// Approche pragmatique (pas un vrai parseur Dart) : on ignore les lignes
/// de commentaire (`//`, `///`) et les lignes qui font partie d'un appel de
/// log (`debugPrint(`, `print(`, `Logger`, `console.log(` — ce dernier pour
/// le JS injecté dans les WebView) puisque ces textes ne sont jamais
/// affichés à l'utilisateur. On regarde aussi la ligne précédente pour
/// couvrir le style `debugPrint(\n  '...',\n);` très utilisé dans ce repo.
void main() {
  test('lib/**/*.dart ne contient aucun émoji dans un texte visible', () {
    final emojiPattern = RegExp(
      r'\p{Extended_Pictographic}|\u{FE0F}|\u{200D}',
      unicode: true,
    );
    final logCallPattern = RegExp(
      r'debugPrint|print\(|Logger|console\.log\(',
    );

    final libDir = Directory('lib');
    expect(libDir.existsSync(), isTrue, reason: 'Dossier lib/ introuvable');

    final offenders = <String>[];

    for (final entity in libDir.listSync(recursive: true)) {
      if (entity is! File || !entity.path.endsWith('.dart')) continue;

      final lines = entity.readAsLinesSync();
      for (var i = 0; i < lines.length; i++) {
        final line = lines[i];
        if (!emojiPattern.hasMatch(line)) continue;

        final trimmed = line.trim();
        if (trimmed.startsWith('//') || trimmed.startsWith('///')) continue;

        // Fenêtre = ligne courante + jusqu'à 2 lignes précédentes, pour
        // couvrir les appels de log multi-lignes (opener sur une ligne,
        // chaîne sur la suivante).
        final windowStart = i - 2 < 0 ? 0 : i - 2;
        final window = lines.sublist(windowStart, i + 1).join('\n');
        if (logCallPattern.hasMatch(window)) continue;

        offenders.add('${entity.path}:${i + 1}: $trimmed');
      }
    }

    expect(
      offenders,
      isEmpty,
      reason:
          'Émoji(s) trouvé(s) dans du texte visible — remplacer par une '
          'vraie icône Material (Icons.*_outlined) rendue par un widget :\n'
          '${offenders.join('\n')}',
    );
  });
}
