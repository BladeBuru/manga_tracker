import 'package:flutter/material.dart';
import 'package:mangatracker/core/theme/app_colors.dart';
import 'package:mangatracker/core/theme/app_radius.dart';
import 'package:mangatracker/core/theme/app_spacing.dart';
import 'package:mangatracker/l10n/app_localizations.dart';

// ╔═══════════════════════════════════════════════════════════════════════╗
// ║  DetailInfoCard — V1 « Refined Classic » (v4 — 2026-05-19).           ║
// ║                                                                       ║
// ║  Matrice fusionnée 3 lignes × 2 colonnes dans UNE SEULE card.         ║
// ║  Hairlines internes verticales + horizontales créant le quadrillage   ║
// ║  (exactement le dessin envoyé par l'user).                            ║
// ║                                                                       ║
// ║  Icônes : TOUTES en `primary` (rouge thème app) — fini le pastel      ║
// ║  multi-couleurs qui rendait visuellement confus.                      ║
// ║                                                                       ║
// ║  Profondeur : ombre élevée (0 4px 12px -2px rgba(20,10,10,0.10)) pour ║
// ║  détacher la card du fond de page `dsBg`.                             ║
// ║                                                                       ║
// ║  Pairing :                                                            ║
// ║    [📖 CHAPITRES · 280]  [⭐ NOTE · 8.18]                              ║
// ║    [ⓘ STATUT · En cours] [📅 ANNÉE · 2020]                            ║
// ║    [👤 AUTEUR · ...]      [🎨 ARTISTE · ...]      (fusion plein-w si  ║
// ║                                                    auteur == artiste) ║
// ╚═══════════════════════════════════════════════════════════════════════╝

class DetailInfoCard extends StatelessWidget {
  final num? totalChapters;
  final String rating;
  final bool? isCompleted;
  final String year;
  final List<String> authors;
  final List<String> artists;

  const DetailInfoCard({
    super.key,
    required this.totalChapters,
    required this.rating,
    required this.isCompleted,
    required this.year,
    required this.authors,
    required this.artists,
  });

  @override
  Widget build(BuildContext context) {
    final brightness = Theme.of(context).brightness;
    final isDark = brightness == Brightness.dark;
    final l10n = AppLocalizations.of(context);

    final authorsList = authors.where((a) => a.trim().isNotEmpty).toList();
    final artistsList = artists.where((a) => a.trim().isNotEmpty).toList();
    final mergeAuthorArtist = authorsList.isNotEmpty &&
        artistsList.isNotEmpty &&
        _namesEqual(authorsList, artistsList);

    final chaptersCount = totalChapters?.toInt() ?? 0;
    final hasChapters = chaptersCount > 0;
    final hasRating = rating.trim().isNotEmpty &&
        rating.trim() != '0' &&
        rating.trim() != '0.0';
    final hasStatus = isCompleted != null;
    final hasYear = year.trim().isNotEmpty && year.trim() != '0';
    final hasAuthor = authorsList.isNotEmpty;
    final hasArtist = artistsList.isNotEmpty;

    final c1 = _Cell(
      icon: Icons.menu_book_outlined,
      label: l10n?.chapters ?? 'Chapitres',
      value: hasChapters ? '$chaptersCount' : '—',
      muted: !hasChapters,
    );
    final c2 = _Cell(
      icon: Icons.star_outline_rounded,
      label: l10n?.rating ?? 'Note',
      value: hasRating ? rating : '—',
      muted: !hasRating,
    );
    final c3 = _Cell(
      icon: Icons.info_outline_rounded,
      label: l10n?.status ?? 'Statut',
      value: hasStatus
          ? (isCompleted == true
              ? (l10n?.completed ?? 'Terminé')
              : (l10n?.reading ?? 'En cours'))
          : '—',
      muted: !hasStatus,
      // Statut "En cours" en primary pour signaler visuellement.
      valueAccent: hasStatus && isCompleted == false,
    );
    final c4 = _Cell(
      icon: Icons.calendar_today_outlined,
      label: l10n?.year ?? 'Année',
      value: hasYear ? year : '—',
      muted: !hasYear,
    );

    Widget row3;
    if (mergeAuthorArtist) {
      row3 = _Cell(
        icon: Icons.person_outline_rounded,
        label:
            '${l10n?.author ?? 'Auteur'} · ${l10n?.artist ?? 'Artiste'}',
        value: authorsList.join(', '),
      );
    } else {
      row3 = _MatrixRow(
        brightness: brightness,
        left: _Cell(
          icon: Icons.person_outline_rounded,
          label: l10n?.author ?? 'Auteur',
          value: hasAuthor ? authorsList.join(', ') : '—',
          muted: !hasAuthor,
        ),
        right: _Cell(
          icon: Icons.palette_outlined,
          label: l10n?.artist ?? 'Artiste',
          value: hasArtist ? artistsList.join(', ') : '—',
          muted: !hasArtist,
        ),
      );
    }

    return Padding(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.m,
        vertical: AppSpacing.s,
      ),
      child: Container(
        decoration: BoxDecoration(
          color: isDark ? AppColors.dsSurfaceDark : Colors.white,
          borderRadius: BorderRadius.circular(AppRadius.xxxl),
          border: Border.all(
            color: AppColors.dsHairline(brightness),
            width: 1,
          ),
          // **Profondeur** (refonte v4) : ombre plus marquée pour détacher
          // la card du fond `dsBg` (peachy off-white). Le user a explicitement
          // demandé un effet de profondeur — ombre 12px-2 spread.
          boxShadow: isDark
              ? null
              : const [
                  BoxShadow(
                    color: Color(0x14140A0A), // rgba(20,10,10,0.08)
                    blurRadius: 12,
                    spreadRadius: -2,
                    offset: Offset(0, 4),
                  ),
                ],
        ),
        clipBehavior: Clip.antiAlias,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            _MatrixRow(left: c1, right: c2, brightness: brightness),
            _hLine(brightness),
            _MatrixRow(left: c3, right: c4, brightness: brightness),
            _hLine(brightness),
            row3,
          ],
        ),
      ),
    );
  }

  Widget _hLine(Brightness b) => Container(
        height: 1,
        color: AppColors.dsHairline(b),
      );
}

