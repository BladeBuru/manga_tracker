import 'package:flutter/material.dart';
import 'package:mangatracker/core/theme/app_colors.dart';
import 'package:mangatracker/core/theme/app_radius.dart';
import 'package:mangatracker/core/theme/app_spacing.dart';
import 'package:mangatracker/l10n/app_localizations.dart';

// ╔═══════════════════════════════════════════════════════════════════════╗
// ║  DetailChapterSection — V1 « Refined Classic » card collapsible pour  ║
// ║  une section/saison de chapitres dans la fiche manga.                 ║
// ║                                                                       ║
// ║  Remplace l'ancien ExpansionTile (avec border rouge agressive + ombre ║
// ║  primary) par une card hairline + AnimatedCrossFade 250ms, alignée    ║
// ║  sur `LibrarySection`.                                                 ║
// ║                                                                       ║
// ║  Rows internes : `#247 · Chapitre · ✓` ultra-compactes (~44px).       ║
// ╚═══════════════════════════════════════════════════════════════════════╝

/// Section repliable d'une saison/sous-section de chapitres du détail manga.
///
/// - Header : label (titre de la saison) + badge `read/total` + chevron rotaté.
/// - Body : liste de `DetailChapterRow` séparées par hairlines.
/// - L'état d'expansion est piloté par le parent ([isExpanded]).
class DetailChapterSection extends StatelessWidget {
  /// Titre de la saison (ex: "Saison 1", "Arc East Blue", etc.).
  final String title;

  /// Liste des numéros de chapitres dans la section (ordre déjà décidé par
  /// le helper côté parent, en général décroissant).
  final List<int> chapterNumbers;

  /// Nombre total de chapitres dans la section (pour le badge `x/total`).
  final int totalCount;

  /// Nombre de chapitres lus dans la section (pour le badge `read/x`).
  final int readCount;

  /// État d'expansion contrôlé par le parent.
  final bool isExpanded;

  /// Callback déclenché quand l'utilisateur tape sur le header.
  final ValueChanged<bool> onExpansionChanged;

  /// Compteur courant de chapitres lus (utilisé pour marquer un chapitre lu).
  final num currentReadCount;

  /// `true` quand une sauvegarde est en cours → désactive les taps.
  final bool isSaving;

  /// Callback déclenché quand l'utilisateur tape sur un chapitre — reçoit
  /// le numéro du chapitre cliqué.
  final ValueChanged<int> onChapterTap;

  const DetailChapterSection({
    super.key,
    required this.title,
    required this.chapterNumbers,
    required this.totalCount,
    required this.readCount,
    required this.isExpanded,
    required this.onExpansionChanged,
    required this.currentReadCount,
    required this.isSaving,
    required this.onChapterTap,
  });

  @override
  Widget build(BuildContext context) {
    final brightness = Theme.of(context).brightness;
    final isDark = brightness == Brightness.dark;

    return Padding(
      padding: const EdgeInsets.only(bottom: AppSpacing.s),
      child: Container(
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
            _SectionHeader(
              title: title,
              readCount: readCount,
              totalCount: totalCount,
              isExpanded: isExpanded,
              onTap: () => onExpansionChanged(!isExpanded),
            ),
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
                  for (int i = 0; i < chapterNumbers.length; i++) ...[
                    DetailChapterRow(
                      chapterNumber: chapterNumbers[i],
                      isRead: chapterNumbers[i] <= currentReadCount,
                      isSaving: isSaving,
                      onTap: () => onChapterTap(chapterNumbers[i]),
                    ),
                    if (i < chapterNumbers.length - 1)
                      Padding(
                        // Indent ~50px sous le numéro de chapitre.
                        padding: const EdgeInsets.only(left: 56),
                        child: Container(
                          height: 1,
                          color: AppColors.dsHairline(brightness),
                        ),
                      ),
                  ],
                ],
              ),
              secondChild: const SizedBox(width: double.infinity, height: 0),
            ),
          ],
        ),
      ),
    );
  }
}

