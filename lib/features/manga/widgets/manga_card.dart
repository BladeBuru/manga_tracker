import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:html/parser.dart';
import 'package:mangatracker/core/components/refreshable_manga_image.dart';
import 'package:mangatracker/core/router/app_router.dart';
import 'package:mangatracker/core/theme/app_colors.dart';
import 'package:mangatracker/core/theme/app_radius.dart';
import 'package:mangatracker/features/download/services/download_manager_service.dart';

class MangaCard extends StatelessWidget {
  final String mangaTitle;
  final String muId;
  final String mangaAuthor;
  final String? mediumImgPath;
  final String? rating;
  final num? lastChapter;
  final num? readChapter;
  final bool showDownloadedOnly; // Nouveau paramètre

  /// Mode "compact bibliothèque" V1 (Phase mai 2026).
  /// Quand `true` :
  ///   - Progression `read/total` affichée en **overlay blanc sur le bottom
  ///     de la cover** (au lieu d'une pill séparée sous la card)
  ///   - **Pas d'année, pas de note d'étoile** → carte plus compacte, focus
  ///     sur la cover + le progrès. Source : `screen-library.jsx` (VariantAGrid)
  /// Default `false` → comportement inchangé pour Home / Recos / Détail.
  final bool compactLibrary;

  const MangaCard({
    super.key,
    required this.mangaTitle,
    required this.muId,
    required this.mangaAuthor,
    this.mediumImgPath,
    this.rating,
    this.lastChapter,
    this.readChapter,
    this.showDownloadedOnly = false, // Par défaut false
    this.compactLibrary = false,
  });

  /// `true` si on a une vraie année (≠ "0" ni "0.0" ni vide) à afficher.
  bool _hasValidYear() {
    final y = mangaAuthor.trim();
    return y.isNotEmpty && y != '0' && y != '0.0' && y != 'null';
  }

  /// `true` si rating est exploitable (≠ N/A, ≠ 0).
  bool _hasValidRating() {
    final r = rating;
    if (r == null || r.isEmpty) return false;
    return r != 'N/A' && r != '0' && r != '0.0';
  }

