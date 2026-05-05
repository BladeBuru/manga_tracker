import 'package:cached_network_image/cached_network_image.dart';
import 'package:html/parser.dart';
import '../helpers/image.helper.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:mangatracker/core/router/app_router.dart';
import 'package:mangatracker/core/service_locator/service_locator.dart';
import 'package:mangatracker/core/theme/app_radius.dart';
import 'package:mangatracker/features/download/services/download_manager_service.dart';
import 'package:mangatracker/features/manga/services/manga.service.dart';

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
  });

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
        await context.push(
          '/manga/$muId',
          extra: MangaDetailExtras(title: mangaName, coverPath: mediumImgPath),
        );
        if (onDetailReturn != null) {
          onDetailReturn!();
        }
      },
      child: Padding(
        padding: const EdgeInsets.only(
            top: 0.0, bottom: 20.0, right: 2.0, left: 2.0),
        child: Container(
          decoration: BoxDecoration(
            color: Theme.of(context).colorScheme.surface,
            borderRadius: AppRadius.circularXl,
            boxShadow: [
              BoxShadow(
                color: Theme.of(context).colorScheme.shadow.withValues(alpha: 0.1),
                spreadRadius: 1,
                blurRadius: 8,
                offset: const Offset(0, 2),
              ),
              BoxShadow(
                color: Theme.of(context).colorScheme.shadow.withValues(alpha: 0.05),
                spreadRadius: 0,
                blurRadius: 4,
                offset: const Offset(0, 1),
              ),
            ],
          ),
          child: IntrinsicHeight(
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                ClipRRect(
                  borderRadius: BorderRadius.only(
                    topLeft: Radius.circular(AppRadius.xl),
                    bottomLeft: Radius.circular(AppRadius.xl),
                  ),
                  child: Stack(
                    children: [
                      SizedBox(
                        width: 80,
                        height: 100,
                        child: _RefreshableRowImage(
                          muId: muId,
                          originalUrl: mediumImgPath,
                          width: 80,
                          height: 100,
                          fit: BoxFit.cover,
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
                          Container(
                            decoration: BoxDecoration(
                              borderRadius: AppRadius.circularLg,
                              color: Theme.of(context).colorScheme.surfaceContainerHighest,
                            ),
                            child: Padding(
                              padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 1),
                              child: Text(
                                readChapter != null
                                    ? '$readChapter / ${lastChapter ?? 0} ${lastChapter! > 1 ? "chapitres" : "chapitre"}'
                                    : '${lastChapter ?? 0} ${lastChapter! > 1 ? "chapitres" : "chapitre"}',
                                overflow: TextOverflow.ellipsis,
                                style: Theme.of(context).textTheme.labelSmall?.copyWith(
                                  color: Colors.orange,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),
                ),
                if (rating != null)
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
}

/// Cooldown global (5min par muId) — partagé avec [_RefreshableMangaImage]
/// dans `manga_card.dart` mais via une instance distincte (pas critique :
/// un double appel par muId / page reste tolérable et reste throttle côté
/// API par le cooldown serveur).
final Map<int, DateTime> _rowCoverRefreshCooldown = {};
const Duration _rowCoverRefreshCooldownDuration = Duration(minutes: 5);

/// Cf. [_RefreshableMangaImage] dans `manga_card.dart` — version pour le
/// row qui utilise les mêmes dimensions que la cover row (80×100).
class _RefreshableRowImage extends StatefulWidget {
  final String muId;
  final String? originalUrl;
  final double? width;
  final double? height;
  final BoxFit fit;

  const _RefreshableRowImage({
    required this.muId,
    required this.originalUrl,
    this.width,
    this.height,
    this.fit = BoxFit.cover,
  });

  @override
  State<_RefreshableRowImage> createState() => _RefreshableRowImageState();
}

class _RefreshableRowImageState extends State<_RefreshableRowImage> {
  String? _currentUrl;
  bool _refreshing = false;

  @override
  void initState() {
    super.initState();
    _currentUrl = widget.originalUrl;
  }

  @override
  void didUpdateWidget(covariant _RefreshableRowImage old) {
    super.didUpdateWidget(old);
    if (old.originalUrl != widget.originalUrl) {
      _currentUrl = widget.originalUrl;
    }
  }

  Future<void> _attemptRefresh() async {
    if (_refreshing) return;
    final muIdInt = int.tryParse(widget.muId);
    if (muIdInt == null || muIdInt <= 0) return;

    final lastTry = _rowCoverRefreshCooldown[muIdInt];
    if (lastTry != null &&
        DateTime.now().difference(lastTry) <
            _rowCoverRefreshCooldownDuration) {
      return;
    }
    _rowCoverRefreshCooldown[muIdInt] = DateTime.now();
    _refreshing = true;
    try {
      final fresh = await getIt<MangaService>().refreshCover(muIdInt);
      if (!mounted) return;
      final newUrl = fresh.mediumCoverUrl ?? fresh.smallCoverUrl;
      if (newUrl != null && newUrl.isNotEmpty && newUrl != _currentUrl) {
        setState(() => _currentUrl = newUrl);
      }
    } catch (_) {
      // Silencieux.
    } finally {
      _refreshing = false;
    }
  }

  @override
  Widget build(BuildContext context) {
    final url = _currentUrl;
    if (url == null || url.isEmpty) {
      return ImageHelper.loadMangaImage(
        null,
        width: widget.width,
        height: widget.height,
        fit: widget.fit,
      );
    }
    return CachedNetworkImage(
      key: ValueKey(url),
      imageUrl: url,
      width: widget.width,
      height: widget.height,
      fit: widget.fit,
      cacheKey: url,
      placeholder: (_, __) => ImageHelper.loadMangaImage(
        null,
        width: widget.width,
        height: widget.height,
        fit: widget.fit,
      ),
      errorWidget: (_, __, ___) {
        WidgetsBinding.instance.addPostFrameCallback((_) => _attemptRefresh());
        return ImageHelper.loadMangaImage(
          null,
          width: widget.width,
          height: widget.height,
          fit: widget.fit,
        );
      },
    );
  }
}