bool _namesEqual(List<String> a, List<String> b) {
  if (a.length != b.length) return false;
  final sortedA = [...a]..sort();
  final sortedB = [...b]..sort();
  for (int i = 0; i < sortedA.length; i++) {
    if (sortedA[i].toLowerCase() != sortedB[i].toLowerCase()) return false;
  }
  return true;
}

/// Ligne de la matrice : 2 cellules séparées par une hairline verticale.
class _MatrixRow extends StatelessWidget {
  final Widget left;
  final Widget right;
  final Brightness brightness;

  const _MatrixRow({
    required this.left,
    required this.right,
    required this.brightness,
  });

  @override
  Widget build(BuildContext context) {
    return IntrinsicHeight(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Expanded(child: left),
          Container(
            width: 1,
            color: AppColors.dsHairline(brightness),
          ),
          Expanded(child: right),
        ],
      ),
    );
  }
}

/// Cellule individuelle de la matrice.
///
/// Layout :
/// ```
/// [icon-red 16px] LABEL UPPERCASE 10.5px text-3
///                 valeur 15px w700 onSurface
/// ```
class _Cell extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;
  final bool muted;
  final bool valueAccent;

  const _Cell({
    required this.icon,
    required this.label,
    required this.value,
    this.muted = false,
    this.valueAccent = false,
  });

  @override
  Widget build(BuildContext context) {
    final brightness = Theme.of(context).brightness;
    final scheme = Theme.of(context).colorScheme;
    // Icône TOUJOURS rouge primary (consigne user — fini le pastel multi-color).
    // Légèrement assoupli si la valeur est manquante (muted) pour cohérence.
    final iconColor =
        muted ? AppColors.dsText3(brightness) : scheme.primary;
    final valueColor = muted
        ? AppColors.dsText3(brightness)
        : (valueAccent ? scheme.primary : scheme.onSurface);
    return Padding(
      padding: const EdgeInsets.fromLTRB(14, 12, 14, 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.center,
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            children: [
              Icon(icon, size: 15, color: iconColor),
              const SizedBox(width: 6),
              Flexible(
                child: Text(
                  label.toUpperCase(),
                  style: TextStyle(
                    fontSize: 10.5,
                    fontWeight: FontWeight.w600,
                    letterSpacing: 0.63,
                    color: AppColors.dsText3(brightness),
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
          const SizedBox(height: 4),
          Text(
            value,
            style: TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.w700,
              letterSpacing: -0.15,
              color: valueColor,
              height: 1.2,
            ),
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );
  }
}
