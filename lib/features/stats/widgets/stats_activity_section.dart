import 'package:flutter/material.dart';
import 'package:mangatracker/core/theme/app_colors.dart';
import 'package:mangatracker/core/theme/app_radius.dart';
import 'package:mangatracker/features/profile/widgets/profile_edit_sections.dart';
import 'package:mangatracker/l10n/app_localizations.dart';

// ╔═══════════════════════════════════════════════════════════════════════╗
// ║  StatsActivitySection — graphique barres « Activité de lecture »      ║
// ║  (Stats v2). 8 dernières semaines depuis le journal chapter_log.      ║
// ║  Barres pur-Flutter (pas de package chart) : hauteur proportionnelle  ║
// ║  au max, couleur primary, libellé compteur au-dessus.                 ║
// ╚═══════════════════════════════════════════════════════════════════════╝

/// Section « Activité de lecture » — barres hebdomadaires.
class StatsActivitySection extends StatelessWidget {
  /// Clé = lundi de la semaine (yyyy-MM-dd), valeur = sessions de lecture.
  final Map<String, int> chaptersPerWeek;

  const StatsActivitySection({super.key, required this.chaptersPerWeek});

  /// Les 8 dernières semaines, semaines vides comprises (barres à 0) —
  /// sinon le graphe « saute » les trous et fausse la lecture temporelle.
  List<MapEntry<DateTime, int>> _lastEightWeeks() {
    final now = DateTime.now();
    // Lundi de la semaine courante.
    final thisMonday = DateTime(now.year, now.month, now.day)
        .subtract(Duration(days: now.weekday - 1));
    final weeks = <MapEntry<DateTime, int>>[];
    for (int i = 7; i >= 0; i--) {
      final monday = thisMonday.subtract(Duration(days: 7 * i));
      final key = '${monday.year.toString().padLeft(4, '0')}-'
          '${monday.month.toString().padLeft(2, '0')}-'
          '${monday.day.toString().padLeft(2, '0')}';
      weeks.add(MapEntry(monday, chaptersPerWeek[key] ?? 0));
    }
    return weeks;
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final brightness = Theme.of(context).brightness;
    final scheme = Theme.of(context).colorScheme;
    final weeks = _lastEightWeeks();
    final maxCount =
        weeks.fold<int>(0, (max, e) => e.value > max ? e.value : max);

    return ProfileEditSection(
      label: l10n.statsActivityTitle,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 14, 16, 14),
          child: maxCount == 0
              ? Text(
                  l10n.statsNoHistory,
                  style: TextStyle(
                    fontSize: 14,
                    color: AppColors.dsText2(brightness),
                  ),
                )
              : SizedBox(
                  height: 120,
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      for (final week in weeks) ...[
                        Expanded(
                          child: _WeekBar(
                            monday: week.key,
                            count: week.value,
                            maxCount: maxCount,
                            barColor: scheme.primary,
                          ),
                        ),
                        if (week != weeks.last) const SizedBox(width: 6),
                      ],
                    ],
                  ),
                ),
        ),
      ],
    );
  }
}

/// Une barre : compteur au-dessus, barre proportionnelle, jour/mois dessous.
class _WeekBar extends StatelessWidget {
  final DateTime monday;
  final int count;
  final int maxCount;
  final Color barColor;

  const _WeekBar({
    required this.monday,
    required this.count,
    required this.maxCount,
    required this.barColor,
  });

  @override
  Widget build(BuildContext context) {
    final brightness = Theme.of(context).brightness;
    // 12px réservés au label compteur + 16px au label date → 80px de barre.
    final barMaxHeight = 80.0;
    final height =
        maxCount == 0 ? 0.0 : (count / maxCount) * barMaxHeight;

    return Column(
      mainAxisAlignment: MainAxisAlignment.end,
      children: [
        if (count > 0)
          Text(
            '$count',
            style: TextStyle(
              fontSize: 10,
              fontWeight: FontWeight.w700,
              color: AppColors.dsText2(brightness),
              fontFeatures: const [FontFeature.tabularFigures()],
            ),
          ),
        const SizedBox(height: 2),
        AnimatedContainer(
          duration: const Duration(milliseconds: 300),
          height: height < 3 && count > 0 ? 3 : height,
          decoration: BoxDecoration(
            color: count > 0
                ? barColor
                : AppColors.dsBgInset(brightness),
            borderRadius: BorderRadius.circular(AppRadius.xs),
          ),
        ),
        const SizedBox(height: 4),
        Text(
          '${monday.day}/${monday.month}',
          style: TextStyle(
            fontSize: 9,
            color: AppColors.dsText3(brightness),
            fontFeatures: const [FontFeature.tabularFigures()],
          ),
        ),
      ],
    );
  }
}
