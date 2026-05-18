import 'package:flutter/material.dart';
import 'package:mangatracker/core/components/app_empty_state.dart';
import 'package:mangatracker/core/components/pastel_tile.dart';
import 'package:mangatracker/features/profile/widgets/profile_edit_sections.dart';
import 'package:mangatracker/features/stats/widgets/stats_section_row.dart';
import 'package:mangatracker/l10n/app_localizations.dart';

// ╔═══════════════════════════════════════════════════════════════════════╗
// ║  StatsStatusSection — section "Mangas par statut".                    ║
// ║  Une row par statut (À lire, En cours, À jour, Terminé) avec une     ║
// ║  pastel tile colorée et le compte à droite.                           ║
// ╚═══════════════════════════════════════════════════════════════════════╝

/// Section "Mangas par statut" — répartition de la biblio par statut de
/// lecture. Affiche un état vide si la biblio est totalement vide.
class StatsStatusSection extends StatelessWidget {
  final Map<String, int> byStatus;

  const StatsStatusSection({super.key, required this.byStatus});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final total = byStatus.values.fold<int>(0, (acc, v) => acc + v);
    if (total == 0) {
      return AppEmptyState(
        icon: Icons.menu_book_outlined,
        title: l10n.statsByStatusEmpty,
      );
    }
    // Ordre fixe d'affichage pour stabilité visuelle.
    final orderedKeys = ['reading', 'caughtUp', 'readLater', 'completed'];
    final rows = <Widget>[];
    for (final key in orderedKeys) {
      final count = byStatus[key];
      if (count == null) continue;
      rows.add(
        StatsSectionRow(
          icon: _iconForStatus(key),
          tileColor: _colorForStatus(key),
          label: _labelForStatus(l10n, key),
          value: count.toString(),
        ),
      );
    }
    // Statuts inconnus restants (forward-compat).
    for (final entry in byStatus.entries) {
      if (orderedKeys.contains(entry.key)) continue;
      rows.add(
        StatsSectionRow(
          label: entry.key,
          value: entry.value.toString(),
          icon: Icons.bookmark_outline,
          tileColor: PastelTileColor.pink,
        ),
      );
    }

    return ProfileEditSection(
      label: l10n.statsSectionBreakdown,
      children: rows,
    );
  }

  String _labelForStatus(AppLocalizations l10n, String key) {
    switch (key) {
      case 'readLater':
        return l10n.statusReadLater;
      case 'reading':
        return l10n.statusReading;
      case 'caughtUp':
        return l10n.statusCaughtUp;
      case 'completed':
        return l10n.statusCompleted;
      default:
        return key;
    }
  }

  IconData _iconForStatus(String key) {
    switch (key) {
      case 'reading':
        return Icons.auto_stories_outlined;
      case 'caughtUp':
        return Icons.bolt_outlined;
      case 'readLater':
        return Icons.bookmark_border;
      case 'completed':
        return Icons.task_alt_outlined;
      default:
        return Icons.bookmark_outline;
    }
  }

  PastelTileColor _colorForStatus(String key) {
    switch (key) {
      case 'reading':
        return PastelTileColor.blue;
      case 'caughtUp':
        return PastelTileColor.yellow;
      case 'readLater':
        return PastelTileColor.purple;
      case 'completed':
        return PastelTileColor.green;
      default:
        return PastelTileColor.pink;
    }
  }
}
