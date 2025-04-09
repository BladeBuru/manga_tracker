import 'package:flutter/widgets.dart';

class ImageHelper {
  static Image loadMangaImage(String? imagePath) {
    Image img;
    if (imagePath == null) {
      img = loadPlaceholderImage();
    } else {
      img = Image.network(
        imagePath,
        errorBuilder:
            (BuildContext context, Object error, StackTrace? stackTrace) {
          return loadPlaceholderImage();
        },
      );
    }
    return img;
  }

  static Image loadPlaceholderImage() {
    return Image.asset('assets/images/placeholders/image_placeholder.png');
  }
}
