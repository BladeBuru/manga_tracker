import 'package:flutter/widgets.dart';

class ImageHelper {

  static Image loadMangaImage(
      String? imagePath, {
        BoxFit fit = BoxFit.cover,
      }) {
    if (imagePath == null) {
      // Placeholder, en lui passant aussi le `fit`
      return _loadPlaceholderImage(fit);
    }

    return Image.network(
      imagePath,
      fit: fit,
      errorBuilder:
          (BuildContext context, Object error, StackTrace? stackTrace) {
        return _loadPlaceholderImage(fit);
      },
    );
  }

  static Image _loadPlaceholderImage(BoxFit fit) {
    return Image.asset(
      'assets/images/placeholders/image_placeholder.png',
      fit: fit,
    );
  }
}
