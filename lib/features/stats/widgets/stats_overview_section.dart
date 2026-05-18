import 'package:flutter/material.dart';
import 'package:mangatracker/core/components/pastel_tile.dart';
import 'package:mangatracker/features/profile/widgets/profile_edit_sections.dart';
import 'package:mangatracker/features/stats/dto/user_stats.dto.dart';
import 'package:mangatracker/features/stats/widgets/stats_section_row.dart';
import 'package:mangatracker/l10n/app_localizations.dart';

// ╔═══════════════════════════════════════════════════════════════════════╗
// ║  StatsOverviewSection — section "Vue d'ensemble".                     ║
// ║  Affiche les compteurs clés : mangas, chapitres lus, temps estimé,    ║
// ║  taux de complétion, dernière lecture. Chaque row a une pastel tile.  ║
// ╚═══════════════════════════════════════════════════════════════════════╝

/// Section "Vue d'ensemble" — résumé chiffré de l'activité.
class StatsOverviewSection extends StatelessWidget {
  final UserStatsDto stats;
  final String? lastReadFormatted;
  final String emptyDash;

  const StatsOverviewSection({
    super.key,
    required this.stats,
    required this.lastReadFormatted,
    required this.emptyDash,
  });

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return ProfileEditSection(
      label: l10n.statsSectionOverview,
      children: [
        StatsSectionRow(
          icon: Icons.library_books_outlined,
          tileColor: PastelTileColor.blue,
          label: l10n.statsLibraryTotal,
          value: stats.totalMangas.toString(),
        ),
        StatsSectionRow(
          icon: Icons.menu_book_outlined,
          tileColor: PastelTileColor.purple,
          label: l10n.statsTotalChapters,
          value: stats.totalChaptersRead.toString(),
        ),
        StatsSectionRow(
          icon: Icons.schedule_outlined,
          tileColor: PastelTileColor.yellow,
          label: l10n.statsReadingTime,
          value: _formatMinutes(l10n, stats.estimatedReadingTimeMinutes),
        ),
        StatsSectionRow(
          icon: Icons.check_circle_outline,
          tileColor: PastelTileColor.green,
          label: l10n.statsCompletionRate,
          value: '${(stats.completionRate * 100).round()}%',
        ),
        StatsSectionRow(
          icon: Icons.history,
          tileColor: PastelTileColor.teal,
          label: l10n.statsLastRead,
          value: lastReadFormatted ?? emptyDash,
        ),
      ],
    );
  }

  String _formatMinutes(AppLocalizations l10n, int totalMinutes) {
    if (totalMinutes < 60) return l10n.statsMinutesShort(totalMinutes);
    final hours = totalMinutes ~/ 60;
    final minutes = totalMinutes % 60;
    if (hours < 24) {
      return l10n.statsHoursAndMinutesShort(hours, minutes);
    }
    final days = hours ~/ 24;
    final remainingHours = hours % 24;
    return l10n.statsDaysAndHoursShort(days, remainingHours);
  }
}
