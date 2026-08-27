import 'package:html/parser.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:mangatracker/core/components/refreshable_manga_image.dart';
import 'package:mangatracker/core/router/app_router.dart';
import 'package:mangatracker/core/theme/app_colors.dart';
import 'package:mangatracker/core/theme/app_radius.dart';
import 'package:mangatracker/features/download/services/download_manager_service.dart';
import 'package:mangatracker/features/manga/widgets/reading_progress_bar.dart';
import 'package:mangatracker/l10n/app_localizations.dart';

class MangaRow extends StatelessWidget {
  final String mangaName;
  final String muId;
  final String mangaAuthor;
  final num? lastChapter;
  final num? readChapter;
  final String? mediumImgPath;
  final String? rating;
  final VoidCallback? onDetailReturn;
  final bool hasNewChapters;
  final int? newChaptersCount;
  final bool showDownloadedOnly; // Nouveau paramètre
  // Si la recherche utilisateur matche un titre alternatif (ex: "Naruto" pour
  // un manga dont le titre principal est "ナルト") on affiche le titre alt
  // sous le titre principal pour que l'utilisateur reconnaisse pourquoi le
  // résultat sort.
  final String? searchQuery;
  final List<String>? associatedTitles;

  /// V1 "Refined Classic" : si `true`, remplace la pill `X / Y chapitres`
  /// par une barre de progression linéaire + compteur (style bibliothèque).
  /// Default `false` : conserve l'ancienne pill pour Home / Search /
  /// Recommandations qui restent inchangés.
  final bool showProgressBar;

  const MangaRow({
    super.key,
    required this.mangaName,
    required this.muId,
    required this.mangaAuthor,
    this.lastChapter,
    this.readChapter,
    this.rating,
    this.mediumImgPath,
    this.onDetailReturn,
    this.hasNewChapters = false,
    this.newChaptersCount,
    this.showDownloadedOnly = false, // Par défaut false
    this.searchQuery,
    this.associatedTitles,
    this.showProgressBar = false,
  });

