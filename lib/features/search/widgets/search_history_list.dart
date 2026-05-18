import 'package:flutter/material.dart';
import 'package:mangatracker/core/theme/app_colors.dart';
import 'package:mangatracker/core/theme/app_spacing.dart';
import 'package:mangatracker/l10n/app_localizations.dart';

/// Header de la section "Historique de recherche" + bouton "Effacer".
///
/// Source : `.claude-design/manga-tracker/project/screen-search.jsx`.
class SearchHistoryHeader extends StatelessWidget {
  final bool canClear;
  final VoidCallback onClearAll;

  const SearchHistoryHeader({
    super.key,
    required this.canClear,
    required this.onClearAll,
  });

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final l10n = AppLocalizations.of(context)!;
    return Padding(
      padding: const EdgeInsets.fromLTRB(
        AppSpacing.m,
        0,
        AppSpacing.m,
        12,
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            l10n.searchHistoryTitle,
            style: TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.w800,
              letterSpacing: -0.15, // -0.01em * 15
              color: scheme.onSurface,
            ),
          ),
          if (canClear)
            GestureDetector(
              onTap: onClearAll,
              behavior: HitTestBehavior.opaque,
              child: Padding(
                padding: const EdgeInsets.symmetric(
                  vertical: 4,
                  horizontal: 4,
                ),
                child: Text(
                  l10n.clear,
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: scheme.primary,
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}

/// Liste de l'historique de recherche, sous forme de card blanche avec
/// hairline border, ou état vide centré.
class SearchHistoryList extends StatelessWidget {
  final List<String> history;
  final ValueChanged<String> onSelect;
  final ValueChanged<String> onRemove;

  const SearchHistoryList({
    super.key,
    required this.history,
    required this.onSelect,
    required this.onRemove,
  });

  @override
  Widget build(BuildContext context) {
    final brightness = Theme.of(context).brightness;
    final isDark = brightness == Brightness.dark;
    final l10n = AppLocalizations.of(context)!;

    if (history.isEmpty) {
      return Padding(
        padding: const EdgeInsets.symmetric(horizontal: AppSpacing.m),
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 40),
          child: Center(
            child: Text(
              l10n.searchEmptyHistory,
              style: TextStyle(
                fontSize: 13,
                color: AppColors.dsText3(brightness),
              ),
            ),
          ),
        ),
      );
    }

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.m),
      child: Container(
        decoration: BoxDecoration(
          color: isDark ? AppColors.dsSurfaceDark : Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: AppColors.dsHairline(brightness),
            width: 1,
          ),
          boxShadow: isDark
              ? null
              : const [
                  BoxShadow(
                    color: Color(0x0A140A0A),
                    blurRadius: 2,
                    offset: Offset(0, 1),
                  ),
                ],
        ),
        clipBehavior: Clip.antiAlias,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            for (int i = 0; i < history.length; i++) ...[
              if (i > 0)
                Padding(
                  padding: const EdgeInsets.only(left: 50),
                  child: Container(
                    height: 1,
                    color: AppColors.dsHairline(brightness),
                  ),
                ),
              _HistoryRow(
                key: ValueKey('history_${history[i]}'),
                term: history[i],
                onTap: () => onSelect(history[i]),
                onRemove: () => onRemove(history[i]),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class _HistoryRow extends StatelessWidget {
  final String term;
  final VoidCallback onTap;
  final VoidCallback onRemove;

  const _HistoryRow({
    super.key,
    required this.term,
    required this.onTap,
    required this.onRemove,
  });

  @override
  Widget build(BuildContext context) {
    final brightness = Theme.of(context).brightness;
    final scheme = Theme.of(context).colorScheme;
    return InkWell(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        child: Row(
          children: [
            Icon(
              Icons.refresh,
              size: 17,
              color: AppColors.dsText3(brightness),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Text(
                term,
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                  color: scheme.onSurface,
                ),
                overflow: TextOverflow.ellipsis,
              ),
            ),
            GestureDetector(
              onTap: onRemove,
              behavior: HitTestBehavior.opaque,
              child: Padding(
                padding: const EdgeInsets.all(4),
                child: Icon(
                  Icons.close,
                  size: 15,
                  color: AppColors.dsText3(brightness),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
