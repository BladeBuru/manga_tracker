import 'dart:convert';
import 'package:flutter/material.dart';

/// Avatar utilisateur générique du design system.
///
/// Affiche l'image depuis l'URL si fournie, sinon un fallback avec
/// l'initiale du nom sur fond `primaryContainer`. Quatre tailles :
///  - `small` (radius 14) — usage inline (search dropdown, count chip)
///  - `medium` (radius 20) — usage standard (list tiles, comment author)
///  - `large` (radius 28) — usage hero compact (inbox cards, profile header tile)
///  - `hero` (radius 48) — usage hero pleine page (édition de profil)
///
/// **À utiliser PARTOUT** où on affiche un avatar utilisateur. Aucune
/// `CircleAvatar` directe dans le code feature — toujours passer par ce
/// primitive pour garder une cohérence du fallback.
class AppAvatar extends StatelessWidget {
  final String? url;
  final String fallback;
  final AppAvatarSize size;

  const AppAvatar({
    super.key,
    required this.url,
    required this.fallback,
    this.size = AppAvatarSize.medium,
  });

  double get _radius {
    switch (size) {
      case AppAvatarSize.small:
        return 14;
      case AppAvatarSize.medium:
        return 20;
      case AppAvatarSize.large:
        return 28;
      case AppAvatarSize.hero:
        return 48;
    }
  }

  double get _fontSize {
    switch (size) {
      case AppAvatarSize.small:
        return 11;
      case AppAvatarSize.medium:
        return 14;
      case AppAvatarSize.large:
        return 18;
      case AppAvatarSize.hero:
        return 36;
    }
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final initial =
        fallback.isNotEmpty ? fallback.characters.first.toUpperCase() : '?';
    final image = _resolveImage();
    if (image != null) {
      return CircleAvatar(
        radius: _radius,
        backgroundColor: scheme.surfaceContainerHighest,
        backgroundImage: image,
        onBackgroundImageError: (_, __) {},
      );
    }
    // **Refactor 2026-05-18 (v2)** : fallback en gris neutre VISIBLE sur fond
    // surface. `surfaceContainerHigh` était quasi-blanc en light (#F0F0F4)
    // → invisible sur surface blanche. On utilise désormais `outlineVariant`
    // qui a un contraste suffisant en light comme en dark (~#CAC4D0 en
    // light Material 3, ~#49454F en dark). Le texte initial passe sur
    // `onSurface` direct pour avoir du contraste sur ce gris moyen.
    // Convention Material 3 idem WhatsApp, Google Photos, Slack pour les
    // avatars sans photo. Plus jamais de cercle rouge primary parasite.
    return CircleAvatar(
      radius: _radius,
      backgroundColor: scheme.outlineVariant,
      child: Text(
        initial,
        style: TextStyle(
          color: scheme.onSurface,
          fontWeight: FontWeight.w700,
          fontSize: _fontSize,
        ),
      ),
    );
  }

  /// Résout l'URL en `ImageProvider` :
  ///  - `data:image/jpeg;base64,...` → `MemoryImage` (image locale picker)
  ///  - `https://...` → `NetworkImage`
  ///  - vide / null / format invalide → null (fallback initial affiché)
  ///
  /// Le support des data URLs permet à `profile_edit.view.dart` de
  /// prévisualiser une photo choisie depuis la galerie (image_picker)
  /// avant qu'elle soit persistée côté API.
  ImageProvider? _resolveImage() {
    final value = url;
    if (value == null || value.isEmpty) return null;
    if (value.startsWith('data:image/')) {
      try {
        final commaIndex = value.indexOf(',');
        if (commaIndex < 0) return null;
        final bytes = base64Decode(value.substring(commaIndex + 1));
        return MemoryImage(bytes);
      } catch (_) {
        return null;
      }
    }
    if (value.startsWith('http://') || value.startsWith('https://')) {
      return NetworkImage(value);
    }
    return null;
  }
}

enum AppAvatarSize { small, medium, large, hero }
