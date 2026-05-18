import 'package:flutter/material.dart';
import 'package:mangatracker/core/theme/app_colors.dart';
import 'package:mangatracker/core/theme/app_radius.dart';
import 'package:mangatracker/core/theme/app_spacing.dart';

// ╔═══════════════════════════════════════════════════════════════════════╗
// ║  LibrarySection — V1 « Refined Classic » collapsible card.            ║
// ║  Source : .claude-design/manga-tracker/project/screen-library.jsx     ║
// ║           (CollapsibleSection).                                         ║
// ║  Remplace l'ExpansionTile rouge agressif (border red + shadow red)    ║
// ║  par une card hairline neutre, alignée sur ProfileEditSection.        ║
// ╚═══════════════════════════════════════════════════════════════════════╝

/// Section repliable du design V1 utilisée dans la bibliothèque.
///
/// - Carte blanche (`Colors.white` / `dsSurfaceDark`)
/// - Hairline 1px (`dsHairline`)
/// - Ombre ultra-subtile en light mode
/// - Header tappable avec :
///   - label uppercase tracké (fontSize 11, weight 700, letterSpacing 0.88)
///   - badge compteur en pill `dsBgInset` / `dsText3`
///   - chevron qui tourne à 180° quand ouvert
/// - Contenu séparé du header par un hairline divider
/// - Animation d'expansion 200ms
class LibrarySection extends StatelessWidget {
  /// Libellé de la section (ex: "EN COURS"). Sera affiché en uppercase.
  final String label;

  /// Nombre d'items dans la section (affiché dans le badge compteur).
  final int count;

  /// État d'expansion contrôlé par le parent.
  final bool isExpanded;

  /// Callback déclenché quand l'utilisateur tape sur le header.
  /// Reçoit le nouvel état d'expansion (true = ouvert, false = fermé).
  final ValueChanged<bool> onExpansionChanged;

  /// Contenu de la section, affiché uniquement quand `isExpanded == true`.
  final Widget child;

  const LibrarySection({
    super.key,
    required this.label,
    required this.count,
    required this.isExpanded,
    required this.onExpansionChanged,
    required this.child,
  });

  @override
  Widget build(BuildContext context) {
    final brightness = Theme.of(context).brightness;
    final isDark = brightness == Brightness.dark;

    return Container(
      decoration: BoxDecoration(
        color: isDark ? AppColors.dsSurfaceDark : Colors.white,
        borderRadius: BorderRadius.circular(AppRadius.xxxl),
        border: Border.all(
          color: AppColors.dsHairline(brightness),
          width: 1,
        ),
        boxShadow: isDark
            ? null
            : const [
                BoxShadow(
                  color: Color(0x0A140A0A), // rgba(20,10,10,0.04)
                  blurRadius: 2,
                  offset: Offset(0, 1),
                ),
              ],
      ),
      clipBehavior: Clip.antiAlias,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _LibrarySectionHeader(
            label: label,
            count: count,
            isExpanded: isExpanded,
            onTap: () => onExpansionChanged(!isExpanded),
          ),
          // **Fix 2026-05-18** : `AnimatedSize` + swap Column/SizedBox était
          // saccadé. `AnimatedCrossFade` gère SIMULTANÉMENT taille + opacité
          // → transition visiblement smooth en 250ms. `sizeCurve` easeInOutCubic
          // pour un slide naturel, `firstCurve`/`secondCurve` fade rapide
          // pour ne pas voir le contenu disparaître brutalement.
          AnimatedCrossFade(
            duration: const Duration(milliseconds: 250),
            sizeCurve: Curves.easeInOutCubic,
            firstCurve: Curves.easeOut,
            secondCurve: Curves.easeIn,
            crossFadeState: isExpanded
                ? CrossFadeState.showFirst
                : CrossFadeState.showSecond,
            firstChild: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Container(
                  height: 1,
                  color: AppColors.dsHairline(brightness),
                ),
                child,
              ],
            ),
            secondChild: const SizedBox(width: double.infinity, height: 0),
          ),
        ],
      ),
    );
  }
}

/// Header tappable d'une LibrarySection. Privé volontairement.
class _LibrarySectionHeader extends StatelessWidget {
  final String label;
  final int count;
  final bool isExpanded;
  final VoidCallback onTap;

  const _LibrarySectionHeader({
    required this.label,
    required this.count,
    required this.isExpanded,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final brightness = Theme.of(context).brightness;
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.symmetric(
            horizontal: AppSpacing.m,
            vertical: 14,
          ),
          // **Fix 2026-05-18** : `Expanded(Row(label+badge))` + chevron force
          // le chevron toujours flush right, quelle que soit la longueur du
          // label (FR/EN/DE peuvent varier). Avant, `Flexible` + `Spacer()`
          // donnait un chevron pseudo-flottant qui semblait "au milieu".
          child: Row(
            children: [
              Expanded(
                child: Row(
                  children: [
                    Flexible(
                      child: Text(
                        label.toUpperCase(),
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w700,
                          letterSpacing: 0.88, // 0.08em × 11px
                          color: AppColors.dsText2(brightness),
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    const SizedBox(width: AppSpacing.s),
                    _CountBadge(count: count),
                  ],
                ),
              ),
              const SizedBox(width: AppSpacing.s),
              // Chevron toujours flush right + rotation 180° quand ouvert.
              // Wrap dans un Container 24×24 pour aligner avec autres chevrons
              // de l'app (ProfileMenuRow utilise size 18 sans container, mais
              // ici on veut un hitbox élargi car toute la row est tappable).
              AnimatedRotation(
                turns: isExpanded ? 0.5 : 0,
                duration: const Duration(milliseconds: 250),
                curve: Curves.easeInOutCubic,
                child: Icon(
                  Icons.expand_more_rounded,
                  size: 22,
                  color: AppColors.dsText3(brightness),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Badge compteur à droite du label.
class _CountBadge extends StatelessWidget {
  final int count;

  const _CountBadge({required this.count});

  @override
  Widget build(BuildContext context) {
    final brightness = Theme.of(context).brightness;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
      decoration: BoxDecoration(
        color: AppColors.dsBgInset(brightness),
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(
        '$count',
        style: TextStyle(
          fontSize: 11,
          fontWeight: FontWeight.w700,
          color: AppColors.dsText3(brightness),
          fontFeatures: const [FontFeature.tabularFigures()],
        ),
      ),
    );
  }
}
