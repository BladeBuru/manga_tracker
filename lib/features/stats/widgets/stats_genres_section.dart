import 'package:flutter/material.dart';
import 'package:mangatracker/core/components/app_chip.dart';
import 'package:mangatracker/core/theme/app_colors.dart';
import 'package:mangatracker/features/profile/widgets/profile_edit_sections.dart';
import 'package:mangatracker/l10n/app_localizations.dart';

// ╔═══════════════════════════════════════════════════════════════════════╗
// ║  StatsGenresSection — section "Genres préférés" en chip-wrap.         ║
// ║  Wrap d'`AppChip` outlined dans une `ProfileEditSection`. Si la liste ║
// ║  est vide, on affiche un message inline à l'intérieur du card.        ║
// ╚═══════════════════════════════════════════════════════════════════════╝

/// Section "Genres préférés" — top genres en chips wrap.
class StatsGenresSection extends StatelessWidget {
  final List<String> topGenres;

  const StatsGenresSection({super.key, required this.topGenres});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final brightness = Theme.of(context).brightness;

    return ProfileEditSection(
      label: l10n.statsSectionGenres,
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
          child: topGenres.isEmpty
              ? Text(
                  l10n.statsTopGenresEmpty,
                  style: TextStyle(
                    fontSize: 14,
                    color: AppColors.dsText2(brightness),
                  ),
                )
              : Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: [
                    for (final genre in topGenres)
                      AppChip(label: genre),
                  ],
                ),
        ),
      ],
    );
  }
}
