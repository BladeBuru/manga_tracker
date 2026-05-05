import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:mangatracker/core/service_locator/service_locator.dart';
import 'package:mangatracker/features/manga/helpers/image.helper.dart';
import 'package:mangatracker/features/manga/services/manga.service.dart';

/// Image de cover qui auto-rafraîchit l'URL quand la requête échoue (URL
/// périmée côté MangaUpdates). Au premier 404, appelle
/// `MangaService.refreshCover(muId)` (1× max par 5min) puis rebuild avec la
/// nouvelle URL.
///
/// Utilisé par `MangaCard` et `MangaRow` (et tout autre call site qui doit
/// afficher une cover potentiellement périmée). Le cooldown statique
/// [_refreshCooldown] est partagé entre tous les call sites pour éviter de
/// spammer l'endpoint `/mangas/:muId/refresh-cover` quand plusieurs widgets
/// avec le même muId périmé sont à l'écran simultanément.
///
/// Si pas de muId valide ou pas d'URL, fallback sur le placeholder de
/// [ImageHelper].
class RefreshableMangaImage extends StatefulWidget {
  final String muId;
  final String? originalUrl;
  final double? width;
  final double? height;
  final BoxFit fit;

  const RefreshableMangaImage({
    super.key,
    required this.muId,
    required this.originalUrl,
    this.width,
    this.height,
    this.fit = BoxFit.cover,
  });

  /// Cooldown global (5min par muId) — partagé entre TOUS les call sites
  /// pour throttle proprement les retries quand la même URL périmée est
  /// affichée à plusieurs endroits (Card + Row d'une même bibliothèque).
  static final Map<int, DateTime> _refreshCooldown = <int, DateTime>{};
  static const Duration _refreshCooldownDuration = Duration(minutes: 5);

  @override
  State<RefreshableMangaImage> createState() => _RefreshableMangaImageState();
}

class _RefreshableMangaImageState extends State<RefreshableMangaImage> {
  String? _currentUrl;
  bool _refreshing = false;

  @override
  void initState() {
    super.initState();
    _currentUrl = widget.originalUrl;
  }

  @override
  void didUpdateWidget(covariant RefreshableMangaImage old) {
    super.didUpdateWidget(old);
    if (old.originalUrl != widget.originalUrl) {
      _currentUrl = widget.originalUrl;
    }
  }

  Future<void> _attemptRefresh() async {
    if (_refreshing) return;
    final muIdInt = int.tryParse(widget.muId);
    if (muIdInt == null || muIdInt <= 0) return;

    final lastTry = RefreshableMangaImage._refreshCooldown[muIdInt];
    if (lastTry != null &&
        DateTime.now().difference(lastTry) <
            RefreshableMangaImage._refreshCooldownDuration) {
      return;
    }
    RefreshableMangaImage._refreshCooldown[muIdInt] = DateTime.now();
    _refreshing = true;
    try {
      final fresh = await getIt<MangaService>().refreshCover(muIdInt);
      if (!mounted) return;
      final newUrl = fresh.mediumCoverUrl ?? fresh.smallCoverUrl;
      if (newUrl != null && newUrl.isNotEmpty && newUrl != _currentUrl) {
        setState(() => _currentUrl = newUrl);
      }
    } catch (_) {
      // Silencieux : on garde le placeholder, retry possible dans 5min.
    } finally {
      _refreshing = false;
    }
  }

  Widget _placeholder() => ImageHelper.loadMangaImage(
        null,
        width: widget.width,
        height: widget.height,
        fit: widget.fit,
      );

  @override
  Widget build(BuildContext context) {
    final url = _currentUrl;
    if (url == null || url.isEmpty) {
      return _placeholder();
    }
    return CachedNetworkImage(
      key: ValueKey(url),
      imageUrl: url,
      width: widget.width,
      height: widget.height,
      fit: widget.fit,
      cacheKey: url,
      placeholder: (_, __) => _placeholder(),
      errorWidget: (_, __, ___) {
        // Trigger un refresh asynchrone (1× par 5min). On n'attend pas :
        // le rebuild se fera via setState quand la nouvelle URL arrive.
        WidgetsBinding.instance.addPostFrameCallback((_) => _attemptRefresh());
        return _placeholder();
      },
    );
  }
}
