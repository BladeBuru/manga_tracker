import 'package:flutter/material.dart';
import 'package:mangatracker/core/theme/app_colors.dart';
import 'package:mangatracker/l10n/app_localizations.dart';

/// Onglets sélecteurs « Amis » / « Demandes » — style chips V1.
///
/// Deux pastilles côte-à-côte avec compteur entre parenthèses. La pastille
/// active est rouge (`red-soft` bg + `primary` fg + border `primary`), la
/// pastille inactive est neutre (surface + hairline).
enum FriendsTab { accepted, pending }

class FriendsTabSegmented extends StatelessWidget {
  final FriendsTab selected;
  final int acceptedCount;
  final int pendingCount;
  final ValueChanged<FriendsTab> onChanged;

  const FriendsTabSegmented({
    super.key,
    required this.selected,
    required this.acceptedCount,
    required this.pendingCount,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return Row(
      children: [
        Expanded(
          child: _TabChip(
            label: l10n.friendsTabAccepted,
            count: acceptedCount,
            selected: selected == FriendsTab.accepted,
            onTap: () => onChanged(FriendsTab.accepted),
          ),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: _TabChip(
            label: l10n.friendsTabPending,
            count: pendingCount,
            selected: selected == FriendsTab.pending,
            onTap: () => onChanged(FriendsTab.pending),
          ),
        ),
      ],
    );
  }
}

class _TabChip extends StatelessWidget {
  final String label;
  final int count;
  final bool selected;
  final VoidCallback onTap;

  const _TabChip({
    required this.label,
    required this.count,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final brightness = Theme.of(context).brightness;
    final scheme = Theme.of(context).colorScheme;
    final isDark = brightness == Brightness.dark;
    final bg = selected
        ? AppColors.dsRedSoft(brightness)
        : (isDark ? AppColors.dsSurfaceDark : Colors.white);
    final fg = selected ? scheme.primary : scheme.onSurface;
    final borderColor =
        selected ? scheme.primary : AppColors.dsHairline(brightness);
    return Material(
      color: bg,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(999),
        side: BorderSide(
          color: borderColor,
          width: selected ? 1.5 : 1,
        ),
      ),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(999),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 9),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            mainAxisSize: MainAxisSize.min,
            children: [
              Flexible(
                child: Text(
                  label,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontSize: 13.5,
                    fontWeight: FontWeight.w600,
                    color: fg,
                  ),
                ),
              ),
              const SizedBox(width: 6),
              _CountBadge(count: count, selected: selected),
            ],
          ),
        ),
      ),
    );
  }
}

class _CountBadge extends StatelessWidget {
  final int count;
  final bool selected;

  const _CountBadge({required this.count, required this.selected});

  @override
  Widget build(BuildContext context) {
    final brightness = Theme.of(context).brightness;
    final scheme = Theme.of(context).colorScheme;
    final bg = selected
        ? scheme.primary
        : AppColors.dsBgInset(brightness);
    final fg = selected ? scheme.onPrimary : AppColors.dsText2(brightness);
    return Container(
      constraints: const BoxConstraints(minWidth: 22),
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(
        '$count',
        textAlign: TextAlign.center,
        style: TextStyle(
          fontSize: 11,
          fontWeight: FontWeight.w700,
          color: fg,
          height: 1.1,
        ),
      ),
    );
  }
}
