import 'dart:convert';

import 'package:flutter/material.dart';

import 'package:mangatracker/core/theme/app_colors.dart';

// ╔═══════════════════════════════════════════════════════════════════════╗
// ║  ProfileHeader — version refondue (Design System V1).                 ║
// ║  Avatar centré 88px sur fond `dsBgInset`, border `dsHairline`, avec   ║
// ║  fallback icône utilisateur. Username 19px weight 800 + email 13px.   ║
// ║  Pas de gradient rouge — clean.                                       ║
// ║                                                                       ║
// ║  Source design : `.claude-design/manga-tracker/project/screen-       ║
// ║  account.jsx` (lignes 17-39).                                        ║
// ╚═══════════════════════════════════════════════════════════════════════╝

class ProfileHeader extends StatelessWidget {
  final String username;
  final String email;
  final String? avatarUrl;
  final VoidCallback? onAvatarTap;

  const ProfileHeader({
    super.key,
    required this.username,
    required this.email,
    this.avatarUrl,
    this.onAvatarTap,
  });

  @override
  Widget build(BuildContext context) {
    final brightness = Theme.of(context).brightness;
    final scheme = Theme.of(context).colorScheme;

    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 22),
      child: Column(
        children: [
          GestureDetector(
            onTap: onAvatarTap,
            child: Container(
              width: 88,
              height: 88,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: AppColors.dsBgInset(brightness),
                border: Border.all(
                  color: AppColors.dsHairline(brightness),
                  width: 1,
                ),
              ),
              alignment: Alignment.center,
              child: _buildAvatarContent(brightness),
            ),
          ),
          const SizedBox(height: 10),
          Text(
            username,
            style: TextStyle(
              fontSize: 19,
              fontWeight: FontWeight.w800,
              letterSpacing: -0.285, // -0.015em * 19
              color: scheme.onSurface,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            email,
            style: TextStyle(
              fontSize: 13,
              fontFeatures: const [FontFeature.tabularFigures()],
              color: AppColors.dsText2(brightness),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAvatarContent(Brightness brightness) {
    // **Fix 2026-05-18** : supporte data URLs (image_picker base64) ET
    // URLs http(s). `Image.network` ne sait pas afficher les data: URIs
    // → fallback silencieux. Logique alignée sur `AppAvatar._resolveImage`.
    final provider = _resolveImage();
    if (provider != null) {
      return ClipOval(
        child: Image(
          image: provider,
          fit: BoxFit.cover,
          width: 88,
          height: 88,
          errorBuilder: (_, __, ___) => _buildFallbackIcon(brightness),
        ),
      );
    }
    return _buildFallbackIcon(brightness);
  }

  ImageProvider? _resolveImage() {
    final v = avatarUrl;
    if (v == null || v.isEmpty) return null;
    if (v.startsWith('data:image/')) {
      // Format : data:image/jpeg;base64,XXXX  → on isole la partie base64.
      final commaIdx = v.indexOf(',');
      if (commaIdx == -1) return null;
      try {
        return MemoryImage(base64Decode(v.substring(commaIdx + 1)));
      } catch (_) {
        return null;
      }
    }
    if (v.startsWith('http://') || v.startsWith('https://')) {
      return NetworkImage(v);
    }
    return null;
  }

  Widget _buildFallbackIcon(Brightness brightness) {
    return Icon(
      Icons.person_outline,
      size: 40,
      color: AppColors.dsText3(brightness),
    );
  }
}
