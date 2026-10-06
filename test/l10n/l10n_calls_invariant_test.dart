import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

/// Fil de détente : une traduction à paramètre (`pendingActions(count)`)
/// utilisée sans être appelée s'affiche « Closure: (int) => String… » —
/// arrivé en production sur le bandeau hors ligne. Ce test lit le source.
void main() {
  test('toute traduction à paramètre est appelée', () {
    final generated =
        File('lib/l10n/app_localizations.dart').readAsStringSync();
    final methods = RegExp(r'^\s*String (\w+)\(', multiLine: true)
        .allMatches(generated)
        .map((m) => m.group(1)!)
        .toSet();
    expect(methods, isNotEmpty);

    final pattern = RegExp(
      r'(?:l10n|AppLocalizations\.of\(\w+\))[!?]?\.('
      '${methods.join('|')}'
      r')\b(?!\s*\()',
    );
    final offenders = <String>[];
    for (final file in Directory('lib').listSync(recursive: true)) {
      if (file is! File || !file.path.endsWith('.dart')) continue;
      if (file.path.startsWith('lib/l10n/')) continue;
      final lines = file.readAsLinesSync();
      for (var i = 0; i < lines.length; i++) {
        if (pattern.hasMatch(lines[i])) offenders.add('${file.path}:${i + 1}');
      }
    }
    expect(offenders, isEmpty);
  });
}
