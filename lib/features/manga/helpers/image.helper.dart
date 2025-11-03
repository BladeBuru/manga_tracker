import 'package:flutter/widgets.dart';
import 'package:cached_network_image/cached_network_image.dart';

class ImageHelper {

  // MODIFICATION 1 : Ajouter les paramètres optionnels width et height
  static Widget loadMangaImage(
      String? imagePath, {
        BoxFit fit = BoxFit.cover,
        double? width,
        double? height,
      }) {
    if (imagePath == null || imagePath.isEmpty) {
      // On passe aussi width et height au placeholder
      return _loadPlaceholderImage(fit, width, height);
    }

    // Utiliser CachedNetworkImage pour gérer le cache en mode offline
    return CachedNetworkImage(
      imageUrl: imagePath,
      width: width,
      height: height,
      fit: fit,
      placeholder: (context, url) => _loadPlaceholderImage(fit, width, height),
      errorWidget: (context, url, error) => _loadPlaceholderImage(fit, width, height),
      cacheKey: imagePath, // Utiliser l'URL comme clé de cache
    );
  }

  static Widget _loadPlaceholderImage(BoxFit fit, double? width, double? height) {
    return Image.asset(
      'assets/images/placeholders/image_placeholder.png',
      width: width,
      height: height,
      fit: fit,
    );
  }
}