  /// Retourne le 1er titre alternatif qui matche la query, ou null si :
  /// - pas de query / pas d'aliases
  /// - le titre principal matche déjà la query (pas besoin de doublon)
  String? _matchedAlias() {
    final q = searchQuery?.trim().toLowerCase();
    if (q == null || q.isEmpty) return null;
    if (mangaName.toLowerCase().contains(q)) return null;
    final aliases = associatedTitles;
    if (aliases == null || aliases.isEmpty) return null;
    for (final alias in aliases) {
      if (alias.toLowerCase().contains(q)) return alias;
    }
    return null;
  }

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
                extra: OfflineReaderExtras(mangaTitle: mangaName),
              );
              if (onDetailReturn != null) {
                onDetailReturn!();
              }
              return;
            }
          }
        }

        // Sinon, aller sur le détail normal
        if (!context.mounted) return;
        await context.push(
          '/manga/$muId',
          extra: MangaDetailExtras(title: mangaName, coverPath: mediumImgPath),
        );
        if (onDetailReturn != null) {
          onDetailReturn!();
        }
      },
      child: Padding(
        // **Refactor 2026-05-18** : densité réduite. Espacement vertical 10
        // (au lieu de 20) pour des résultats plus denses, plus design.
        padding: const EdgeInsets.only(
            top: 0.0, bottom: 10.0, right: 0.0, left: 0.0),
        child: Container(
          decoration: BoxDecoration(
            // **Refactor V1 "Refined Classic"** : surface blanche/dsSurfaceDark
            // + hairline border 1px au lieu d'une lourde ombre double Material
            // 3. Cohérent avec ProfileEditSection / InboxShareTile / etc.
            color: Theme.of(context).brightness == Brightness.dark
                ? AppColors.dsSurfaceDark
                : Colors.white,
            borderRadius: AppRadius.circularXxxl, // 16, comme cards V1
            border: Border.all(
              color: AppColors.dsHairline(Theme.of(context).brightness),
              width: 1,
            ),
            boxShadow: Theme.of(context).brightness == Brightness.dark
                ? null
                : const [
                    BoxShadow(
                      color: Color(0x0A140A0A), // rgba(20,10,10,0.04)
                      blurRadius: 2,
                      offset: Offset(0, 1),
                    ),
                  ],
          ),
          clipBehavior: Clip.antiAlias,
          child: IntrinsicHeight(
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                ClipRRect(
                  borderRadius: BorderRadius.only(
                    topLeft: Radius.circular(AppRadius.xxxl),
                    bottomLeft: Radius.circular(AppRadius.xxxl),
                  ),
                  child: Stack(
                    children: [
                      SizedBox(
                        // **Density tweak** : cover 70×96 (au lieu de 80×100)
                        // pour gagner un peu d'espace horizontal sans rogner
                        // la lisibilité.
                        width: 70,
                        height: 96,
                        child: RefreshableMangaImage(
                          muId: muId,
                          originalUrl: mediumImgPath,
                          width: 70,
                          height: 96,
                          // Phase 4 : proxy stable côté API.
                          useProxy: true,
                          proxySize: 'small',
                        ),
                      ),
                      // Badge pour nouveaux chapitres
                      if (hasNewChapters)
                        Positioned(
                          top: 4,
                          right: 4,
                          child: Container(
                            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                            decoration: BoxDecoration(
                              color: Theme.of(context).colorScheme.error,
                              borderRadius: BorderRadius.circular(12),
                              boxShadow: [
                                BoxShadow(
                                  color: Theme.of(context).colorScheme.shadow.withValues(alpha: 0.3),
                                  blurRadius: 4,
                                  offset: const Offset(0, 2),
                                ),
                              ],
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(
                                  Icons.fiber_new,
                                  color: Theme.of(context).colorScheme.onError,
                                  size: 14,
                                ),
                                if (newChaptersCount != null && newChaptersCount! > 0) ...[
                                  const SizedBox(width: 2),
                                  Text(
                                    newChaptersCount.toString(),
                                    style: TextStyle(
                                      color: Theme.of(context).colorScheme.onError,
                                      fontSize: 10,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ],
                              ],
                            ),
                          ),
                        ),
                    ],
                  ),
                ),
                Expanded(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 15.0, vertical: 12.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisAlignment: MainAxisAlignment.center,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          parseFragment(mangaName).text!,
                          overflow: TextOverflow.fade,
                          maxLines: 1,
                          softWrap: false,
                          style: const TextStyle(
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        // Affiche le titre alternatif qui matche la recherche
                        // (ex: "Naruto" affiché sous "ナルト" si l'user cherche "Naruto")
                        if (_matchedAlias() != null) ...[
                          const SizedBox(height: 2),
                          Text(
                            parseFragment(_matchedAlias()!).text!,
                            overflow: TextOverflow.ellipsis,
                            maxLines: 1,
                            style: TextStyle(
                              fontStyle: FontStyle.italic,
                              fontSize: 12,
                              color: Theme.of(context).colorScheme.primary.withValues(alpha: 0.85),
                            ),
                          ),
                        ],
                        const SizedBox(height: 5),
                        Text(
                          mangaAuthor,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.6),
                            fontWeight: FontWeight.w300,
                          ),
                        ),
                        if (lastChapter != null) ...[
                          const SizedBox(height: 7),
                          _buildProgressIndicator(context),
                        ],
                      ],
                    ),
                  ),
                ),
                if (rating != null && rating!.isNotEmpty && rating != 'N/A' && rating != '0' && rating != '0.0')
                  Padding(
                    padding: const EdgeInsets.only(right: 12.0),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(Icons.star, color: Theme.of(context).colorScheme.primary, size: 14),
                            const SizedBox(width: 2),
                            Text(
                              rating!,
                              style: Theme.of(context).textTheme.labelSmall?.copyWith(
                                color: Theme.of(context).colorScheme.onSurface,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  /// Choisit l'indicateur de progression à afficher selon `showProgressBar`.
  Widget _buildProgressIndicator(BuildContext context) {
    if (showProgressBar &&
        readChapter != null &&
        lastChapter != null &&
        lastChapter! > 0) {
      return ReadingProgressBar(
        readChapter: readChapter!,
        lastChapter: lastChapter!,
      );
    }
    return _buildChapterPill(context);
  }

  /// Ancien indicateur — pill rouge soft. Conservé pour Home / Search /
  /// Recommandations (default `showProgressBar = false`).
  ///
  /// Utilise `chaptersCount` (ICU plural i18n) qui formate déjà "N chapitres" /
  /// "N chapitre". Pour le format "read / total chapitres" on prend la chaîne
  /// totale formatée et on préfixe `readChapter /`.
  Widget _buildChapterPill(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final total = (lastChapter ?? 0).toInt();
    // chaptersCount déjà localisé (ex: "208 chapitres", "1 chapter", "208話")
    final formattedTotal = l10n?.chaptersCount(total) ?? '$total chapitres';
    final text = readChapter != null
        ? '$readChapter / $formattedTotal'
        : formattedTotal;
    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(999),
        color: AppColors.dsRedSoft(Theme.of(context).brightness),
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
        child: Text(
          text,
          overflow: TextOverflow.ellipsis,
          style: TextStyle(
            fontSize: 11,
            fontWeight: FontWeight.w700,
            color: Theme.of(context).colorScheme.primary,
          ),
        ),
      ),
    );
  }
}


