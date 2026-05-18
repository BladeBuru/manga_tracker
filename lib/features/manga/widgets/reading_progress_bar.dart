import 'package:flutter/material.dart';
import 'package:mangatracker/core/theme/app_colors.dart';
import 'package:mangatracker/l10n/app_localizations.dart';

/// Barre de progression V1 « Refined Classic » utilisée dans la bibliothèque.
///
/// - Track : `dsBgInset(brightness)` (gris subtil).
/// - Fill : `colorScheme.primary` (rouge thème).
/// - Compteur `read / total` à droite, tabular figures pour alignement.
/// - Hauteur 5px, radius 999 (pill shape).
/// - Wrappé dans Semantics pour TalkBack/VoiceOver.
class ReadingProgressBar extends StatelessWidget {
  final num readChapter;
  final num lastChapter;

  const ReadingProgressBar({
    super.key,
    required this.readChapter,
    required this.lastChapter,
  });

  @override
  Widget build(BuildContext context) {
    final brightness = Theme.of(context).brightness;
    final scheme = Theme.of(context).colorScheme;
    final l10n = AppLocalizations.of(context);
    final read = readChapter.toInt();
    final total = lastChapter.toInt();
    final ratio = total > 0 ? (read / total).clamp(0.0, 1.0) : 0.0;

    return Semantics(
      label: l10n?.libraryProgressLabel(read, total) ?? '$read / $total',
      child: Row(
        children: [
          Expanded(
            child: ClipRRect(
              borderRadius: BorderRadius.circular(999),
              child: LinearProgressIndicator(
                value: ratio,
                minHeight: 5,
                backgroundColor: AppColors.dsBgInset(brightness),
                valueColor: AlwaysStoppedAnimation<Color>(scheme.primary),
              ),
            ),
          ),
          const SizedBox(width: 8),
          Text(
            '$read / $total',
            style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w700,
              color: AppColors.dsText2(brightness),
              fontFeatures: const [FontFeature.tabularFigures()],
            ),
          ),
        ],
      ),
    );
  }
}
