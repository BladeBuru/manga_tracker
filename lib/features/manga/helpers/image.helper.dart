import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:mangatracker/core/theme/app_colors.dart';

class ImageHelper {

  // MODIFICATION 1 : Ajouter les paramètres optionnels width et height
  static Widget loadMangaImage(
      String? imagePath, {
        BoxFit fit = BoxFit.cover,
        double? width,
        double? height,
      }) {
    if (imagePath == null || imagePath.isEmpty) {
      return _skeleton(width, height);
    }

    // Utiliser CachedNetworkImage pour gérer le cache en mode offline
    return CachedNetworkImage(
      imageUrl: imagePath,
      width: width,
      height: height,
      fit: fit,
      placeholder: (context, url) => _skeleton(width, height),
      errorWidget: (context, url, error) => _skeleton(width, height),
      cacheKey: imagePath, // Utiliser l'URL comme clé de cache
    );
  }

  /// **Skeleton loader V1 (2026-05-19)** : remplace l'ancien
  /// `image_placeholder.png` (image grisée avec montagne, mauvaises
  /// proportions). Container plat couleur `dsBgInset` avec une pulsation
  /// d'opacité subtile pour signaler le chargement. Le parent (cover
  /// ClipRRect typiquement) applique son propre radius — pas besoin
  /// d'en mettre un ici.
  static Widget _skeleton(double? width, double? height) {
    return Builder(
      builder: (context) {
        final brightness = Theme.of(context).brightness;
        return _PulsingSkeleton(
          width: width,
          height: height,
          color: AppColors.dsBgInset(brightness),
        );
      },
    );
  }
}

class _PulsingSkeleton extends StatefulWidget {
  final double? width;
  final double? height;
  final Color color;

  const _PulsingSkeleton({
    required this.width,
    required this.height,
    required this.color,
  });

  @override
  State<_PulsingSkeleton> createState() => _PulsingSkeletonState();
}

class _PulsingSkeletonState extends State<_PulsingSkeleton>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  late final Animation<double> _animation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1100),
    )..repeat(reverse: true);
    // Pulsation entre 1.0 et 0.5 de l'opacité — assez subtil.
    _animation = Tween<double>(begin: 1.0, end: 0.55).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _animation,
      builder: (_, __) => Container(
        width: widget.width,
        height: widget.height,
        color: Color.lerp(widget.color, widget.color.withValues(alpha: 0.4),
            1 - _animation.value),
      ),
    );
  }
}