  /// Au moins une des 2 infos doit exister pour rendre la row meta.
  bool _hasYearOrRating() => _hasValidYear() || _hasValidRating();

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () async {
        // Vérifier s'il y a des chapitres téléchargés ET si le filtre est activé
        if (showDownloadedOnly) {
          final downloadManager = DownloadManagerService();
          final downloadedChapters = await downloadManager.getDownloadedChapters(int.parse(muId));
          
          if (downloadedChapters.isNotEmpty && context.mounted) {
            // Trier les chapitres téléchargés par numéro
            final sortedChapters = downloadedChapters.toList()..sort((a, b) => a.chapterNumber.compareTo(b.chapterNumber));
            
            // Déterminer le chapitre à ouvrir : priorité au prochain chapitre non lu ou reprise de lecture
            int targetChapterNumber;
            if (readChapter != null && readChapter! > 0) {
              final lastReadChapterNum = readChapter!.toInt();
              
              // Vérifier d'abord si le dernier chapitre lu est téléchargé et a une position de scroll sauvegardée
              final lastReadChapter = sortedChapters.where(
                (ch) => ch.chapterNumber == lastReadChapterNum && ch.scrollPosition != null && ch.scrollPosition! > 0,
              ).firstOrNull;
              
              if (lastReadChapter != null) {
                // Reprendre la lecture du dernier chapitre lu là où on s'est arrêté
                targetChapterNumber = lastReadChapterNum;
              } else {
                // Chercher le prochain chapitre non lu (dernier lu + 1)
                final nextChapter = lastReadChapterNum + 1;
                final nextChapterDownloaded = sortedChapters.where(
                  (ch) => ch.chapterNumber == nextChapter,
                ).firstOrNull;
                
                if (nextChapterDownloaded != null) {
                  // Le prochain chapitre est téléchargé, l'utiliser
                  targetChapterNumber = nextChapter;
                } else {
                  // Sinon, chercher le chapitre téléchargé le plus proche après le dernier lu
                  final nextAvailable = sortedChapters.where(
                    (ch) => ch.chapterNumber > lastReadChapterNum,
                  ).firstOrNull;
                  targetChapterNumber = nextAvailable?.chapterNumber ?? sortedChapters.first.chapterNumber;
                }
              }
            } else {
              // Aucun chapitre lu, ouvrir le premier téléchargé
              targetChapterNumber = sortedChapters.first.chapterNumber;
            }
            
            // En mode téléchargé uniquement, utiliser directement le titre fourni
            // pour éviter toute requête réseau qui pourrait ralentir ou échouer
            if (context.mounted) {
              await context.push(
                '/manga/$muId/read-offline?chapter=$targetChapterNumber',
                extra: OfflineReaderExtras(mangaTitle: mangaTitle),
              );
              return;
            }
          }
        }

        // Sinon, aller sur le détail normal
        if (!context.mounted) return;
        context.push(
          '/manga/$muId',
          extra: MangaDetailExtras(title: mangaTitle, coverPath: mediumImgPath),
        );
      },
      child: SizedBox(
        width: double.infinity,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            // ── Cover (avec overlay progress si compactLibrary) ───
            Container(
              height: 160,
              width: double.infinity,
              decoration: BoxDecoration(
                borderRadius: AppRadius.circularXl,
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.2),
                    blurRadius: 8,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: ClipRRect(
                borderRadius: AppRadius.circularXl,
                child: Stack(
                  fit: StackFit.expand,
                  children: [
                    // useProxy: true (hotfix-v0-10-1 US-2) — l'URL MU brute
                    // est bloquée par CORS sur le web ; le proxy gère les
                    // deux plateformes (302 mobile, stream web).
                    RefreshableMangaImage(
                      muId: muId,
                      originalUrl: mediumImgPath,
                      width: double.infinity,
                      height: 160,
                      useProxy: true,
                    ),
                    if (compactLibrary && lastChapter != null)
                      _ProgressOverlay(
                        readChapter: readChapter,
                        lastChapter: lastChapter!,
                      ),
                  ],
                ),
              ),
            ),
            // **Fix 2026-05-19** : barre de progression V1 sous la cover en mode
            // compactLibrary (en plus de l'overlay texte sur la cover). Visuel
            // satisfaisant pour voir la progression d'un coup d'œil.
            if (compactLibrary &&
                lastChapter != null &&
                lastChapter! > 0) ...[
              const SizedBox(height: 4),
              _LibraryProgressBar(
                read: readChapter ?? 0,
                total: lastChapter!,
              ),
            ],
            // **Fix 2026-05-19** : titre rapproché de la cover en mode compact
            // (gap 3 au lieu de 5-6) puisqu'on a viré l'année + rating.
            SizedBox(
              height: compactLibrary ? 3 : (lastChapter != null ? 5 : 6),
            ),
            // ── Titre ───
            Expanded(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 4.0),
                child: Align(
                  alignment: Alignment.centerLeft,
                  child: Text(
                    parseFragment(mangaTitle).text!,
                    style: Theme.of(context).textTheme.titleSmall?.copyWith(
                      fontSize: lastChapter != null ? 12 : 14,
                      height: 1.2,
                    ),
                    overflow: TextOverflow.ellipsis,
                    maxLines: 2,
                  ),
                ),
              ),
            ),
            // ── Sous le titre : pill chapitre (mode home/recos seulement) ───
            if (lastChapter != null && !compactLibrary) ...[
              const SizedBox(height: 3),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 4.0),
                child: Container(
                  decoration: BoxDecoration(
                    borderRadius: AppRadius.circularSm,
                    color:
                        Theme.of(context).colorScheme.surfaceContainerHighest,
                  ),
                  child: Padding(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 5, vertical: 2),
                    child: Text(
                      readChapter != null
                          ? '$readChapter / ${lastChapter ?? 0} ${lastChapter! > 1 ? "chapitres" : "chapitre"}'
                          : '${lastChapter ?? 0} ${lastChapter! > 1 ? "chapitres" : "chapitre"}',
                      overflow: TextOverflow.ellipsis,
                      maxLines: 1,
                      style:
                          Theme.of(context).textTheme.labelSmall?.copyWith(
                                color: Colors.orange,
                                fontWeight: FontWeight.bold,
                                fontSize: 9,
                              ),
                    ),
                  ),
                ),
              ),
            ],
            // ── Année + rating (mode home/recos seulement) ───
            // **Fix 2026-05-19** : skip toute la row si année="0"/"" ET rating
            // absent — l'API renvoie 0/null pour les stubs (manga pas encore
            // détaillé). Avant on affichait "0" tout seul, parasite visuel.
            if (!compactLibrary && _hasYearOrRating()) ...[
              SizedBox(height: lastChapter != null ? 3 : 4),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 4.0),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    if (_hasValidYear())
                      Expanded(
                        child: Text(
                          mangaAuthor,
                          style:
                              Theme.of(context).textTheme.bodySmall?.copyWith(
                                    fontSize: lastChapter != null ? 9 : 10,
                                  ),
                          overflow: TextOverflow.ellipsis,
                          maxLines: 1,
                        ),
                      )
                    else
                      const Spacer(),
                    if (rating != null &&
                        rating!.isNotEmpty &&
                        rating != 'N/A' &&
                        rating != '0' &&
                        rating != '0.0') ...[
                      const SizedBox(width: 4),
                      Icon(
                        Icons.star,
                        color: Theme.of(context).colorScheme.primary,
                        size: lastChapter != null ? 10 : 11,
                      ),
                      const SizedBox(width: 2),
                      Text(
                        rating!,
                        style: TextStyle(
                          color: Theme.of(context).colorScheme.primary,
                          fontSize: lastChapter != null ? 9 : 10,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

/// Overlay au bas de la cover en mode `compactLibrary` :
/// gradient noir + texte blanc `read / total` (ou "Terminé" si lu == total).
/// Source visuelle : `screen-library.jsx` VariantAGrid lignes 270-280.
class _ProgressOverlay extends StatelessWidget {
  final num? readChapter;
  final num lastChapter;

  const _ProgressOverlay({
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
class _LibraryProgressBar extends StatelessWidget {
  final num read;
  final num total;

  const _LibraryProgressBar({required this.read, required this.total});

  @override
  Widget build(BuildContext context) {
    final brightness = Theme.of(context).brightness;
    final scheme = Theme.of(context).colorScheme;
    final ratio = total > 0 ? (read / total).clamp(0.0, 1.0).toDouble() : 0.0;
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 4),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(999),
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

