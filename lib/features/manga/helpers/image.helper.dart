import 'package:flutter/widgets.dart';

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

    return Image.network(
      imagePath,

      width: width,
      height: height,
      fit: fit,
      errorBuilder:
          (BuildContext context, Object error, StackTrace? stackTrace) {
        // On passe aussi width et height au placeholder en cas d'erreur
        return _loadPlaceholderImage(fit, width, height);
      },
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