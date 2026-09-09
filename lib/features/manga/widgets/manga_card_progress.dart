import 'package:flutter/material.dart';
import 'package:mangatracker/core/theme/app_colors.dart';
import 'package:mangatracker/core/theme/app_radius.dart';

// Extraits de `manga_card.dart` (2026-09-09) : le fichier depassait la
// limite de 400 lignes du projet. Rien d'autre n'a change — memes visuels,
// memes valeurs.

/// Overlay au bas de la cover en mode `compactLibrary` :
/// gradient noir + texte blanc `read / total` (ou "Terminé" si lu == total).
/// Source visuelle : `screen-library.jsx` VariantAGrid lignes 270-280.
class MangaCardProgressOverlay extends StatelessWidget {
  final num? readChapter;
  final num lastChapter;

  const MangaCardProgressOverlay({
    super.key,
    required this.readChapter,
    required this.lastChapter,
  });

  @override
  Widget build(BuildContext context) {
    final read = readChapter ?? 0;
    final isFinished = read >= lastChapter && lastChapter > 0;
    return Positioned(
      left: 0,
      right: 0,
      bottom: 0,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              Color(0x00000000),
              Color(0xCC000000), // ~80 % opaque en bas pour la lisibilité
            ],
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (isFinished) ...[
              const Icon(Icons.check_circle, color: Colors.white, size: 11),
              const SizedBox(width: 4),
              const Text(
                'Terminé',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 10,
                  fontWeight: FontWeight.w700,
                  fontFeatures: [FontFeature.tabularFigures()],
                ),
              ),
            ] else
              Text(
                '$read / $lastChapter',
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 10.5,
                  fontWeight: FontWeight.w700,
                  letterSpacing: 0.2,
                  fontFeatures: [FontFeature.tabularFigures()],
                ),
              ),
          ],
        ),
      ),
    );
  }
}

/// Barre de progression linéaire affichée sous la cover en mode
/// `compactLibrary`. Track `dsBgInset`, fill `primary`. Hauteur 4px,
/// fully rounded. Pas de texte (le compteur est déjà dans l'overlay
/// blanc sur la cover).
class MangaCardProgressBar extends StatelessWidget {
  final num read;
  final num total;

  const MangaCardProgressBar({
    super.key,
    required this.read,
    required this.total,
  });

  @override
  Widget build(BuildContext context) {
    final brightness = Theme.of(context).brightness;
    final scheme = Theme.of(context).colorScheme;
    final ratio = total > 0 ? (read / total).clamp(0.0, 1.0).toDouble() : 0.0;
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 4),
      child: ClipRRect(
        borderRadius: AppRadius.circularFull,
        child: LinearProgressIndicator(
          value: ratio,
          minHeight: 4,
          backgroundColor: AppColors.dsBgInset(brightness),
          valueColor: AlwaysStoppedAnimation<Color>(scheme.primary),
        ),
      ),
    );
  }
}

