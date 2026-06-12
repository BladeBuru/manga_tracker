import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:mangatracker/core/components/app_chip.dart';
import 'package:mangatracker/core/theme/app_colors.dart';
import 'package:mangatracker/features/profile/widgets/profile_edit_sections.dart';
import 'package:mangatracker/features/stats/dto/user_stats.dto.dart';
import 'package:mangatracker/l10n/app_localizations.dart';

// ╔═══════════════════════════════════════════════════════════════════════╗
// ║  StatsHistorySection — « Dernières lectures » (Stats v2).             ║
// ║  Liste des sessions du journal chapter_log : titre du manga,          ║
// ║  « Chapitre N » + chip Hors-série éventuelle + date relative.         ║
// ║  Tap → fiche manga.                                                   ║
// ╚═══════════════════════════════════════════════════════════════════════╝

/// Section « Dernières lectures » — historique du journal de lecture.
class StatsHistorySection extends StatelessWidget {
  final List<ReadingHistoryEntryDto> history;

  /// Limite d'affichage (l'API en renvoie max 20 — 8 suffisent ici).
  static const int _maxRows = 8;

  const StatsHistorySection({super.key, required this.history});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final brightness = Theme.of(context).brightness;
    final entries = history.take(_maxRows).toList();

    return ProfileEditSection(
      label: l10n.statsHistoryTitle,
      children: [
        if (entries.isEmpty)
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
            child: Text(
              l10n.statsNoHistory,
              style: TextStyle(
                fontSize: 14,
                color: AppColors.dsText2(brightness),
              ),
            ),
          )
        else
          for (int i = 0; i < entries.length; i++) ...[
            _HistoryRow(entry: entries[i]),
            if (i < entries.length - 1)
              Padding(
                padding: const EdgeInsets.only(left: 16),
                child: Container(
                  height: 1,
                  color: AppColors.dsHairline(brightness),
                ),
              ),
          ],
      ],
    );
  }
}

/// Ligne d'historique : titre + chapitre + chip bonus + date. Tap → fiche.
class _HistoryRow extends StatelessWidget {
  final ReadingHistoryEntryDto entry;

  const _HistoryRow({required this.entry});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final brightness = Theme.of(context).brightness;
    final scheme = Theme.of(context).colorScheme;
    final locale = Localizations.localeOf(context).toString();
    final dateLabel = DateFormat.MMMd(locale).format(entry.readAt);

    // Numéro entier si possible (247 plutôt que 247.0).
    final n = entry.chapterNumber;
    final chapterLabel =
        n == n.truncate() ? n.truncate().toString() : n.toString();

    return InkWell(
      onTap: entry.muId > 0 ? () => context.push('/manga/${entry.muId}') : null,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        child: Row(
          children: [
            Icon(Icons.menu_book_outlined, size: 18, color: scheme.primary),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    entry.mangaTitle,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: scheme.onSurface,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Row(
                    children: [
                      Text(
                        '${l10n.chapter} $chapterLabel',
                        style: TextStyle(
                          fontSize: 12,
                          color: AppColors.dsText2(brightness),
                          fontFeatures: const [FontFeature.tabularFigures()],
                        ),
                      ),
                      if (entry.isBonus) ...[
                        const SizedBox(width: 8),
                        AppChip(label: l10n.statsBonusTag),
                      ],
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(width: 8),
            Text(
              dateLabel,
              style: TextStyle(
                fontSize: 12,
                color: AppColors.dsText3(brightness),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
