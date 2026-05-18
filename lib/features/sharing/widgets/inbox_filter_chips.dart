import 'package:flutter/material.dart';
import 'package:mangatracker/core/theme/app_colors.dart';
import 'package:mangatracker/core/theme/app_spacing.dart';

/// Filtre d'inbox : 3 pills "Toutes / Non lues / Lues" avec compteur.
///
/// Design System V1 « Refined Classic » :
///  - Pills full radius (999) avec bg `dsBgInset` quand inactive, `red-soft`
///    + outline rouge quand actif.
///  - Label uppercase 12px medium + petite count badge intégrée.
///
/// Le compteur en suffixe permet de jeter un coup d'œil rapide à la
/// distribution sans avoir à scanner la liste.
enum InboxFilter { all, unread, read }

class InboxFilterChips extends StatelessWidget {
  final InboxFilter selected;
  final int totalCount;
  final int unreadCount;
  final int readCount;
  final ValueChanged<InboxFilter> onChanged;
  final String labelAll;
  final String labelUnread;
  final String labelRead;

  const InboxFilterChips({
    super.key,
    required this.selected,
    required this.totalCount,
    required this.unreadCount,
    required this.readCount,
    required this.onChanged,
    required this.labelAll,
    required this.labelUnread,
    required this.labelRead,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        _Pill(
          label: labelAll,
          count: totalCount,
          active: selected == InboxFilter.all,
          onTap: () => onChanged(InboxFilter.all),
        ),
        const SizedBox(width: AppSpacing.s),
        _Pill(
          label: labelUnread,
          count: unreadCount,
          active: selected == InboxFilter.unread,
          onTap: () => onChanged(InboxFilter.unread),
        ),
        const SizedBox(width: AppSpacing.s),
        _Pill(
          label: labelRead,
          count: readCount,
          active: selected == InboxFilter.read,
          onTap: () => onChanged(InboxFilter.read),
        ),
      ],
    );
  }
}

class _Pill extends StatelessWidget {
  final String label;
  final int count;
  final bool active;
  final VoidCallback onTap;

  const _Pill({
    required this.label,
    required this.count,
    required this.active,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final brightness = Theme.of(context).brightness;
    final scheme = Theme.of(context).colorScheme;
    final bg = active
        ? AppColors.dsRedSoft(brightness)
        : AppColors.dsBgInset(brightness);
    final fg = active ? scheme.primary : AppColors.dsText2(brightness);
    final border = active
        ? BorderSide(color: scheme.primary.withValues(alpha: 0.45), width: 1)
        : BorderSide(color: AppColors.dsHairline(brightness), width: 1);

    return Material(
      color: bg,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(999),
        side: border,
      ),
      child: InkWell(
        borderRadius: BorderRadius.circular(999),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                label,
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: active ? FontWeight.w700 : FontWeight.w600,
                  color: fg,
                  letterSpacing: -0.1,
                ),
              ),
              const SizedBox(width: 6),
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 7, vertical: 1),
                decoration: BoxDecoration(
                  color: active
                      ? scheme.primary
                      : AppColors.dsHairline(brightness),
                  borderRadius: BorderRadius.circular(999),
                ),
                child: Text(
                  '$count',
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
                    fontFeatures: const [FontFeature.tabularFigures()],
                    color: active
                        ? scheme.onPrimary
                        : AppColors.dsText2(brightness),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
