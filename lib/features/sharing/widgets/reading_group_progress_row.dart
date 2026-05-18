import 'package:flutter/material.dart';
import 'package:mangatracker/core/theme/app_colors.dart';
import 'package:mangatracker/l10n/app_localizations.dart';

// ╔═══════════════════════════════════════════════════════════════════════╗
// ║  ReadingGroupProgressRow — row "label + ch.X / total" + barre fine    ║
// ║  intégrée. Pour la section "Progression" du détail de groupe.         ║
// ╚═══════════════════════════════════════════════════════════════════════╝

class ReadingGroupProgressRow extends StatelessWidget {
  final String label;
  final int? read;
  final int max;
  final Color barColor;

  /// Si vrai : affiche la valeur "ch.X" en colorScheme.primary (toi).
  final bool emphasized;

  const ReadingGroupProgressRow({
    super.key,
    required this.label,
    required this.read,
    required this.max,
    required this.barColor,
    this.emphasized = false,
  });

  @override
  Widget build(BuildContext context) {
    final brightness = Theme.of(context).brightness;
    final scheme = Theme.of(context).colorScheme;
    final l10n = AppLocalizations.of(context)!;
    final readValue = read ?? 0;
    final ratio = max <= 0 ? 0.0 : (readValue / max).clamp(0.0, 1.0);
    final valueColor =
        emphasized ? scheme.primary : AppColors.dsText2(brightness);

    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 14, 16, 14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  label,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontSize: 14.5,
                    fontWeight: FontWeight.w600,
                    color: scheme.onSurface,
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Text(
                read != null
                    ? 'ch. $readValue'
                    : l10n.readingGroupNotStarted,
                style: TextStyle(
                  fontFamily: 'JetBrainsMono',
                  fontFeatures: const [FontFeature.tabularFigures()],
                  fontSize: 12.5,
                  fontWeight: FontWeight.w700,
                  color: valueColor,
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          ClipRRect(
            borderRadius: BorderRadius.circular(999),
            child: LinearProgressIndicator(
              value: ratio,
              minHeight: 4,
              backgroundColor: AppColors.dsBgInset(brightness),
              valueColor: AlwaysStoppedAnimation<Color>(barColor),
            ),
          ),
        ],
      ),
    );
  }
}