/// Header d'une `DetailChapterSection`. Tappable, affiche label + badge + chevron.
class _SectionHeader extends StatelessWidget {
  final String title;
  final int readCount;
  final int totalCount;
  final bool isExpanded;
  final VoidCallback onTap;

  const _SectionHeader({
    required this.title,
    required this.readCount,
    required this.totalCount,
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
          child: Row(
            children: [
              Expanded(
                child: Row(
                  children: [
                    Flexible(
                      child: Text(
                        title.toUpperCase(),
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w700,
                          letterSpacing: 0.88, // 0.08em * 11
                          color: AppColors.dsText2(brightness),
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    const SizedBox(width: AppSpacing.s),
                    _CountBadge(readCount: readCount, totalCount: totalCount),
                  ],
                ),
              ),
              const SizedBox(width: AppSpacing.s),
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

/// Badge compteur "x/y" à droite du header.
class _CountBadge extends StatelessWidget {
  final int readCount;
  final int totalCount;

  const _CountBadge({required this.readCount, required this.totalCount});

  @override
  Widget build(BuildContext context) {
    final brightness = Theme.of(context).brightness;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
      decoration: BoxDecoration(
        color: AppColors.dsBgInset(brightness),
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(
        '$readCount/$totalCount',
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

/// Row compacte d'un chapitre dans une `DetailChapterSection`.
///
/// Layout : `[#247 mono] · Chapitre · [check]`. Densité ~44px.
class DetailChapterRow extends StatelessWidget {
  final int chapterNumber;
  final bool isRead;
  final bool isSaving;
  final VoidCallback onTap;

  const DetailChapterRow({
    super.key,
    required this.chapterNumber,
    required this.isRead,
    required this.isSaving,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final l10n = AppLocalizations.of(context);

    // `titleColor` : primary si lu (signaler la progression), onSurface sinon.
    // Avant on avait aussi un `numberColor` séparé (numéro mono à gauche)
    // mais le numéro est désormais fusionné dans le titre « Chapitre N ».
    final titleColor = isRead ? scheme.primary : scheme.onSurface;

    return Opacity(
      opacity: isSaving ? 0.5 : 1.0,
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: isSaving ? null : onTap,
          child: Padding(
            padding: const EdgeInsets.symmetric(
              horizontal: AppSpacing.m,
              vertical: 12,
            ),
            child: Row(
              children: [
                // **Fix 2026-05-19** : retrait du `#` (user feedback). Le
                // numéro reste mono tabular pour l'alignement vertical mais
                // sans préfixe : « 247 » au lieu de « #247 ». Plus moderne.
                Expanded(
                  child: RichText(
                    overflow: TextOverflow.ellipsis,
                    text: TextSpan(
                      children: [
                        TextSpan(
                          text:
                              '${l10n?.chapter ?? 'Chapitre'} $chapterNumber',
                          style: TextStyle(
                            fontSize: 14.5,
                            fontWeight: FontWeight.w600,
                            color: titleColor,
                            fontFeatures: const [
                              FontFeature.tabularFigures(),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                _ReadCheckbox(isRead: isRead),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// Indicateur de chapitre lu / non lu (cercle vide ou check primary).
class _ReadCheckbox extends StatelessWidget {
  final bool isRead;

  const _ReadCheckbox({required this.isRead});

  @override
  Widget build(BuildContext context) {
    final brightness = Theme.of(context).brightness;
    final scheme = Theme.of(context).colorScheme;
    return AnimatedContainer(
      duration: const Duration(milliseconds: 200),
      width: 22,
      height: 22,
      decoration: BoxDecoration(
        color: isRead ? scheme.primary : Colors.transparent,
        borderRadius: BorderRadius.circular(AppRadius.xs),
        border: Border.all(
          color: isRead ? scheme.primary : AppColors.dsBorder(brightness),
          width: 1.5,
        ),
      ),
      alignment: Alignment.center,
      child: isRead
          ? Icon(
              Icons.check_rounded,
              size: 14,
              color: scheme.onPrimary,
            )
          : const SizedBox.shrink(),
    );
  }
}
